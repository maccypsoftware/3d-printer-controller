import pytest
import asyncio
from unittest.mock import Mock, patch
from fastapi.testclient import TestClient
from main import app

@pytest.fixture
def client():
    """Create a test client for the FastAPI app"""
    return TestClient(app)

@pytest.fixture
def mock_camera():
    """Mock camera for testing"""
    with patch('main.camera') as mock:
        # Mock camera capture array
        import numpy as np
        mock_frame = np.zeros((480, 640, 3), dtype=np.uint8)
        mock_frame.fill(128)
        mock.capture_array.return_value = mock_frame
        yield mock

@pytest.fixture
def mock_printer_status():
    """Mock printer status for testing"""
    with patch('main.printer_status') as mock:
        mock.return_value = {
            "printing": False,
            "paused": False,
            "progress": 0.0,
            "error_detected": False,
            "error_message": None,
            "print_time_remaining": 0,
            "file_name": None
        }
        yield mock

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()
