# Testing Guide

This guide provides comprehensive instructions for running tests for both the Python server and Flutter client of the 3D Printer Controller application.

## Overview

The project includes comprehensive test suites covering:
- **Server Tests**: Unit tests, integration tests, and API endpoint tests
- **Client Tests**: Unit tests, widget tests, and integration tests for Flutter app

## Prerequisites

### Server Testing Prerequisites
- Python 3.8+ installed
- Virtual environment activated
- Test dependencies installed

### Client Testing Prerequisites
- Flutter SDK installed
- iOS Simulator or physical device
- Test dependencies installed

## Server Testing

### 1. Setup Test Environment

```bash
# Navigate to server directory
cd server

# Activate virtual environment
source venv/bin/activate

# Install test dependencies
pip install -r requirements.txt
```

### 2. Run All Server Tests

```bash
# Run all tests with verbose output
pytest tests/ -v

# Run with coverage report
pytest tests/ --cov=. --cov-report=html

# Run specific test file
pytest tests/test_main.py -v

# Run specific test class
pytest tests/test_main.py::TestPrinterStatusAPI -v

# Run specific test method
pytest tests/test_main.py::TestPrinterStatusAPI::test_get_status_endpoint -v
```

### 3. Server Test Categories

#### API Endpoint Tests
- `TestPrinterStatusAPI`: Tests all REST API endpoints
- Test status retrieval, command sending, device registration

#### Camera Tests
- `TestCameraEndpoints`: Tests camera-related endpoints
- Test snapshot capture, video streaming

#### Error Detection Tests
- `TestErrorDetection`: Tests computer vision error detection
- Test spaghetti detection, dark frame detection

#### WebSocket Tests
- `TestWebSocketConnection`: Tests real-time communication
- Test connection, status updates

#### Integration Tests
- `TestIntegration`: Tests complete workflows
- Test full print lifecycle

### 4. Running Server Tests with Different Options

```bash
# Run tests with detailed output
pytest tests/ -v -s

# Run tests with coverage
pytest tests/ --cov=main --cov-report=term-missing

# Run tests and generate HTML coverage report
pytest tests/ --cov=. --cov-report=html
# Open coverage report
open htmlcov/index.html

# Run tests in parallel (faster execution)
pytest tests/ -n auto

# Run tests with markers
pytest tests/ -m "not slow"  # Skip slow tests
pytest tests/ -m "unit"      # Run only unit tests
```

### 5. Server Test Configuration

Create `pytest.ini` for custom configuration:

```ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow running tests
    camera: Tests requiring camera hardware
```

### 6. Mocking and Test Doubles

The server tests use mocking to avoid hardware dependencies:

```python
# Mock camera for tests
@patch('main.camera')
def test_camera_snapshot_success(self, mock_camera):
    mock_frame = np.zeros((480, 640, 3), dtype=np.uint8)
    mock_camera.capture_array.return_value = mock_frame
    # Test logic here
```

### 7. Server Test Troubleshooting

```bash
# Check test dependencies
pip list | grep pytest

# Run tests with debugging
pytest tests/ --pdb

# Check specific test failure
pytest tests/test_main.py::TestPrinterStatusAPI::test_get_status_endpoint -v -s
```

## Client Testing

### 1. Setup Test Environment

```bash
# Navigate to client directory
cd client

# Install dependencies
flutter pub get

# Install test dependencies
flutter pub dev

# Generate mock files
flutter packages pub run build_runner build
```

### 2. Run All Client Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run tests in verbose mode
flutter test --verbose

# Run specific test file
flutter test test/unit_test.dart

# Run specific test group
flutter test --name "PrinterStatus Model Tests"
```

### 3. Client Test Categories

#### Unit Tests
- **Model Tests**: Test data models and business logic
- **Service Tests**: Test API services and networking
- **ViewModel Tests**: Test state management and business logic

#### Widget Tests
- **Widget Tests**: Test individual widgets in isolation
- **Integration Tests**: Test widget interactions and user flows

### 4. Running Client Tests with Different Options

```bash
# Run tests on specific platform
flutter test --platform ios

# Run tests on specific device
flutter test -d "iPhone 14"

# Run tests with golden file updates
flutter test --update-goldens

# Run tests with specific tags
flutter test --tags="unit"
flutter test --tags="widget"

# Run tests and generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 5. Client Test Configuration

Create `analysis_options.yaml` for test configuration:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print

test:
  exclude:
    - "**/test/mocks/**"
```

### 6. Mock Generation

```bash
# Generate mocks for testing
flutter packages pub run build_runner build

# Generate mocks with watch mode
flutter packages pub run build_runner watch --delete-conflicting-outputs

# Clean and regenerate mocks
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 7. Client Test Troubleshooting

```bash
# Check test dependencies
flutter doctor

# Run tests with debugging
flutter test --debug

# Run specific test
flutter test --plain-name "test_statusText_should_return_correct_values"

# Check test coverage
flutter test --coverage && lcov --summary coverage/lcov.info
```

## Continuous Integration Testing

### GitHub Actions Setup

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test-server:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          cd server
          pip install -r requirements.txt
      - name: Run tests
        run: |
          cd server
          pytest tests/ --cov=. --cov-report=xml

  test-client:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - name: Install dependencies
        run: |
          cd client
          flutter pub get
      - name: Run tests
        run: |
          cd client
          flutter test --coverage
```

## Test Data and Fixtures

### Server Test Fixtures

Create `tests/fixtures/` directory:

```python
# tests/fixtures/sample_responses.py
SAMPLE_PRINTER_STATUS = {
    "printing": True,
    "paused": False,
    "progress": 45.5,
    "error_detected": False,
    "print_time_remaining": 3600,
    "file_name": "test_print.gcode"
}

SAMPLE_ERROR_RESPONSE = {
    "error_detected": True,
    "error_message": "Spaghetti detected - possible filament extrusion issue"
}
```

### Client Test Assets

Create `test/assets/` directory:

```dart
// test/assets/test_data.dart
const String kSamplePrinterStatusJson = '''
{
  "printing": true,
  "paused": false,
  "progress": 45.5,
  "error_detected": false,
  "print_time_remaining": 3600,
  "file_name": "test_print.gcode"
}
''';
```

## Performance Testing

### Server Performance Tests

```bash
# Install performance testing dependencies
pip install pytest-benchmark

# Run performance tests
pytest tests/test_performance.py --benchmark-only
```

### Client Performance Tests

```bash
# Run integration tests with performance profiling
flutter test --profile
flutter test --trace-startup
```

## End-to-End Testing

### Setup E2E Tests

```bash
# Install integration_test package
flutter pub add integration_test

# Run E2E tests
flutter test integration_test/
```

### E2E Test Example

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prusa_monitor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Test complete user flow
    // 1. App loads
    // 2. Connects to server
    // 3. Displays printer status
    // 4. User can control printer
  });
}
```

## Test Best Practices

### Server Testing Best Practices

1. **Use Fixtures**: Reuse test data with pytest fixtures
2. **Mock External Dependencies**: Mock camera, printer, and network calls
3. **Test Edge Cases**: Test error conditions and boundary values
4. **Use Descriptive Names**: Make test names self-documenting
5. **Arrange-Act-Assert**: Structure tests clearly

### Client Testing Best Practices

1. **Widget Isolation**: Test widgets independently
2. **Mock Services**: Use mockito for service dependencies
3. **Golden Testing**: Use golden tests for UI consistency
4. **Accessibility Testing**: Include accessibility tests
5. **Platform Testing**: Test on iOS and Android

## Troubleshooting Common Issues

### Server Test Issues

**Import Errors**:
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Install missing dependencies
pip install -r requirements.txt
```

**Camera Tests Failing**:
```bash
# Skip camera tests if no hardware
pytest tests/ -k "not camera"

# Use mock camera
export MOCK_CAMERA=1
pytest tests/
```

### Client Test Issues

**Mock Generation Failing**:
```bash
# Clean and regenerate
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Widget Tests Failing**:
```bash
# Check platform compatibility
flutter test --platform ios

# Update golden files
flutter test --update-goldens
```

## Coverage Reports

### Server Coverage

```bash
# Generate HTML coverage report
pytest tests/ --cov=. --cov-report=html

# View coverage
open htmlcov/index.html
```

### Client Coverage

```bash
# Generate coverage report
flutter test --coverage

# Convert to HTML
genhtml coverage/lcov.info -o coverage/html

# View coverage
open coverage/html/index.html
```

## Running Tests Locally - Quick Start

### Server Tests Quick Start

```bash
cd server
source venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

### Client Tests Quick Start

```bash
cd client
flutter pub get
flutter packages pub run build_runner build
flutter test
```

## Test Documentation

- **Server Tests**: Located in `server/tests/`
- **Client Tests**: Located in `client/test/`
- **Test Fixtures**: `server/tests/fixtures/` and `client/test/assets/`
- **Mock Files**: Generated in `client/test/mocks/`

For more detailed information about specific test cases, refer to the inline documentation in the test files.
