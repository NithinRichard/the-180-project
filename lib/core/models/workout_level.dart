enum LevelStatus { locked, current, completed }

class WorkoutLevel {
  final int id;
  final String title;
  final String description;
  final String exercise; // The exercise key used in logs
  final int targetReps;
  final int targetSets;
  final int? targetDuration; // In seconds, for static holds
  final LevelStatus status;
  final bool isSafetyRequired;

  WorkoutLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.exercise,
    this.targetReps = 10,
    this.targetSets = 3,
    this.targetDuration,
    this.status = LevelStatus.locked,
    this.isSafetyRequired = false,
  });

  WorkoutLevel copyWith({
    LevelStatus? status,
    bool? isSafetyRequired,
  }) {
    return WorkoutLevel(
      id: id,
      title: title,
      description: description,
      exercise: exercise,
      targetReps: targetReps,
      targetSets: targetSets,
      targetDuration: targetDuration,
      status: status ?? this.status,
      isSafetyRequired: isSafetyRequired ?? this.isSafetyRequired,
    );
  }
}
