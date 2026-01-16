/// Application-wide configuration for time tracking and compliance thresholds.
///
/// Contains settings that control how the application calculates and displays
/// time registration compliance, including target work hours, warning thresholds,
/// and working day schedules.
class AppConfig {
  /// Default target work time in minutes when no specific shift type is assigned.
  ///
  /// Typically 480 minutes (8 hours) for a standard workday.
  final int defaultTargetTimeMinutes;

  /// Warning threshold in minutes for time compliance.
  ///
  /// When actual time differs from target by less than this value,
  /// the registration is considered compliant (green status).
  final int warningThresholdMinutes;

  /// Red threshold in minutes for time compliance.
  ///
  /// When actual time differs from target by more than this value,
  /// the registration is marked as critically non-compliant (red status).
  final int redThresholdMinutes;

  /// List of working days as integers (1=Monday, 7=Sunday).
  ///
  /// Days not in this list are considered non-working days and
  /// will be disabled in calendars.
  final List<int> workingDays;

  const AppConfig({
    required this.defaultTargetTimeMinutes,
    this.warningThresholdMinutes = 15,
    this.redThresholdMinutes = 60,
    required this.workingDays,
  });

  /// Creates an [AppConfig] with default values.
  ///
  /// Default configuration:
  /// - Target time: 480 minutes (8 hours)
  /// - Working days: Monday to Friday (1-5)
  /// - Warning threshold: 15 minutes
  /// - Red threshold: 60 minutes
  factory AppConfig.defaultConfig() {
    return const AppConfig(
      defaultTargetTimeMinutes: 480, // 8 hours
      workingDays: [1, 2, 3, 4, 5], // Monday to Friday
    );
  }

  /// Creates an [AppConfig] from a JSON map.
  ///
  /// Provides default fallback values for any missing fields.
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

  /// Converts this [AppConfig] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'defaultTargetTimeMinutes': defaultTargetTimeMinutes,
      'warningThresholdMinutes': warningThresholdMinutes,
      'redThresholdMinutes': redThresholdMinutes,
      'workingDays': workingDays,
    };
  }

  /// Creates a copy of this [AppConfig] with the given fields replaced.
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

  /// Checks if a given date falls on a working day.
  ///
  /// Returns `true` if the date's weekday (1-7) is in the [workingDays] list.
  bool isWorkingDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }
}
