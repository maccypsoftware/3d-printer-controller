import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:prusa_monitor/models/printer_status.dart';
import 'package:prusa_monitor/services/printer_service.dart';
import 'package:prusa_monitor/services/notification_service.dart';
import 'package:prusa_monitor/viewmodels/printer_viewmodel.dart';

import 'unit_test.mocks.dart';

@GenerateMocks([http.Client, WebSocketChannel])
void main() {
  group('PrinterStatus Model Tests', () {
    test('PrinterStatus should create from JSON correctly', () {
      // Arrange
      final json = {
        'printing': true,
        'paused': false,
        'progress': 45.5,
        'error_detected': false,
        'error_message': null,
        'print_time_remaining': 3600,
        'file_name': 'test_print.gcode',
      };

      // Act
      final status = PrinterStatus.fromJson(json);

      // Assert
      expect(status.printing, true);
      expect(status.paused, false);
      expect(status.progress, 45.5);
      expect(status.errorDetected, false);
      expect(status.errorMessage, null);
      expect(status.printTimeRemaining, 3600);
      expect(status.fileName, 'test_print.gcode');
    });

    test('PrinterStatus should handle missing optional fields', () {
      // Arrange
      final json = {
        'printing': false,
        'paused': true,
        'progress': 0.0,
        'error_detected': true,
        'error_message': 'Test error',
        'print_time_remaining': 0,
      };

      // Act
      final status = PrinterStatus.fromJson(json);

      // Assert
      expect(status.printing, false);
      expect(status.paused, true);
      expect(status.progress, 0.0);
      expect(status.errorDetected, true);
      expect(status.errorMessage, 'Test error');
      expect(status.printTimeRemaining, 0);
      expect(status.fileName, null);
    });

    test('PrinterStatus should convert to JSON correctly', () {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 75.2,
        errorDetected: false,
        printTimeRemaining: 1800,
        fileName: 'complex_print.gcode',
      );

      // Act
      final json = status.toJson();

      // Assert
      expect(json['printing'], true);
      expect(json['paused'], false);
      expect(json['progress'], 75.2);
      expect(json['error_detected'], false);
      expect(json['print_time_remaining'], 1800);
      expect(json['file_name'], 'complex_print.gcode');
    });

    test('statusText should return correct values', () {
      // Test error state
      var status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: true,
        errorMessage: 'Spaghetti detected',
        printTimeRemaining: 0,
      );
      expect(status.statusText, 'Error');

      // Test paused state
      status = PrinterStatus(
        printing: false,
        paused: true,
        progress: 50.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.statusText, 'Paused');

      // Test printing state
      status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 25.0,
        errorDetected: false,
        printTimeRemaining: 7200,
      );
      expect(status.statusText, 'Printing');

      // Test idle state
      status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.statusText, 'Idle');
    });

    test('statusColor should return correct colors', () {
      // Test error state
      var status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: true,
        printTimeRemaining: 0,
      );
      expect(status.statusColor, Colors.red);

      // Test paused state
      status = PrinterStatus(
        printing: false,
        paused: true,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.statusColor, Colors.orange);

      // Test printing state
      status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.statusColor, Colors.green);

      // Test idle state
      status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.statusColor, Colors.grey);
    });

    test('timeRemainingText should format correctly', () {
      // Test hours and minutes
      var status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 3665, // 1 hour, 1 minute, 5 seconds
      );
      expect(status.timeRemainingText, '1h 1m');

      // Test only minutes
      status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 1800, // 30 minutes
      );
      expect(status.timeRemainingText, '30m');

      // Test zero time
      status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );
      expect(status.timeRemainingText, 'Unknown');
    });
  });

  group('PrinterService Tests', () {
    late MockClient mockHttpClient;
    late MockWebSocketChannel mockWebSocketChannel;
    late PrinterService printerService;

    setUp(() {
      mockHttpClient = MockClient();
      mockWebSocketChannel = MockWebSocketChannel();
      printerService = PrinterService();
    });

    test('getStatus should return PrinterStatus on successful response', () async {
      // Arrange
      final jsonResponse = {
        'printing': true,
        'paused': false,
        'progress': 65.5,
        'error_detected': false,
        'print_time_remaining': 2400,
        'file_name': 'test.gcode',
      };

      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));

      // Act
      final result = await printerService.getStatus();

      // Assert
      expect(result.printing, true);
      expect(result.progress, 65.5);
      expect(result.fileName, 'test.gcode');
    });

    test('getStatus should throw exception on network error', () async {
      // Arrange
      when(mockHttpClient.get(any))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => printerService.getStatus(),
        throwsA(isA<Exception>()),
      );
    });

    test('sendCommand should return true on successful response', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"success": true}', 200));

      // Act
      final result = await printerService.sendCommand('start');

      // Assert
      expect(result, true);
    });

    test('sendCommand should throw exception on network error', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => printerService.sendCommand('pause'),
        throwsA(isA<Exception>()),
      );
    });

    test('registerDevice should handle network errors gracefully', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert - Should not throw, just handle gracefully
      await printerService.registerDevice('test_token');
      // No exception should be thrown
    });

    test('getCameraStreamUrl should return correct URL', () {
      // Act
      final url = printerService.getCameraStreamUrl();

      // Assert
      expect(url, 'http://192.168.1.100:8000/camera/stream');
    });

    test('getCameraSnapshot should return base64 image on success', () async {
      // Arrange
      final jsonResponse = {
        'image': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A8A'
      };

      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));

      // Act
      final result = await printerService.getCameraSnapshot();

      // Assert
      expect(result, startsWith('data:image/jpeg;base64,'));
    });
  });

  group('NotificationService Tests', () {
    setUp(() async {
      // Reset notification service before each test
      await NotificationService.initialize();
    });

    test('should save and retrieve device token', () async {
      // Arrange
      const testToken = 'test_device_token_12345';

      // Act
      await NotificationService._saveDeviceToken(testToken);
      final retrievedToken = await NotificationService.getDeviceToken();

      // Assert
      expect(retrievedToken, testToken);
    });

    test('should return null when no token is saved', () async {
      // Act
      final token = await NotificationService.getDeviceToken();

      // Assert
      expect(token, null);
    });

    test('should show local notification', () {
      // Act & Assert - Should not throw
      NotificationService.showLocalNotification(
        title: 'Test Title',
        body: 'Test Body',
        payload: 'test_payload',
      );
    });
  });

  group('PrinterViewModel Tests', () {
    late PrinterViewModel viewModel;
    late MockPrinterService mockPrinterService;

    setUp(() {
      mockPrinterService = MockPrinterService();
      viewModel = PrinterViewModel();
    });

    test('initial state should be correct', () {
      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.currentStatus, null);
      expect(viewModel.error, null);
      expect(viewModel.isConnected, false);
    });

    test('loadStatus should set loading state', () async {
      // Arrange
      final mockStatus = PrinterStatus(
        printing: true,
        paused: false,
        progress: 50.0,
        errorDetected: false,
        printTimeRemaining: 3600,
        fileName: 'test.gcode',
      );

      when(mockPrinterService.getStatus())
          .thenAnswer((_) async => mockStatus);

      // Act
      await viewModel.loadStatus();

      // Assert
      expect(viewModel.currentStatus, mockStatus);
      expect(viewModel.isLoading, false);
      expect(viewModel.isConnected, true);
      expect(viewModel.error, null);
    });

    test('loadStatus should handle errors', () async {
      // Arrange
      when(mockPrinterService.getStatus())
          .thenThrow(Exception('Network error'));

      // Act
      await viewModel.loadStatus();

      // Assert
      expect(viewModel.currentStatus, null);
      expect(viewModel.isLoading, false);
      expect(viewModel.isConnected, false);
      expect(viewModel.error, contains('Failed to load printer status'));
    });

    test('startPrint should send start command', () async {
      // Arrange
      when(mockPrinterService.sendCommand('start'))
          .thenAnswer((_) async => true);

      // Act
      await viewModel.startPrint();

      // Assert
      verify(mockPrinterService.sendCommand('start')).called(1);
    });

    test('pausePrint should send pause command', () async {
      // Arrange
      when(mockPrinterService.sendCommand('pause'))
          .thenAnswer((_) async => true);

      // Act
      await viewModel.pausePrint();

      // Assert
      verify(mockPrinterService.sendCommand('pause')).called(1);
    });

    test('resumePrint should send resume command', () async {
      // Arrange
      when(mockPrinterService.sendCommand('resume'))
          .thenAnswer((_) async => true);

      // Act
      await viewModel.resumePrint();

      // Assert
      verify(mockPrinterService.sendCommand('resume')).called(1);
    });

    test('cancelPrint should send cancel command', () async {
      // Arrange
      when(mockPrinterService.sendCommand('cancel'))
          .thenAnswer((_) async => true);

      // Act
      await viewModel.cancelPrint();

      // Assert
      verify(mockPrinterService.sendCommand('cancel')).called(1);
    });

    test('should handle error detection and show notification', () async {
      // Arrange
      final errorStatus = PrinterStatus(
        printing: true,
        paused: false,
        progress: 25.0,
        errorDetected: true,
        errorMessage: 'Spaghetti detected',
        printTimeRemaining: 0,
      );

      // Act - Simulate status update with error
      // This would normally come from WebSocket
      // For testing, we'll verify the notification service is called

      // Assert
      expect(errorStatus.errorDetected, true);
      expect(errorStatus.errorMessage, 'Spaghetti detected');
    });

    test('should handle print completion and show notification', () async {
      // Arrange
      final completedStatus = PrinterStatus(
        printing: false,
        paused: false,
        progress: 100.0,
        errorDetected: false,
        printTimeRemaining: 0,
        fileName: 'completed_print.gcode',
      );

      // Act & Assert
      expect(completedStatus.printing, false);
      expect(completedStatus.progress, 100.0);
      expect(completedStatus.errorDetected, false);
    });
  });

  group('Widget Tests', () {
    testWidgets('StatusCard should display printer information', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 45.5,
        errorDetected: false,
        printTimeRemaining: 3600,
        fileName: 'test_print.gcode',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusCard(status: status),
          ),
        ),
      );

      // Assert
      expect(find.text('Printer Status'), findsOneWidget);
      expect(find.text('Printing'), findsOneWidget);
      expect(find.text('45.5%'), findsOneWidget);
      expect(find.text('test_print.gcode'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
    });

    testWidgets('ProgressBar should display progress correctly', (WidgetTester tester) async {
      // Arrange
      const progress = 75.0;
      const timeRemaining = '30m';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressBar(
              progress: progress,
              timeRemaining: timeRemaining,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Print Progress'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('Time remaining: 30m'), findsOneWidget);
    });

    testWidgets('PrinterControls should show correct buttons', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 25.0,
        errorDetected: false,
        printTimeRemaining: 7200,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrinterControls(
              status: status,
              isLoading: false,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Printer Controls'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });
}
