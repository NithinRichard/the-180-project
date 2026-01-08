import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/app_theme.dart';
import '../../core/services/pose_detection_service.dart';

class VideoRecorderWidget extends StatefulWidget {
  final Function(XFile) onRecordingComplete;
  final String exerciseType;

  const VideoRecorderWidget({
    super.key, 
    required this.onRecordingComplete,
    required this.exerciseType,
  });

  @override
  State<VideoRecorderWidget> createState() => VideoRecorderWidgetState();
}

class VideoRecorderWidgetState extends State<VideoRecorderWidget> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  
  late PoseDetectionService _poseDetectionService;
  int _currentReps = 0;
  Pose? _currentPose;

  @override
  void initState() {
    super.initState();
    _poseDetectionService = PoseDetectionService(
      onRepCountChanged: (count) {
        if (mounted) setState(() => _currentReps = count);
      },
      onPoseDetected: (pose) {
        if (mounted) setState(() => _currentPose = pose);
      },
    );
    _poseDetectionService.setExercise(widget.exerciseType);
    _initializeCamera();
  }

  @override
  void didUpdateWidget(VideoRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseType != widget.exerciseType) {
      _poseDetectionService.setExercise(widget.exerciseType);
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Critical for ML Kit conversion
    );

    try {
      await _controller!.initialize();
      
      // Start AI Stream
      _controller!.startImageStream((image) {
        _poseDetectionService.processImage(
          image,
          _controller!.description.sensorOrientation,
        );
      });

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
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseDetectionService.dispose();
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
        // Live Camera Feed
        CameraPreview(_controller!),
        
        // AI Skeletal Overlay
        if (_currentPose != null)
          Positioned.fill(
            child: CustomPaint(
              painter: PosePainter(
                _currentPose!,
                _controller!.value.previewSize!,
                MediaQuery.of(context).size,
              ),
            ),
          ),

        // AI Rep Counter (Floats over the video)
        Positioned(
          top: 40,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "AI REP COUNT",
                style: TextStyle(
                  color: AppTheme.voltGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _currentReps.toString(),
                style: const TextStyle(
                  color: AppTheme.voltGreen,
                  fontSize: 64,
                  fontWeight: FontWeight.black,
                  height: 1,
                ),
              ),
            ],
          ),
        ),

        // Recording Status
        if (_isRecording)
          Positioned(
            bottom: 20,
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

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size widgetSize;

  PosePainter(this.pose, this.imageSize, this.widgetSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppTheme.voltGreen;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final l1 = pose.landmarks[type1];
      final l2 = pose.landmarks[type2];
      if (l1 != null && l2 != null) {
        canvas.drawLine(
          Offset(
            l1.x * widgetSize.width / imageSize.height,
            l1.y * widgetSize.height / imageSize.width,
          ),
          Offset(
            l2.x * widgetSize.width / imageSize.height,
            l2.y * widgetSize.height / imageSize.width,
          ),
          paint,
        );
      }
    }

    // Draw main skeletal lines
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Draw dots for landmarks
    for (final landmark in pose.landmarks.values) {
      canvas.drawCircle(
        Offset(
          landmark.x * widgetSize.width / imageSize.height,
          landmark.y * widgetSize.height / imageSize.width,
        ),
        2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}
