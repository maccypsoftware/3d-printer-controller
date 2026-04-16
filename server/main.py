#!/usr/bin/env python3
"""
Prusa Printer Monitor Server
Provides API endpoints for printer control, camera preview, and error detection
"""

import asyncio
import cv2
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import json
import time
import threading
from typing import Optional
import requests
from picamera2 import Picamera2
import base64
from apns2.client import APNsClient
from apns2.payload import Payload
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Prusa Printer Monitor", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables
camera = None
printer_status = {
    "printing": False,
    "paused": False,
    "progress": 0.0,
    "error_detected": False,
    "error_message": None,
    "print_time_remaining": 0,
    "file_name": None
}
connected_clients = set()
apns_client = None
device_tokens = set()

class PrinterCommand(BaseModel):
    action: str  # "start", "pause", "resume", "cancel"

class DeviceToken(BaseModel):
    token: str

class PrinterStatus(BaseModel):
    printing: bool
    paused: bool
    progress: float
    error_detected: bool
    error_message: Optional[str] = None
    print_time_remaining: int
    file_name: Optional[str] = None

def initialize_camera():
    """Initialize Raspberry Pi camera"""
    global camera
    try:
        camera = Picamera2()
        camera.configure(camera.create_preview_configuration(main={"size": (640, 480)}))
        camera.start()
        logger.info("Camera initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize camera: {e}")
        return False

def detect_print_errors(frame):
    """
    Analyze camera frame to detect common 3D printing errors
    Returns (error_detected, error_message)
    """
    try:
        # Convert to grayscale for analysis
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # Detect spaghetti detection (random filament movements)
        edges = cv2.Canny(gray, 50, 150)
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Count contours in the print area
        print_area_contours = [c for c in contours if cv2.contourArea(c) > 100]
        
        # Simple spaghetti detection: too many small contours
        if len(print_area_contours) > 50:
            return True, "Spaghetti detected - possible filament extrusion issue"
        
        # Layer shift detection (simplified - would need more sophisticated approach)
        # This is a placeholder for more advanced detection
        mean_val = np.mean(gray)
        if mean_val < 30:  # Very dark could indicate print failure
            return True, "Print failure detected - very low visibility"
            
        return False, None
        
    except Exception as e:
        logger.error(f"Error detection failed: {e}")
        return False, None

def get_printer_status_from_prusa():
    """Get actual printer status from Prusa printer via API"""
    try:
        # This would connect to Prusa's API
        # For now, return simulated data
        # TODO: Implement actual Prusa API integration
        return {
            "printing": True,
            "paused": False,
            "progress": 45.2,
            "print_time_remaining": 3600,
            "file_name": "test_print.gcode"
        }
    except Exception as e:
        logger.error(f"Failed to get printer status: {e}")
        return printer_status

def send_push_notification(title, message, sound="default"):
    """Send push notification to all connected iOS devices"""
    global apns_client, device_tokens
    
    if not apns_client or not device_tokens:
        return
    
    try:
        payload = Payload(alert={"title": title, "body": message}, sound=sound)
        
        for token in device_tokens:
            apns_client.send_notification(token, payload)
            logger.info(f"Push notification sent to {token[:10]}...")
            
    except Exception as e:
        logger.error(f"Failed to send push notification: {e}")

def camera_monitor_thread():
    """Background thread for camera monitoring and error detection"""
    global camera, printer_status
    
    if not camera:
        return
    
    last_error_time = 0
    
    while True:
        try:
            frame = camera.capture_array()
            
            # Convert BGR to RGB for OpenCV
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Detect errors
            error_detected, error_message = detect_print_errors(frame_rgb)
            
            # Check if this is a new error
            current_time = time.time()
            if error_detected and (current_time - last_error_time > 60):  # Debounce for 60 seconds
                printer_status["error_detected"] = True
                printer_status["error_message"] = error_message
                last_error_time = current_time
                
                # Send push notification
                send_push_notification("Print Error Detected", error_message)
                
                # Notify connected clients
                status_update = json.dumps(printer_status)
                for client in connected_clients.copy():
                    try:
                        asyncio.create_task(client.send_text(status_update))
                    except:
                        connected_clients.discard(client)
            elif not error_detected:
                printer_status["error_detected"] = False
                printer_status["error_message"] = None
                
        except Exception as e:
            logger.error(f"Camera monitoring error: {e}")
            
        time.sleep(5)  # Check every 5 seconds

@app.on_event("startup")
async def startup_event():
    """Initialize camera and start monitoring thread"""
    initialize_camera()
    
    # Start camera monitoring thread
    monitor_thread = threading.Thread(target=camera_monitor_thread, daemon=True)
    monitor_thread.start()
    
    # Initialize APNs client (you'll need to provide actual certificates)
    # apns_client = APNsClient("path/to/cert.pem", use_sandbox=True)
    
    logger.info("Server started successfully")

@app.get("/")
async def root():
    return {"message": "Prusa Printer Monitor Server"}

@app.get("/status")
async def get_status():
    """Get current printer status"""
    return printer_status

@app.post("/command")
async def send_command(command: PrinterCommand):
    """Send command to printer"""
    try:
        # TODO: Implement actual Prusa printer commands
        if command.action == "pause":
            printer_status["paused"] = True
            printer_status["printing"] = False
        elif command.action == "resume":
            printer_status["paused"] = False
            printer_status["printing"] = True
        elif command.action == "cancel":
            printer_status["printing"] = False
            printer_status["paused"] = False
            printer_status["progress"] = 0.0
            
        # Notify all connected clients
        status_update = json.dumps(printer_status)
        for client in connected_clients.copy():
            try:
                await client.send_text(status_update)
            except:
                connected_clients.discard(client)
                
        return {"success": True, "status": printer_status}
        
    except Exception as e:
        logger.error(f"Command failed: {e}")
        return {"success": False, "error": str(e)}

@app.post("/register-device")
async def register_device(device_token: DeviceToken):
    """Register iOS device for push notifications"""
    device_tokens.add(device_token.token)
    logger.info(f"Device registered: {device_token.token[:10]}...")
    return {"success": True}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await websocket.accept()
    connected_clients.add(websocket)
    
    try:
        # Send current status immediately
        await websocket.send_text(json.dumps(printer_status))
        
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            # Handle any client messages if needed
            
    except WebSocketDisconnect:
        connected_clients.discard(websocket)
        logger.info("Client disconnected")

@app.get("/camera/stream")
async def camera_stream():
    """MJPEG camera stream endpoint"""
    if not camera:
        return {"error": "Camera not available"}
    
    def generate_frames():
        while True:
            try:
                frame = camera.capture_array()
                # Convert to JPEG
                _, buffer = cv2.imencode('.jpg', frame)
                frame_bytes = buffer.tobytes()
                
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
                       
            except Exception as e:
                logger.error(f"Frame generation error: {e}")
                break
                
    return StreamingResponse(
        generate_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )

@app.get("/camera/snapshot")
async def camera_snapshot():
    """Get single camera frame as base64"""
    if not camera:
        return {"error": "Camera not available"}
    
    try:
        frame = camera.capture_array()
        _, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()
        frame_base64 = base64.b64encode(frame_bytes).decode('utf-8')
        
        return {"image": f"data:image/jpeg;base64,{frame_base64}"}
        
    except Exception as e:
        logger.error(f"Snapshot error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
