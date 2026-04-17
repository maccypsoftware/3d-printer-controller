import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:prusa_monitor/screens/home_screen.dart';
import 'package:prusa_monitor/viewmodels/printer_viewmodel.dart';
import 'package:prusa_monitor/widgets/status_card.dart';
import 'package:prusa_monitor/widgets/progress_bar.dart';
import 'package:prusa_monitor/widgets/printer_controls.dart';
import 'package:prusa_monitor/widgets/camera_preview.dart';
import 'package:prusa_monitor/models/printer_status.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([PrinterViewModel])
void main() {
  group('HomeScreen Widget Tests', () {
    late MockPrinterViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockPrinterViewModel();
    });

    testWidgets('HomeScreen should show loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.isLoading).thenReturn(true);
      when(mockViewModel.currentStatus).thenReturn(null);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<PrinterViewModel>(
          create: (_) => mockViewModel,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('HomeScreen should show error state', (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.currentStatus).thenReturn(null);
      when(mockViewModel.error).thenReturn('Connection failed');

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<PrinterViewModel>(
          create: (_) => mockViewModel,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('HomeScreen should show status when loaded', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 45.5,
        errorDetected: false,
        printTimeRemaining: 3600,
        fileName: 'test_print.gcode',
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.currentStatus).thenReturn(status);
      when(mockViewModel.isConnected).thenReturn(true);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<PrinterViewModel>(
          create: (_) => mockViewModel,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byType(StatusCard), findsOneWidget);
      expect(find.byType(CameraPreview), findsOneWidget);
      expect(find.byType(ProgressBar), findsOneWidget);
      expect(find.byType(PrinterControls), findsOneWidget);
    });

    testWidgets('HomeScreen should show error alert when detected', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 25.0,
        errorDetected: true,
        errorMessage: 'Spaghetti detected',
        printTimeRemaining: 0,
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.currentStatus).thenReturn(status);
      when(mockViewModel.isConnected).thenReturn(true);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<PrinterViewModel>(
          create: (_) => mockViewModel,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Print Error Detected'), findsOneWidget);
      expect(find.text('Spaghetti detected'), findsOneWidget);
    });
  });

  group('StatusCard Widget Tests', () {
    testWidgets('StatusCard should display null status correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusCard(status: null),
          ),
        ),
      );

      // Assert
      expect(find.text('Printer Status'), findsOneWidget);
      expect(find.text('No status available'), findsOneWidget);
    });

    testWidgets('StatusCard should display error status correctly', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: false,
        paused: true,
        progress: 50.0,
        errorDetected: true,
        errorMessage: 'Print failed',
        printTimeRemaining: 0,
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
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget); // time remaining
    });
  });

  group('ProgressBar Widget Tests', () {
    testWidgets('ProgressBar should show 0% progress', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressBar(
              progress: 0.0,
              timeRemaining: '10m',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Print Progress'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('Time remaining: 10m'), findsOneWidget);
    });

    testWidgets('ProgressBar should show 100% progress', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressBar(
              progress: 100.0,
              timeRemaining: 'Complete',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Print Progress'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('Time remaining: Complete'), findsOneWidget);
    });

    testWidgets('ProgressBar should have correct color for completion', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressBar(
              progress: 100.0,
              timeRemaining: 'Complete',
            ),
          ),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.valueColor, Colors.green);
    });
  });

  group('PrinterControls Widget Tests', () {
    testWidgets('PrinterControls should show start button when idle', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
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
      expect(find.text('Start Print'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Resume'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('PrinterControls should show pause/cancel when printing', (WidgetTester tester) async {
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
      expect(find.text('Start Print'), findsNothing);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('PrinterControls should show resume/cancel when paused', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: false,
        paused: true,
        progress: 50.0,
        errorDetected: false,
        printTimeRemaining: 3600,
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
      expect(find.text('Start Print'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('PrinterControls should disable buttons when loading', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: false,
        paused: false,
        progress: 0.0,
        errorDetected: false,
        printTimeRemaining: 0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrinterControls(
              status: status,
              isLoading: true,
              onStart: () {},
              onPause: () {},
              onResume: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Assert
      final startButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start Print'),
      );
      expect(startButton.onPressed, null);
    });
  });

  group('CameraPreview Widget Tests', () {
    testWidgets('CameraPreview should show loading state', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraPreview(
              streamUrl: 'http://test.com/stream',
              onSnapshotTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Camera Preview'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CameraPreview should show camera button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraPreview(
              streamUrl: 'http://test.com/stream',
              onSnapshotTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.camera), findsOneWidget);
    });

    testWidgets('CameraPreview should call onSnapshotTap when camera button tapped', (WidgetTester tester) async {
      // Arrange
      bool snapshotTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraPreview(
              streamUrl: 'http://test.com/stream',
              onSnapshotTap: () => snapshotTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera));
      await tester.pump();

      // Assert
      expect(snapshotTapped, true);
    });
  });

  group('Integration Widget Tests', () {
    testWidgets('Complete app flow should work', (WidgetTester tester) async {
      // Arrange
      final status = PrinterStatus(
        printing: true,
        paused: false,
        progress: 35.0,
        errorDetected: false,
        printTimeRemaining: 5400,
        fileName: 'integration_test.gcode',
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.currentStatus).thenReturn(status);
      when(mockViewModel.isConnected).thenReturn(true);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<PrinterViewModel>(
          create: (_) => mockViewModel,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert - All components should be present
      expect(find.byType(StatusCard), findsOneWidget);
      expect(find.byType(CameraPreview), findsOneWidget);
      expect(find.byType(ProgressBar), findsOneWidget);
      expect(find.byType(PrinterControls), findsOneWidget);

      // Assert - Status information should be displayed
      expect(find.text('35.0%'), findsOneWidget);
      expect(find.text('integration_test.gcode'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);

      // Assert - Control buttons should be correct for printing state
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Start Print'), findsNothing);
    });
  });
}
