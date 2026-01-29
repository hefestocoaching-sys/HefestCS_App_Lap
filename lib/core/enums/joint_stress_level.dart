enum JointStressLevel { low, moderate, high }

extension JointStressLevelX on JointStressLevel {
  String get label => switch (this) {
        JointStressLevel.low => 'Bajo',
        JointStressLevel.moderate => 'Medio',
        JointStressLevel.high => 'Alto',
      };
}
