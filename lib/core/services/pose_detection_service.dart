import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_heuristics.dart';

class PoseDetectionService {
  late PoseDetector _poseDetector;
  bool _isProcessing = false;
  PoseHeuristic? _currentHeuristic;
  
  // Callback to update UI with latest rep count
  final Function(int) onRepCountChanged;
  // Callback to provide skeletal data for overlay
  final Function(Pose?) onPoseDetected;

  PoseDetectionService({
    required this.onRepCountChanged,
    required this.onPoseDetected,
  }) {
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  void setExercise(String exercise) {
    switch (exercise.toUpperCase()) {
      case "SQUAT":
        _currentHeuristic = SquatHeuristic();
        break;
      case "PUSHUP":
        _currentHeuristic = PushupHeuristic();
        break;
      case "HSPU":
        _currentHeuristic = HSPUHeuristic();
        break;
      default:
        _currentHeuristic = null;
    }
    _currentHeuristic?.reset();
    onRepCountChanged(0);
  }

  Future<void> processImage(CameraImage image, int sensorOrientation) async {
    if (_isProcessing || _currentHeuristic == null) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image, sensorOrientation);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        _currentHeuristic?.analyze(pose);
        onRepCountChanged(_currentHeuristic?.repCount ?? 0);
        onPoseDetected(pose);
      } else {
        onPoseDetected(null);
      }
    } catch (e) {
      debugPrint("PoseDetection Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image, int sensorOrientation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    final inputImageMetadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );
    
    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  void dispose() {
    _poseDetector.close();
  }
}
