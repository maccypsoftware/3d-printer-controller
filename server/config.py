"""
Configuration settings for Prusa Printer Monitor Server
"""

import os
from typing import Optional

class Config:
    # Server settings
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", "8000"))
    
    # Camera settings
    CAMERA_RESOLUTION = (640, 480)
    CAMERA_FRAMERATE = 30
    
    # Prusa printer settings
    PRUSA_IP = os.getenv("PRUSA_IP", "192.168.1.100")  # Default Prusa IP
    PRUSA_API_KEY = os.getenv("PRUSA_API_KEY", "")  # Prusa Connect API key
    PRUSE_SERIAL_PORT = os.getenv("PRUSE_SERIAL_PORT", "/dev/ttyUSB0")  # Direct serial connection
    
    # Push notification settings
    APNS_CERT_PATH = os.getenv("APNS_CERT_PATH", "certificates/apns_cert.pem")
    APNS_KEY_PATH = os.getenv("APNS_KEY_PATH", "certificates/apns_key.pem")
    APNS_USE_SANDBOX = os.getenv("APNS_USE_SANDBOX", "true").lower() == "true"
    
    # Error detection settings
    ERROR_DETECTION_INTERVAL = 5  # seconds
    ERROR_NOTIFICATION_COOLDOWN = 60  # seconds
    
    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    
    # Security
    ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Camera configuration
CAMERA_CONFIG = {
    "main": {"size": Config.CAMERA_RESOLUTION},
    "lores": {"size": (320, 240)},
    "transform": None
}
