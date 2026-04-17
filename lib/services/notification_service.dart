import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _tokenKey = 'push_token';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize push notifications
    await _initializePushNotifications();
  }

  static Future<void> _requestPermissions() async {
    // Request notification permission for iOS
    final notificationStatus = await Permission.notification.request();
    
    if (notificationStatus.isGranted) {
      print('Notification permission granted');
    } else {
      print('Notification permission denied');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static Future<void> _initializePushNotifications() async {
    // This would integrate with APNs
    // For now, we'll use a mock implementation
    // In a real app, you'd use firebase_messaging or similar
    
    // Simulate getting a device token
    const mockToken = 'mock_ios_device_token_12345';
    await _saveDeviceToken(mockToken);
    
    print('Push notifications initialized with mock token');
  }

  static Future<void> _saveDeviceToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('Device token saved: $token');
    } catch (e) {
      print('Failed to save device token: $e');
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Failed to get device token: $e');
      return null;
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'printer_monitor_channel',
      'Printer Monitor Notifications',
      channelDescription: 'Notifications for 3D printer status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    handleNotificationTap(response.payload);
  }

  static void handleNotificationTap(String? payload) {
    // Handle notification tap
    print('Notification tapped with payload: $payload');
  }
}
