import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/app_theme.dart';
import '../../core/services/pose_detection_service.dart';
import '../../core/services/pose_heuristics.dart';
import '../../core/services/audio_service.dart';

class VideoRecorderWidget extends StatefulWidget {
  final Function(XFile) onRecordingComplete;
  final String exerciseType;
  final bool enableVideo;
  final bool enableAI;
  final Function(int)? onRepCountChanged;

  const VideoRecorderWidget({
    super.key, 
    required this.onRecordingComplete,
    required this.exerciseType,
    this.enableVideo = false,
    this.enableAI = false,
    this.onRepCountChanged,
  });

  @override
  State<VideoRecorderWidget> createState() => VideoRecorderWidgetState();
}

class VideoRecorderWidgetState extends State<VideoRecorderWidget> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  
  late AudioService _audioService;
  
  late PoseDetectionService _poseDetectionService;
  int _currentReps = 0;
  Pose? _currentPose;
  PoseHeuristic? _currentHeuristic;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _poseDetectionService = PoseDetectionService(
      onRepCountChanged: (count) {
        if (mounted) {
          setState(() => _currentReps = count);
          widget.onRepCountChanged?.call(count);
        }
      },
      onPoseDetected: (pose, heuristic) {
        if (mounted) {
          setState(() {
            _currentPose = pose;
            _currentHeuristic = heuristic;
            
            // Trigger audio feedback for cues
            if (widget.enableAI && heuristic != null && heuristic.currentCues.isNotEmpty) {
              _audioService.speakCue(heuristic.currentCues.first);
            }
          });
        }
      },
    );
    _poseDetectionService.setExercise(widget.exerciseType);
    if (widget.enableVideo || widget.enableAI) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(VideoRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseType != widget.exerciseType) {
      _poseDetectionService.setExercise(widget.exerciseType);
    }
    if ((widget.enableVideo || widget.enableAI) && !_isInitialized && _controller == null) {
      _initializeCamera();
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
      
      // Start AI Stream if enabled
      if (widget.enableAI) {
        _controller!.startImageStream((image) {
          _poseDetectionService.processImage(
            image,
            _controller!.description.sensorOrientation,
          );
        });
      }

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> toggleRecording() async {
    if (!widget.enableVideo || _controller == null || !_isInitialized) return;

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
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableVideo && !widget.enableAI) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "OFF-CAMERA WORKOUT",
            style: TextStyle(
              color: AppTheme.voltGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

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
        if (widget.enableAI && _currentPose != null)
          Positioned.fill(
            child: CustomPaint(
              painter: PosePainter(
                _currentPose!,
                _controller!.value.previewSize!,
                MediaQuery.of(context).size,
                heuristic: _currentHeuristic,
              ),
            ),
          ),

        // AI Form Toasts
        if (widget.enableAI && _currentHeuristic != null && _currentHeuristic!.currentCues.isNotEmpty)
          Positioned(
            top: 20,
            child: Column(
              children: _currentHeuristic!.currentCues.map((cue) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  cue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              )).toList(),
            ),
          ),

        // AI Rep Counter (Floats over the video)
        if (widget.enableAI)
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
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (_currentHeuristic != null)
                  Text(
                    "FORM: ${_currentHeuristic!.currentFormScore.toInt()}%",
                    style: TextStyle(
                      color: _currentHeuristic!.currentFormScore > 80 ? AppTheme.voltGreen : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
        
        // AI Tracking Indicator
        if (widget.enableAI)
          Positioned(
            top: 10,
            left: 20,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.voltGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "AI FORM ENGINE ACTIVE",
                  style: TextStyle(
                    color: AppTheme.voltGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
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
  final PoseHeuristic? heuristic;

  PosePainter(this.pose, this.imageSize, this.widgetSize, {this.heuristic});

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppTheme.voltGreen;

    final warningPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, {Paint? customPaint}) {
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
          customPaint ?? defaultPaint,
        );
      }
    }

    bool hasCue(String cue) => heuristic?.currentCues.contains(cue) ?? false;

    // Select color based on cues
    final armPaint = hasCue("TUCK ELBOWS") ? warningPaint : defaultPaint;
    final backPaint = (hasCue("STRAIGHTEN BACK") || hasCue("STRAIGHTEN BODY")) ? warningPaint : defaultPaint;

    // Draw main skeletal lines
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, customPaint: armPaint);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, customPaint: armPaint);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, customPaint: armPaint);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, customPaint: armPaint);
    
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, customPaint: backPaint);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, customPaint: backPaint);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, customPaint: backPaint);
    
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, customPaint: backPaint);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, customPaint: backPaint);
    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, customPaint: backPaint);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, customPaint: backPaint);

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
