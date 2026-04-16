# Prusa 3D Printer Monitor

A comprehensive monitoring system for Prusa MK3S 3D printers with real-time camera preview, error detection, and iOS push notifications.

## Features

- **Live Camera Preview**: Real-time video stream from Raspberry Pi camera
- **Print Control**: Start, pause, resume, and cancel prints remotely
- **Progress Monitoring**: Real-time print progress and time remaining
- **Error Detection**: AI-powered computer vision to detect common print failures
- **Push Notifications**: Instant alerts for print errors and completion on iOS
- **Real-time Updates**: WebSocket connection for live status updates

## Architecture

- **Server**: Python FastAPI running on Raspberry Pi 3
- **Client**: Flutter iOS app for iPhone
- **Communication**: REST API + WebSocket + MJPEG streaming
- **Notifications**: Apple Push Notification Service (APNs)

## Hardware Requirements

### Required Components:
- Prusa MK3S 3D printer
- Raspberry Pi 3 (or newer)
- Raspberry Pi Camera Module
- MicroSD card (16GB+ recommended)
- Power supply for Raspberry Pi
- Ethernet or WiFi connection

### Optional:
- Case for Raspberry Pi
- Camera mount for printer

## Server Setup (Raspberry Pi 3)

### Hardware Requirements

- Raspberry Pi 3 Model B (or B+)
- 16GB+ microSD card (Class 10 or higher)
- Raspberry Pi Camera Module v2 or newer
- Power supply (5V 2.5A minimum)
- Ethernet cable or WiFi connection
- Computer for initial setup

### 1. Prepare the microSD Card

#### Download Required Software
1. Download [Raspberry Pi Imager](https://www.raspberrypi.org/software/)
2. Download [Raspberry Pi OS Lite (64-bit)](https://www.raspberrypi.org/software/operating-systems/)

#### Flash the OS
1. Insert microSD card into your computer
2. Open Raspberry Pi Imager
3. Choose "Raspberry Pi OS Lite (64-bit)"
4. Click "Advanced options" and configure:
   - Set hostname: `prusa-monitor`
   - Enable SSH
   - Set username: `pi`
   - Set password: `your-secure-password`
   - Configure WiFi (if using wireless)
   - Set locale settings
5. Click "Write" and wait for completion

### 2. Initial Boot and SSH Connection

1. Insert microSD card into Raspberry Pi 3
2. Connect Ethernet cable (or ensure WiFi is configured)
3. Connect power supply
4. Wait 2-3 minutes for boot
5. Find IP address (check your router's admin panel)
6. Connect via SSH:
   ```bash
   ssh pi@<raspberry-pi-ip>
   ```

### 3. System Updates and Basic Configuration

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Set up proper locale
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Configure timezone
sudo dpkg-reconfigure tzdata

# Configure keyboard layout (optional)
sudo dpkg-reconfigure keyboard-configuration

# Change hostname if needed
sudo nano /etc/hostname
sudo nano /etc/hosts
# Replace "raspberrypi" with "prusa-monitor"

# Reboot to apply changes
sudo reboot
```

### 4. Install System Dependencies

```bash
# Install build tools and libraries
sudo apt install -y python3-pip python3-venv python3-dev
sudo apt install -y git cmake build-essential pkg-config
sudo apt install -y libjpeg-dev libpng-dev libtiff-dev
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev
sudo apt install -y libv4l-dev libxvidcore-dev libx264-dev
sudo apt install -y libgtk-3-dev libatlas-base-dev gfortran
sudo apt install -y libhdf5-dev libhdf5-serial-dev
sudo apt install -y libqtgui4 libqt4-test

# Install camera libraries
sudo apt install -y libcamera-apps-lite libcamera-v4l2

# Install additional dependencies
sudo apt install -y nginx htop vim curl wget
```

### 5. Enable Camera Interface

```bash
# Enable camera using raspi-config
sudo raspi-config

# Navigate through menu:
# 3 Interface Options
# I1 Legacy Camera
# Enable -> Yes
# Finish -> Yes (reboot)

# Alternative: Enable via config.txt
sudo nano /boot/config.txt
# Add or uncomment:
# start_x=1
# gpu_mem=128

# Reboot
sudo reboot
```

### 6. Configure Camera for Raspberry Pi 3

```bash
# Test camera detection
vcgencmd get_camera
# Should output: supported=1 detected=1

# Test camera capture
raspistill -o test_camera.jpg -t 2000
# Check if test_camera.jpg was created

# If camera not detected, check permissions
sudo usermod -a -G video pi

# Logout and login again for group changes
exit
ssh pi@<raspberry-pi-ip>

# Verify camera permissions
groups pi
# Should include "video" in the output
```

### 7. Install Python Environment

```bash
# Create project directory
mkdir -p /home/pi/3d-printer-controller
cd /home/pi/3d-printer-controller

# Clone the repository
git clone <your-repo-url> .

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python packages
pip install -r server/requirements.txt

# Install Raspberry Pi specific packages
pip install picamera2
pip install numpy --upgrade
```

### 8. Environment Configuration

```bash
# Create environment file
cd /home/pi/3d-printer-controller/server
cp .env.example .env
nano .env
```

Example configuration for Raspberry Pi 3:
```bash
HOST=0.0.0.0
PORT=8000
PRUSA_IP=192.168.1.50
PRUSA_API_KEY=
PRUSE_SERIAL_PORT=/dev/ttyUSB0
APNS_CERT_PATH=/home/pi/3d-printer-controller/server/certificates/apns_cert.pem
APNS_KEY_PATH=/home/pi/3d-printer-controller/server/certificates/apns_key.pem
APNS_USE_SANDBOX=true
LOG_LEVEL=INFO
CAMERA_RESOLUTION=640,480
CAMERA_FRAMERATE=15
ERROR_DETECTION_INTERVAL=10
ERROR_NOTIFICATION_COOLDOWN=120
```

### 9. Network Configuration

#### Static IP (Recommended)
```bash
# Configure static IP
sudo nano /etc/dhcpcd.conf

# Add at the end:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4

# For WiFi, use:
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4

# Reboot
sudo reboot
```

#### Port Forwarding (if needed)
Configure your router to forward:
- Port 8000 (HTTP server)
- Port 443 (HTTPS, if using SSL)

### 10. Start the Server

```bash
# For development (auto-restart on changes)
cd /home/pi/3d-printer-controller/server
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# For production
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 11. Create System Service (Optional)

```bash
# Create service file
sudo nano /etc/systemd/system/prusa-monitor.service
```

Service configuration:
```ini
[Unit]
Description=Prusa Printer Monitor
After=network.target

[Service]
Type=simple
User=pi
Group=video
WorkingDirectory=/home/pi/3d-printer-controller/server
Environment=PATH=/home/pi/3d-printer-controller/server/venv/bin
ExecStart=/home/pi/3d-printer-controller/server/venv/bin/python main.py
ExecStartPost=/bin/sleep 10
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable prusa-monitor
sudo systemctl start prusa-monitor

# Check status
sudo systemctl status prusa-monitor

# View logs
sudo journalctl -u prusa-monitor -f
```

### 12. Firewall Configuration

```bash
# Install and configure UFW
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow application ports
sudo ufw allow 8000/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### 13. Performance Optimization for Raspberry Pi 3

#### Memory Management
```bash
# Create swap file for better memory handling
sudo nano /etc/sysctl.conf

# Add these lines:
vm.swappiness=10
vm.vfs_cache_pressure=50

# Apply changes
sudo sysctl -p
```

#### GPU Memory Split
```bash
# Configure GPU memory allocation
sudo nano /boot/config.txt

# Add or modify:
gpu_mem=64
```

#### Disable GUI (if not needed)
```bash
# Ensure booting to console
sudo raspi-config
# 3 Boot Options
# B1 Desktop / CLI
# B1 Console Autologin
```

### 14. Monitor and Maintenance

#### System Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop

# Monitor CPU usage
htop

# Monitor disk usage
df -h

# Monitor memory
free -h

# Monitor temperature
vcgencmd measure_temp
```

#### Log Management
```bash
# Configure log rotation
sudo nano /etc/logrotate.d/prusa-monitor

# Content:
/home/pi/3d-printer-controller/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 pi pi
}
```

#### Backup Script
```bash
# Create backup script
nano /home/pi/backup-3d-printer-controller.sh
```

Backup script content:
```bash
#!/bin/bash
BACKUP_DIR="/home/pi/backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/home/pi/3d-printer-controller"

mkdir -p $BACKUP_DIR

# Backup configuration and logs
tar -czf "$BACKUP_DIR/3d-printer-controller_$DATE.tar.gz" \
    -C "$PROJECT_DIR" \
    server/.env \
    server/certificates/ \
    logs/

# Keep only last 7 days of backups
find $BACKUP_DIR -name "3d-printer-controller_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/3d-printer-controller_$DATE.tar.gz"
```

```bash
# Make executable
chmod +x /home/pi/backup-3d-printer-controller.sh

# Add to crontab for daily backup
crontab -e
# Add line:
# 0 2 * * * /home/pi/backup-3d-printer-controller.sh
```

### 15. Testing the Setup

```bash
# Test server locally
curl http://localhost:8000/status

# Test camera
curl http://localhost:8000/camera/snapshot

# Test from another computer on network
curl http://<raspberry-pi-ip>:8000/status

# Check WebSocket connection
wscat -c ws://<raspberry-pi-ip>:8000/ws
```

### 16. Troubleshooting Common Issues

#### Camera Not Working
```bash
# Check camera connection
vcgencmd get_camera

# Test camera manually
raspistill -o test.jpg -t 2000

# Check camera permissions
groups pi

# Re-enable camera
sudo raspi-config -> Interface Options -> Camera -> Enable
```

#### Server Not Starting
```bash
# Check service status
sudo systemctl status prusa-monitor

# View logs
sudo journalctl -u prusa-monitor -n 50

# Check Python environment
source venv/bin/activate
python -c "import fastapi; print('FastAPI OK')"
python -c "import picamera2; print('Camera OK')"
```

#### Performance Issues
```bash
# Check CPU temperature
vcgencmd measure_temp

# Monitor CPU usage
top

# Check memory usage
free -h

# Reduce camera resolution if needed
# Edit .env file:
# CAMERA_RESOLUTION=320,240
# CAMERA_FRAMERATE=10
```

#### Network Issues
```bash
# Check network configuration
ip addr show

# Test connectivity
ping 8.8.8.8

# Check DNS
nslookup google.com

# Restart network service
sudo systemctl restart networking
```

### 17. Security Hardening

```bash
# Change default password
passwd

# Disable password authentication (use SSH keys)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no

# Fail2ban for SSH protection
sudo apt install fail2ban

# Update system regularly
sudo apt update && sudo apt upgrade -y
```

## iOS Client Setup

### 1. Install Flutter

```bash
# Follow official Flutter installation guide
# https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor
```

### 2. Setup iOS Development

```bash
# Install Xcode from App Store
# Install Xcode Command Line Tools
xcode-select --install

# Setup iOS Simulator
flutter config --enable-ios
```

### 3. Configure the App

```bash
# Navigate to client directory
cd client

# Install dependencies
flutter pub get

# Update server IP in lib/services/printer_service.dart
# Change the _baseUrl to your Raspberry Pi IP
```

### 4. Run on iOS Simulator

```bash
# Check available devices
flutter devices

# Run on iOS Simulator
flutter run -d ios

# Or run on physical device (connected via USB)
flutter run -d <device-id>
```

### 5. Build for App Store

```bash
# Build release version
flutter build ios --release

# Open Xcode project for App Store submission
open ios/Runner.xcworkspace
```

## Push Notification Setup

### 1. Create APNs Certificate

1. Go to Apple Developer Portal
2. Navigate to: Certificates, Identifiers & Profiles
3. Create a new App ID with Push Notifications capability
4. Create a Development/Production Push Notification Certificate
5. Download the certificate (.p12 file)

### 2. Convert Certificate for Python

```bash
# Convert .p12 to .pem
openssl pkcs12 -in your_cert.p12 -out apns_cert.pem -nodes -clcerts
openssl pkcs12 -in your_cert.p12 -out apns_key.pem -nodes

# Copy to Raspberry Pi
scp apns_cert.pem pi@<raspberry-pi-ip>:~/prusa-printer-monitor/server/certificates/
scp apns_key.pem pi@<raspberry-pi-ip>:~/prusa-printer-monitor/server/certificates/
```

### 3. Update Server Configuration

Edit `.env` file:
```bash
APNS_CERT_PATH=/home/pi/prusa-printer-monitor/server/certificates/apns_cert.pem
APNS_KEY_PATH=/home/pi/prusa-printer-monitor/server/certificates/apns_key.pem
APNS_USE_SANDBOX=true  # false for production
```

## Prusa Printer Integration

### Option 1: Prusa Connect API

1. Create account at [Prusa Connect](https://connect.prusa3d.com/)
2. Link your printer to Prusa Connect
3. Get your API key from account settings
4. Update `PRUSA_API_KEY` in `.env` file

### Option 2: Direct Serial Connection

```bash
# Find printer serial port
ls /dev/tty*

# Update PRUSE_SERIAL_PORT in .env
# Common values: /dev/ttyUSB0, /dev/ttyACM0
```

## Usage

### Server
1. Start the server on Raspberry Pi
2. Ensure camera is working: `http://<pi-ip>:8000/camera/stream`
3. Check API status: `http://<pi-ip>:8000/status`

### iOS App
1. Install and open the app
2. The app will automatically connect to the server
3. View live camera feed and printer status
4. Control prints remotely
5. Receive push notifications for errors and completion

## API Endpoints

- `GET /status` - Get current printer status
- `POST /command` - Send printer command (start/pause/resume/cancel)
- `GET /camera/stream` - MJPEG camera stream
- `GET /camera/snapshot` - Single camera frame as base64
- `POST /register-device` - Register iOS device for push notifications
- `WebSocket /ws` - Real-time status updates

## Troubleshooting

### Camera Issues
```bash
# Check if camera is detected
vcgencmd get_camera

# Test camera manually
raspistill -o test.jpg

# Check permissions
groups $USER  # Should include 'video'
```

### Network Issues
```bash
# Check server is running
curl http://localhost:8000/status

# Check firewall
sudo ufw status

# Check port availability
netstat -tulpn | grep :8000
```

### Push Notification Issues
```bash
# Test APNs connection
python3 -c "
from apns2.client import APNsClient
client = APNsClient('cert.pem', use_sandbox=True)
print('APNs connection successful')
"
```

## Development

### Server Development
```bash
# Install development dependencies
pip install pytest pytest-asyncio black flake8

# Run tests
pytest

# Code formatting
black *.py

# Linting
flake8 *.py
```

### Client Development
```bash
# Install development dependencies
flutter pub add --dev flutter_test

# Run tests
flutter test

# Code analysis
flutter analyze
```

## Security Considerations

- Change default Raspberry Pi password
- Use HTTPS in production (add SSL certificate)
- Restrict API access with authentication
- Keep software updated
- Use firewall to restrict access

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section
2. Search existing GitHub issues
3. Create a new issue with detailed information

---

**Note**: This is a comprehensive monitoring system. Always supervise your 3D printer and never leave it completely unattended, even with monitoring systems in place.
