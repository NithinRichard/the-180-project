import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum MovementState { neutral, down, up }

abstract class PoseHeuristic {
  final String exerciseName;
  MovementState state = MovementState.neutral;
  int repCount = 0;
  
  // Real-time feedback
  List<String> currentCues = [];
  double currentFormScore = 100.0;
  
  // Buffering for stable feedback
  final Map<String, int> _cueBuffer = {};
  static const int _cueThreshold = 8; // Frames required to trigger a cue

  PoseHeuristic(this.exerciseName);

  void analyze(Pose pose);
  bool isPositionCorrect(Pose pose);
  
  void reset() {
    state = MovementState.neutral;
    repCount = 0;
    currentCues.clear();
    currentFormScore = 100.0;
    _cueBuffer.clear();
  }

  void addCue(String cue) {
    _cueBuffer[cue] = (_cueBuffer[cue] ?? 0) + 1;
    if (_cueBuffer[cue]! >= _cueThreshold) {
      if (!currentCues.contains(cue)) {
        currentCues.add(cue);
      }
    }
  }

  void clearCues() {
    _cueBuffer.clear();
    currentCues.clear();
  }

  double calculateAngle(PoseLandmark first, PoseLandmark second, PoseLandmark third) {
    double radians = math.atan2(third.y - second.y, third.x - second.x) -
                     math.atan2(first.y - second.y, first.x - second.x);
    double angle = (radians * 180 / math.pi).abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }
}

class PushupHeuristic extends PoseHeuristic {
  PushupHeuristic() : super("PUSHUP");

  @override
  void analyze(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (nose == null || leftWrist == null || rightWrist == null || 
        leftShoulder == null || leftElbow == null || leftHip == null) return;

    // FORM CHECK: Elbow Flare
    double elbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    // This isn't exactly the flare angle relative to torso, let's refine:
    double torsoElbowAngle = calculateAngle(leftHip, leftShoulder, leftElbow);
    if (torsoElbowAngle > 70) {
      addCue("TUCK ELBOWS");
    }

    // FORM CHECK: Hip Arch
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    if (leftKnee != null) {
      double hipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
      if (hipAngle < 160) {
        addCue("STRAIGHTEN BACK");
      }
    }

    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final noseY = nose.y;
    final noseToWristDist = avgWristY - noseY;

    if (state == MovementState.neutral && noseToWristDist < 120) {
      state = MovementState.down;
    } else if (state == MovementState.down && noseToWristDist > 280) {
      state = MovementState.neutral;
      repCount++;
      _calculateRepScore();
      clearCues();
    }
  }

  void _calculateRepScore() {
    // Basic logic: fewer cues = higher score
    currentFormScore = math.max(0, 100 - (currentCues.length * 20));
  }

  @override
  bool isPositionCorrect(Pose pose) => true;
}

class SquatHeuristic extends PoseHeuristic {
  SquatHeuristic() : super("SQUAT");

  @override
  void analyze(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (leftHip == null || leftKnee == null || leftAnkle == null || leftShoulder == null) return;

    // FORM CHECK: Depth
    final hipToKneeDistY = leftKnee.y - leftHip.y;
    
    // FORM CHECK: Torso Angle
    double torsoAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    if (torsoAngle < 80) {
      addCue("CHEST UP");
    }

    if (state == MovementState.neutral && hipToKneeDistY < 40) {
      state = MovementState.down;
    } else if (state == MovementState.down && hipToKneeDistY > 160) {
      state = MovementState.neutral;
      repCount++;
      
      // Check depth at peak
      if (hipToKneeDistY < 10) {
        addCue("GO DEEPER");
      }
      
      currentFormScore = currentCues.contains("GO DEEPER") ? 60 : 100;
      clearCues();
    }
  }

  @override
  bool isPositionCorrect(Pose pose) => true;
}

class HSPUHeuristic extends PoseHeuristic {
  HSPUHeuristic({String name = "HSPU"}) : super(name);

  @override
  void analyze(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (nose == null || leftWrist == null || rightWrist == null || 
        leftShoulder == null || leftElbow == null || leftHip == null) return;

    // FORM CHECK: Elbow Flare
    double flareAngle = calculateAngle(leftHip, leftShoulder, leftElbow);
    if (flareAngle > 70) {
      addCue("TUCK ELBOWS");
    }

    // FORM CHECK: Tripod Path
    final avgWristX = (leftWrist.x + rightWrist.x) / 2;
    final noseX = nose.x;
    if ((noseX - avgWristX).abs() < 50) {
      addCue("HEAD FORWARD (TRIPOD)");
    }

    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final noseY = nose.y;
    final dist = noseY - avgWristY;

    if (state == MovementState.neutral && dist < 120) {
      state = MovementState.down;
    } else if (state == MovementState.down && dist > 280) {
      state = MovementState.neutral;
      repCount++;
      currentFormScore = math.max(0, 100 - (currentCues.length * 25));
      clearCues();
    }
  }

  @override
  bool isPositionCorrect(Pose pose) => true;
}

class PikePushupHeuristic extends HSPUHeuristic {
  PikePushupHeuristic() : super(name: "PIKE_PUSHUP");
}

class ElevatedPikeHeuristic extends HSPUHeuristic {
  ElevatedPikeHeuristic() : super(name: "ELEVATED_PIKE");
}

class WallHoldHeuristic extends PoseHeuristic {
  WallHoldHeuristic() : super("WALL_HOLD");

  @override
  void analyze(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder == null || leftHip == null || leftAnkle == null) return;

    // FORM CHECK: Straight Body
    double bodyAngle = calculateAngle(leftShoulder, leftHip, leftAnkle);
    if (bodyAngle < 165) {
      addCue("STRAIGHTEN BODY");
    } else {
      clearCues();
    }
  }

  @override
  bool isPositionCorrect(Pose pose) => true;
}
