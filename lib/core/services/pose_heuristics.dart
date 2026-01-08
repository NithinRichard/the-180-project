import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum MovementState { neutral, down, up }

abstract class PoseHeuristic {
  final String exerciseName;
  MovementState state = MovementState.neutral;
  int repCount = 0;

  PoseHeuristic(this.exerciseName);

  void analyze(Pose pose);
  bool isPositionCorrect(Pose pose);
  void reset() {
    state = MovementState.neutral;
    repCount = 0;
  }
}

class PushupHeuristic extends PoseHeuristic {
  PushupHeuristic() : super("PUSHUP");

  @override
  void analyze(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (nose == null || leftWrist == null || rightWrist == null) return;

    // Average wrist height
    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final noseY = nose.y;

    // Proximity to floor (wrists are on floor, nose moves towards them)
    // In ML Kit coordinates, Y increases downwards.
    final noseToWristDist = avgWristY - noseY;

    if (state == MovementState.neutral && noseToWristDist < 100) {
      state = MovementState.down;
    } else if (state == MovementState.down && noseToWristDist > 250) {
      state = MovementState.neutral;
      repCount++;
    }
  }

  @override
  bool isPositionCorrect(Pose pose) => true; // Simple version for now
}

class SquatHeuristic extends PoseHeuristic {
  SquatHeuristic() : super("SQUAT");

  @override
  void analyze(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftHip == null || leftKnee == null) return;

    final hipToKneeDist = leftKnee.y - leftHip.y;

    if (state == MovementState.neutral && hipToKneeDist < 50) {
      state = MovementState.down;
    } else if (state == MovementState.down && hipToKneeDist > 150) {
      state = MovementState.neutral;
      repCount++;
    }
  }

  @override
  bool isPositionCorrect(Pose pose) => true;
}

class HSPUHeuristic extends PoseHeuristic {
  HSPUHeuristic() : super("HSPU");

  @override
  void analyze(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (nose == null || leftWrist == null || rightWrist == null) return;

    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final noseY = nose.y;

    // In HSPU, you are inverted. Nose is HIGHER than wrists in pixels (smaller Y).
    // Bottom position: Nose is CLOSE to the floor (Nose Y increases)
    // Top position: Arms locked (Nose Y decreases)
    final dist = noseY - avgWristY;

    if (state == MovementState.neutral && dist < 100) {
      state = MovementState.down; // Nose is close to floor (inverted)
    } else if (state == MovementState.down && dist > 250) {
      state = MovementState.neutral; // Arms pushed to lock
      repCount++;
    }
  }

  @override
  bool isPositionCorrect(Pose pose) {
    // Basic inversion check: Shoulders should be below hips in screen space (but inverted)
    return true; 
  }
}
