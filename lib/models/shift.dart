class Shift {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String shiftTypeId;

  const Shift({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftTypeId,
  });

  Duration get duration => endTime.difference(startTime);

  int get durationInMinutes => duration.inMinutes;

  String get durationFormatted {
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  bool get isPast => date.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isFuture => date.isAfter(DateTime.now()) && !isToday;

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      shiftTypeId: json['shiftTypeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'shiftTypeId': shiftTypeId,
    };
  }

  Shift copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? shiftTypeId,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shiftTypeId: shiftTypeId ?? this.shiftTypeId,
    );
  }
}
