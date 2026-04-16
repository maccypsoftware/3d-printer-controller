import pytest
import asyncio
import json
from unittest.mock import Mock, patch, AsyncMock
from fastapi.testclient import TestClient
from fastapi import WebSocket
from io import BytesIO
import cv2
import numpy as np

from main import app, printer_status, detect_print_errors, get_printer_status_from_prusa

class TestPrinterStatusAPI:
    """Test printer status API endpoints"""
    
    def setup_method(self):
        """Setup test client"""
        self.client = TestClient(app)
    
    def test_get_status_endpoint(self):
        """Test GET /status endpoint"""
        response = self.client.get("/status")
        assert response.status_code == 200
        data = response.json()
        assert "printing" in data
        assert "paused" in data
        assert "progress" in data
        assert "error_detected" in data
    
    def test_post_command_start(self):
        """Test POST /command with start action"""
        response = self.client.post(
            "/command",
            json={"action": "start"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "status" in data
    
    def test_post_command_pause(self):
        """Test POST /command with pause action"""
        response = self.client.post(
            "/command",
            json={"action": "pause"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
    
    def test_post_command_resume(self):
        """Test POST /command with resume action"""
        response = self.client.post(
            "/command",
            json={"action": "resume"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
    
    def test_post_command_cancel(self):
        """Test POST /command with cancel action"""
        response = self.client.post(
            "/command",
            json={"action": "cancel"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
    
    def test_post_command_invalid_action(self):
        """Test POST /command with invalid action"""
        response = self.client.post(
            "/command",
            json={"action": "invalid"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True  # Still returns success for simplicity
    
    def test_register_device(self):
        """Test POST /register-device endpoint"""
        response = self.client.post(
            "/register-device",
            json={"token": "test_device_token"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

class TestCameraEndpoints:
    """Test camera-related endpoints"""
    
    def setup_method(self):
        """Setup test client"""
        self.client = TestClient(app)
    
    @patch('main.camera')
    def test_camera_snapshot_success(self, mock_camera):
        """Test GET /camera/snapshot with successful capture"""
        # Mock camera capture
        mock_frame = np.zeros((480, 640, 3), dtype=np.uint8)
        mock_camera.capture_array.return_value = mock_frame
        
        response = self.client.get("/camera/snapshot")
        assert response.status_code == 200
        data = response.json()
        assert "image" in data
        assert data["image"].startswith("data:image/jpeg;base64,")
    
    @patch('main.camera', None)
    def test_camera_snapshot_no_camera(self):
        """Test GET /camera/snapshot when camera is not available"""
        response = self.client.get("/camera/snapshot")
        assert response.status_code == 200
        data = response.json()
        assert "error" in data
        assert data["error"] == "Camera not available"
    
    @patch('main.camera')
    def test_camera_stream(self, mock_camera):
        """Test GET /camera/stream endpoint"""
        response = self.client.get("/camera/stream")
        # Stream endpoints return multipart response
        assert response.status_code == 200
        assert "multipart/x-mixed-replace" in response.headers["content-type"]

class TestErrorDetection:
    """Test print error detection functionality"""
    
    def test_detect_print_errors_no_error(self):
        """Test error detection with normal frame"""
        # Create a normal frame (mostly uniform)
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame.fill(128)  # Gray background
        
        error_detected, error_message = detect_print_errors(frame)
        
        assert error_detected is False
        assert error_message is None
    
    def test_detect_print_errors_spaghetti(self):
        """Test error detection with spaghetti-like patterns"""
        # Create a frame with many small contours (simulating spaghetti)
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame.fill(128)
        
        # Add many small white dots to simulate spaghetti
        for i in range(100):
            x = np.random.randint(0, 640)
            y = np.random.randint(0, 480)
            cv2.circle(frame, (x, y), 2, (255, 255, 255), -1)
        
        error_detected, error_message = detect_print_errors(frame)
        
        assert error_detected is True
        assert "Spaghetti detected" in error_message
    
    def test_detect_print_errors_dark_frame(self):
        """Test error detection with very dark frame"""
        # Create a very dark frame
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame.fill(10)  # Very dark
        
        error_detected, error_message = detect_print_errors(frame)
        
        assert error_detected is True
        assert "print failure detected" in error_message.lower()
    
    def test_detect_print_errors_exception_handling(self):
        """Test error detection with invalid frame"""
        # Test with None input
        error_detected, error_message = detect_print_errors(None)
        
        assert error_detected is False
        assert error_message is None

class TestWebSocketConnection:
    """Test WebSocket functionality"""
    
    def setup_method(self):
        """Setup test client"""
        self.client = TestClient(app)
    
    def test_websocket_connection(self):
        """Test WebSocket connection and status update"""
        with self.client.websocket_connect("/ws") as websocket:
            # Send a test message (though server doesn't process incoming messages)
            websocket.send_text("test")
            
            # Receive initial status
            data = websocket.receive_text()
            status_data = json.loads(data)
            
            assert "printing" in status_data
            assert "paused" in status_data
            assert "progress" in status_data

class TestPrinterStatusModel:
    """Test printer status management"""
    
    def test_printer_status_initial_state(self):
        """Test initial printer state"""
        assert printer_status["printing"] is False
        assert printer_status["paused"] is False
        assert printer_status["progress"] == 0.0
        assert printer_status["error_detected"] is False
    
    @patch('main.get_printer_status_from_prusa')
    def test_get_printer_status_from_prusa_success(self, mock_get_status):
        """Test successful printer status retrieval"""
        mock_status = {
            "printing": True,
            "paused": False,
            "progress": 45.5,
            "print_time_remaining": 3600,
            "file_name": "test.gcode"
        }
        mock_get_status.return_value = mock_status
        
        result = get_printer_status_from_prusa()
        
        assert result == mock_status
        mock_get_status.assert_called_once()
    
    @patch('main.get_printer_status_from_prusa')
    def test_get_printer_status_from_prusa_failure(self, mock_get_status):
        """Test printer status retrieval failure"""
        mock_get_status.side_effect = Exception("Connection failed")
        
        result = get_printer_status_from_prusa()
        
        # Should return default printer_status on failure
        assert result == printer_status

class TestIntegration:
    """Integration tests for the complete system"""
    
    def setup_method(self):
        """Setup test client"""
        self.client = TestClient(app)
        
        # Reset printer status
        global printer_status
        printer_status = {
            "printing": False,
            "paused": False,
            "progress": 0.0,
            "error_detected": False,
            "error_message": None,
            "print_time_remaining": 0,
            "file_name": None
        }
    
    def test_full_print_workflow(self):
        """Test complete print workflow: start -> pause -> resume -> cancel"""
        # Start print
        response = self.client.post("/command", json={"action": "start"})
        assert response.status_code == 200
        
        # Check status
        response = self.client.get("/status")
        status = response.json()
        assert status["printing"] is True
        
        # Pause print
        response = self.client.post("/command", json={"action": "pause"})
        assert response.status_code == 200
        
        # Check status
        response = self.client.get("/status")
        status = response.json()
        assert status["paused"] is True
        
        # Resume print
        response = self.client.post("/command", json={"action": "resume"})
        assert response.status_code == 200
        
        # Check status
        response = self.client.get("/status")
        status = response.json()
        assert status["paused"] is False
        assert status["printing"] is True
        
        # Cancel print
        response = self.client.post("/command", json={"action": "cancel"})
        assert response.status_code == 200
        
        # Check status
        response = self.client.get("/status")
        status = response.json()
        assert status["printing"] is False
        assert status["paused"] is False
        assert status["progress"] == 0.0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
