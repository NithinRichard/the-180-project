import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class VideoRecorderWidget extends StatefulWidget {
  final Function(XFile) onRecordingComplete;

  const VideoRecorderWidget({super.key, required this.onRecordingComplete});

  @override
  State<VideoRecorderWidget> createState() => VideoRecorderWidgetState();
}

class VideoRecorderWidgetState extends State<VideoRecorderWidget> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false, // HSPU training often doesn't need audio
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> toggleRecording() async {
    if (_controller == null || !_isInitialized) return;

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      widget.onRecordingComplete(file);
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.voltGreen),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_controller!),
        if (_isRecording)
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.red,
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 12),
                  SizedBox(width: 8),
                  Text(
                    "RECORDING",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
