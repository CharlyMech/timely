class TimeRegistration {
  final String id;
  final String employeeId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pauseTime;
  final DateTime? resumeTime;
  final String date; // DD/MM/YYYY

  const TimeRegistration({
    required this.id,
    required this.employeeId,
    required this.startTime,
    this.endTime,
    this.pauseTime,
    this.resumeTime,
    required this.date,
  });

  int get totalMinutes {
    final end = endTime ?? DateTime.now();
    int total = end.difference(startTime).inMinutes;

    // Subtract pause duration if pause and resume times are available
    if (pauseTime != null && resumeTime != null) {
      final pauseDuration = resumeTime!.difference(pauseTime!).inMinutes;
      total -= pauseDuration;
    } else if (pauseTime != null && resumeTime == null) {
      // Currently on pause, subtract from pause time to now
      final pauseDuration = DateTime.now().difference(pauseTime!).inMinutes;
      total -= pauseDuration;
    }

    return total;
  }

  int remainingMinutes(int targetTimeMinutes) {
    final elapsedMinutes = totalMinutes;
    final remaining = targetTimeMinutes - elapsedMinutes;

    return remaining.clamp(0, targetTimeMinutes);
  }

  bool get isPaused => pauseTime != null && resumeTime == null;

  bool get isActive => endTime == null;

  // Green: 405-435 minutes (6h45m - 7h15m)
  // Orange: 436-479 minutes (7h16m - 7h59m)
  // Red: 480+ minutes (8h+)
  TimeRegistrationStatus get status {
    final minutes = totalMinutes;
    if (minutes >= 405 && minutes <= 435) {
      return TimeRegistrationStatus.green;
    } else if (minutes >= 436 && minutes <= 479) {
      return TimeRegistrationStatus.orange;
    } else {
      return TimeRegistrationStatus.red;
    }
  }

  factory TimeRegistration.fromJson(Map<String, dynamic> json) {
    return TimeRegistration(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      pauseTime: json['pauseTime'] != null
          ? DateTime.parse(json['pauseTime'] as String)
          : null,
      resumeTime: json['resumeTime'] != null
          ? DateTime.parse(json['resumeTime'] as String)
          : null,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'pauseTime': pauseTime?.toIso8601String(),
      'resumeTime': resumeTime?.toIso8601String(),
      'date': date,
    };
  }

  TimeRegistration copyWith({
    String? id,
    String? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pauseTime,
    DateTime? resumeTime,
    String? date,
  }) {
    return TimeRegistration(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pauseTime: pauseTime ?? this.pauseTime,
      resumeTime: resumeTime ?? this.resumeTime,
      date: date ?? this.date,
    );
  }
}

enum TimeRegistrationStatus { green, orange, red }
