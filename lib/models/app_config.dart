class AppConfig {
  final int defaultTargetTimeMinutes; // Default target time when no shift type specified
  final int warningThresholdMinutes;
  final int redThresholdMinutes;
  final List<int> workingDays; // Working days (1=Monday, 7=Sunday)

  const AppConfig({
    required this.defaultTargetTimeMinutes,
    this.warningThresholdMinutes = 15,
    this.redThresholdMinutes = 60,
    required this.workingDays,
  });

  // Default configuration
  factory AppConfig.defaultConfig() {
    return const AppConfig(
      defaultTargetTimeMinutes: 480, // 8 hours
      workingDays: [1, 2, 3, 4, 5], // Monday to Friday
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      defaultTargetTimeMinutes: json['defaultTargetTimeMinutes'] as int? ?? 480,
      warningThresholdMinutes: json['warningThresholdMinutes'] as int? ?? 15,
      redThresholdMinutes: json['redThresholdMinutes'] as int? ?? 60,
      workingDays:
          (json['workingDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultTargetTimeMinutes': defaultTargetTimeMinutes,
      'warningThresholdMinutes': warningThresholdMinutes,
      'redThresholdMinutes': redThresholdMinutes,
      'workingDays': workingDays,
    };
  }

  AppConfig copyWith({
    int? defaultTargetTimeMinutes,
    int? warningThresholdMinutes,
    int? redThresholdMinutes,
    List<int>? workingDays,
  }) {
    return AppConfig(
      defaultTargetTimeMinutes: defaultTargetTimeMinutes ?? this.defaultTargetTimeMinutes,
      warningThresholdMinutes: warningThresholdMinutes ?? this.warningThresholdMinutes,
      redThresholdMinutes: redThresholdMinutes ?? this.redThresholdMinutes,
      workingDays: workingDays ?? this.workingDays,
    );
  }

  bool isWorkingDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }
}
