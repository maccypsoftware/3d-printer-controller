import 'package:flutter/foundation.dart';
import '../models/printer_status.dart';
import '../services/printer_service.dart';
import '../services/notification_service.dart';

class PrinterViewModel extends ChangeNotifier {
  final PrinterService _printerService = PrinterService();
  
  PrinterStatus? _currentStatus;
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;

  PrinterStatus? get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;

  PrinterViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadStatus();
    _connectWebSocket();
    _registerDevice();
  }

  Future<void> loadStatus() async {
    _setLoading(true);
    _clearError();
    
    try {
      final status = await _printerService.getStatus();
      _currentStatus = status;
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load printer status: $e');
      _isConnected = false;
    } finally {
      _setLoading(false);
    }
  }

  void _connectWebSocket() {
    _printerService.statusStream.listen(
      (status) {
        _currentStatus = status;
        _isConnected = true;
        _clearError();
        notifyListeners();
        
        // Check for errors and show local notification
        if (status.errorDetected && status.errorMessage != null) {
          NotificationService.showLocalNotification(
            title: 'Print Error Detected',
            body: status.errorMessage!,
          );
        }
        
        // Check for print completion
        if (!status.printing && !status.paused && status.progress >= 99.0) {
          NotificationService.showLocalNotification(
            title: 'Print Completed',
            body: 'Your 3D print has finished successfully!',
          );
        }
      },
      onError: (error) {
        _setError('WebSocket error: $error');
        _isConnected = false;
      },
    );
    
    _printerService.connectWebSocket();
  }

  Future<void> _registerDevice() async {
    final token = await NotificationService.getDeviceToken();
    if (token != null) {
      await _printerService.registerDevice(token);
    }
  }

  Future<void> startPrint() async {
    await _sendCommand('start');
  }

  Future<void> pausePrint() async {
    await _sendCommand('pause');
  }

  Future<void> resumePrint() async {
    await _sendCommand('resume');
  }

  Future<void> cancelPrint() async {
    await _sendCommand('cancel');
  }

  Future<void> _sendCommand(String action) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _printerService.sendCommand(action);
      if (!success) {
        _setError('Failed to send command');
      }
      // Status will be updated via WebSocket
    } catch (e) {
      _setError('Command failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  String getCameraStreamUrl() {
    return _printerService.getCameraStreamUrl();
  }

  Future<String> getCameraSnapshot() async {
    try {
      return await _printerService.getCameraSnapshot();
    } catch (e) {
      _setError('Failed to get camera snapshot: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _printerService.disconnect();
    super.dispose();
  }
}
