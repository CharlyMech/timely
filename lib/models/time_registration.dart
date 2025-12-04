class TimeRegistration {
  final String id;
  final String employeeId;
  final DateTime startTime;
  final DateTime? endTime;
  final String date; // DD/MM/YYYY

  const TimeRegistration({
    required this.id,
    required this.employeeId,
    required this.startTime,
    this.endTime,
    required this.date,
  });

  int get totalMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

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
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'date': date,
    };
  }

  TimeRegistration copyWith({
    String? id,
    String? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    String? date,
  }) {
    return TimeRegistration(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
    );
  }
}

enum TimeRegistrationStatus { green, orange, red }
