import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a scheduled work shift for an employee on a specific date.
///
/// A shift assigns an employee to work on a particular date with a specific
/// shift type that defines the work hours and schedule.
class Shift {
  /// Unique identifier for the shift.
  final String id;

  /// ID of the employee assigned to this shift.
  final String employeeId;

  /// Date of the shift.
  final DateTime date;

  /// Reference to the shift type defining work hours.
  final String shiftTypeId;

  /// Optional notes or comments about the shift.
  final String? notes;

  const Shift({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.shiftTypeId,
    this.notes,
  });

  /// Returns `true` if this shift is in the past.
  bool get isPast => date.isBefore(DateTime.now());

  /// Returns `true` if this shift is scheduled for today.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns `true` if this shift is in the future (excluding today).
  bool get isFuture => date.isAfter(DateTime.now()) && !isToday;

  /// Creates a [Shift] from a JSON map.
  ///
  /// Supports parsing date from either Firestore [Timestamp] or ISO 8601 string.
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

  /// Converts this [Shift] to a JSON map.
  ///
  /// Date is stored as Firestore [Timestamp].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'shiftTypeId': shiftTypeId,
      'notes': notes,
    };
  }

  /// Creates a copy of this [Shift] with the given fields replaced.
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
