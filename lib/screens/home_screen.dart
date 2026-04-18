import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../widgets/camera_preview.dart';
import '../widgets/printer_controls.dart';
import '../widgets/status_card.dart';
import '../widgets/progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prusa Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<PrinterViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(
                  viewModel.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: viewModel.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: viewModel.loadStatus,
              );
            },
          ),
        ],
      ),
      body: Consumer<PrinterViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.currentStatus == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null && viewModel.currentStatus == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connection Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.loadStatus,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadStatus,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  StatusCard(status: viewModel.currentStatus),
                  
                  const SizedBox(height: 16),
                  
                  // Camera Preview
                  CameraPreview(
                    streamUrl: viewModel.getCameraStreamUrl(),
                    onSnapshotTap: () async {
                      try {
                        await viewModel.getCameraSnapshot();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Snapshot captured')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to capture snapshot: $e')),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  if (viewModel.currentStatus != null)
                    ProgressBar(
                      progress: viewModel.currentStatus!.progress,
                      timeRemaining: viewModel.currentStatus!.timeRemainingText,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Printer Controls
                  PrinterControls(
                    status: viewModel.currentStatus,
                    isLoading: viewModel.isLoading,
                    onStart: viewModel.startPrint,
                    onPause: viewModel.pausePrint,
                    onResume: viewModel.resumePrint,
                    onCancel: viewModel.cancelPrint,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Error Display
                  if (viewModel.currentStatus?.errorDetected == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Print Error Detected',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (viewModel.currentStatus?.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                viewModel.currentStatus!.errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
