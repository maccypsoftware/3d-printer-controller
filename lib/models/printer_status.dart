import 'package:flutter/material.dart';

class PrinterStatus {
  final bool printing;
  final bool paused;
  final double progress;
  final bool errorDetected;
  final String? errorMessage;
  final int printTimeRemaining;
  final String? fileName;

  PrinterStatus({
    required this.printing,
    required this.paused,
    required this.progress,
    required this.errorDetected,
    this.errorMessage,
    required this.printTimeRemaining,
    this.fileName,
  });

  factory PrinterStatus.fromJson(Map<String, dynamic> json) {
    return PrinterStatus(
      printing: json['printing'] ?? false,
      paused: json['paused'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      errorDetected: json['error_detected'] ?? false,
      errorMessage: json['error_message'],
      printTimeRemaining: json['print_time_remaining'] ?? 0,
      fileName: json['file_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'printing': printing,
      'paused': paused,
      'progress': progress,
      'error_detected': errorDetected,
      'error_message': errorMessage,
      'print_time_remaining': printTimeRemaining,
      'file_name': fileName,
    };
  }

  String get statusText {
    if (errorDetected) return 'Error';
    if (paused) return 'Paused';
    if (printing) return 'Printing';
    return 'Idle';
  }

  Color get statusColor {
    if (errorDetected) return Colors.red;
    if (paused) return Colors.orange;
    if (printing) return Colors.green;
    return Colors.grey;
  }

  String get timeRemainingText {
    if (printTimeRemaining <= 0) return 'Unknown';
    final hours = printTimeRemaining ~/ 3600;
    final minutes = (printTimeRemaining % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
