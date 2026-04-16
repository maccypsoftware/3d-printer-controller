import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/printer_status.dart';

class PrinterService {
  static const String _baseUrl = 'http://192.168.1.100:8000'; // Update with your Pi's IP
  static const String _wsUrl = 'ws://192.168.1.100:8000/ws';
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final StreamController<PrinterStatus> _statusController = 
      StreamController<PrinterStatus>.broadcast();
  
  Stream<PrinterStatus> get statusStream => _statusController.stream;

  Future<PrinterStatus> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/status'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrinterStatus.fromJson(data);
      } else {
        throw Exception('Failed to load printer status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> sendCommand(String action) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send command');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> registerDevice(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );
    } catch (e) {
      print('Failed to register device: $e');
    }
  }

  void connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final statusData = json.decode(data);
            final status = PrinterStatus.fromJson(statusData);
            _statusController.add(status);
          } catch (e) {
            print('Error parsing WebSocket data: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          print('WebSocket disconnected');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      connectWebSocket();
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
  }

  String getCameraStreamUrl() {
    return '$_baseUrl/camera/stream';
  }

  Future<String> getCameraSnapshot() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/camera/snapshot'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['image'];
      } else {
        throw Exception('Failed to get camera snapshot');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
