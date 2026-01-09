import 'package:cloud_firestore/cloud_firestore.dart';

class Shift {
  final String id;
  final String employeeId;
  final DateTime date;
  final String shiftTypeId;
  final String? notes;

  const Shift({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.shiftTypeId,
    this.notes,
  });

  bool get isPast => date.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isFuture => date.isAfter(DateTime.now()) && !isToday;

  factory Shift.fromJson(Map<String, dynamic> json) {
    DateTime date;

    if (json['date'] is Timestamp) {
      date = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      date = DateTime.parse(json['date'] as String);
    } else {
      throw ArgumentError(
        'Invalid date format for Shift: expected Timestamp or String',
      );
    }

    return Shift(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: date,
      shiftTypeId: json['shiftTypeId'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'shiftTypeId': shiftTypeId,
      'notes': notes,
    };
  }

  Shift copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    String? shiftTypeId,
    String? notes,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      shiftTypeId: shiftTypeId ?? this.shiftTypeId,
      notes: notes ?? this.notes,
    );
  }
}
