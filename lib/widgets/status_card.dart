import 'package:flutter/material.dart';
import '../models/printer_status.dart';

class StatusCard extends StatelessWidget {
  final PrinterStatus? status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Printer Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status != null) ...[
              _buildStatusRow(context, 'Status', status!.statusText, status!.statusColor),
              _buildStatusRow(context, 'Progress', '${status!.progress.toStringAsFixed(1)}%', null),
              if (status!.fileName != null)
                _buildStatusRow(context, 'File', status!.fileName!, null),
              _buildStatusRow(context, 'Time Remaining', status!.timeRemainingText, null),
            ] else
              const Text('No status available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
