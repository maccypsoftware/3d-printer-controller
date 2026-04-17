import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CameraPreview extends StatefulWidget {
  final String streamUrl;
  final VoidCallback onSnapshotTap;

  const CameraPreview({
    super.key,
    required this.streamUrl,
    required this.onSnapshotTap,
  });

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void didUpdateWidget(CameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For MJPEG streams, we'll use a simpler approach
      // In a real implementation, you might use a package like flutter_mjpeg
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
      
      await _controller!.initialize();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load camera stream: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8),
                Text(
                  'Camera Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onSnapshotTap,
                  icon: const Icon(Icons.camera),
                  tooltip: 'Take Snapshot',
                ),
              ],
            ),
          ),
          Container(
            height: 240,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black,
            ),
            child: _buildCameraContent(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              'Camera Stream',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    return const Center(
      child: Text(
        'No Camera Feed',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
