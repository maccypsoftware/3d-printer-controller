import 'package:flutter/material.dart';
import '../models/printer_status.dart';

class PrinterControls extends StatelessWidget {
  final PrinterStatus? status;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const PrinterControls({
    super.key,
    required this.status,
    required this.isLoading,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                Text(
                  'Printer Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildControlButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    if (status == null) {
      return const Center(
        child: Text('No printer status available'),
      );
    }

    final isPrinting = status!.printing;
    final isPaused = status!.paused;

    if (!isPrinting && !isPaused) {
      // Not printing - show start button
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Print'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    if (isPaused) {
      // Paused - show resume and cancel buttons
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onResume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onCancel,
              icon: const Icon(Icons.stop),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    if (isPrinting) {
      // Printing - show pause button
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPause,
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onCancel,
              icon: const Icon(Icons.stop),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
