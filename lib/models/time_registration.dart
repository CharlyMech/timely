import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/timezone_utils.dart';

/// Represents a time registration record for an employee's work session.
///
/// Tracks start, end, pause, and resume times for a work shift, calculates
/// total worked minutes, and determines compliance status based on target hours.
class TimeRegistration {
  /// Unique identifier for the registration.
  final String id;

  /// ID of the employee who owns this registration.
  final String employeeId;

  /// ID of the shift this registration is associated with.
  final String shiftId;

  /// Timestamp when work started.
  final DateTime startTime;

  /// Timestamp when work ended, or null if still active.
  final DateTime? endTime;

  /// Timestamp when work was paused, or null if not paused.
  final DateTime? pauseTime;

  /// Timestamp when work resumed after pause, or null if not yet resumed.
  final DateTime? resumeTime;

  /// Date of the registration in DD/MM/YYYY format.
  final String date;

  /// Timestamp when the registration was created.
  final DateTime? createdAt;

  /// Timestamp when the registration was last updated.
  final DateTime? lastUpdatedAt;

  const TimeRegistration({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.startTime,
    this.endTime,
    this.pauseTime,
    this.resumeTime,
    required this.date,
    this.createdAt,
    this.lastUpdatedAt,
  });

  /// Calculates total worked minutes, excluding pause duration.
  ///
  /// Uses [DateTimeUtils.differenceInMinutesRounded] for consistent rounding
  /// that matches UI display. If still active, uses current time in Spanish
  /// timezone as end time. Subtracts pause duration if pause and resume times
  /// exist, or time since pause if currently paused.
  int get totalMinutes {
    final end = endTime ?? DateTimeUtils.now();

    // Calculate total minutes rounded to nearest minute for better UX consistency
    // This ensures that if UI shows 17:00 - 17:01, we count it as 1 minute
    int total = DateTimeUtils.differenceInMinutesRounded(startTime, end);

    // Subtract pause duration if pause and resume times are available
    if (pauseTime != null && resumeTime != null) {
      final pauseDuration = DateTimeUtils.differenceInMinutesRounded(
        pauseTime!,
        resumeTime!,
      );
      total -= pauseDuration;
    } else if (pauseTime != null && resumeTime == null) {
      // Currently on pause, subtract from pause time to now (using Spanish timezone)
      final pauseDuration = DateTimeUtils.differenceInMinutesRounded(
        pauseTime!,
        DateTimeUtils.now(),
      );
      total -= pauseDuration;
    }

    return total;
  }

  /// Calculates remaining minutes to reach the target time.
  ///
  /// Returns a value clamped between 0 and [targetTimeMinutes].
  /// If [totalMinutes] exceeds the target, returns 0.
  int remainingMinutes(int targetTimeMinutes) {
    final elapsedMinutes = totalMinutes;
    final remaining = targetTimeMinutes - elapsedMinutes;

    return remaining.clamp(0, targetTimeMinutes);
  }

  /// Returns `true` if the work session is currently paused.
  bool get isPaused => pauseTime != null && resumeTime == null;

  /// Returns `true` if the work session is still active (not ended).
  bool get isActive => endTime == null;

  /// Calculates the log status based on the configured time target and thresholds
  ///
  /// - Green: Within the acceptable range (target - warningThreshold <= minutes <= target + warningThreshold)
  /// - Orange: Outside the acceptable range but within the red threshold
  /// - Red: Outside the red threshold (more than one redThreshold minute difference from the target)
  TimeRegistrationStatus getStatus({
    required int targetMinutes,
    int warningThreshold = 15,
    int redThreshold = 60,
  }) {
    final minutes = totalMinutes;
    final difference = (minutes - targetMinutes).abs();

    if (difference <= warningThreshold) {
      return TimeRegistrationStatus.green;
    } else if (difference <= redThreshold) {
      return TimeRegistrationStatus.orange;
    } else {
      return TimeRegistrationStatus.red;
    }
  }

  /// Convenience getter that uses default values ​​(8h target, 15min warning, 60min red)
  // For compatibility with existing code
  @Deprecated('Usa getStatus() con los parámetros de AppConfig en su lugar')
  TimeRegistrationStatus get status => getStatus(targetMinutes: 480);

  /// Creates a [TimeRegistration] from a JSON map.
  ///
  /// Handles parsing timestamps from both Firestore [Timestamp] and
  /// ISO 8601 string formats. Accepts camelCase or snake_case keys
  /// (e.g. startTime or start_time) for API compatibility.
  factory TimeRegistration.fromJson(Map<String, dynamic> json) {
    return TimeRegistration(
      id: _s(json, 'id') as String,
      employeeId: _s(json, 'employeeId', 'employee_id') as String,
      shiftId: _s(json, 'shiftId', 'shift_id') as String,
      startTime: _parseDateTime(_s(json, 'startTime', 'start_time')),
      endTime: _s(json, 'endTime', 'end_time') != null
          ? _parseDateTime(_s(json, 'endTime', 'end_time'))
          : null,
      pauseTime: _s(json, 'pauseTime', 'pause_time') != null
          ? _parseDateTime(_s(json, 'pauseTime', 'pause_time'))
          : null,
      resumeTime: _s(json, 'resumeTime', 'resume_time') != null
          ? _parseDateTime(_s(json, 'resumeTime', 'resume_time'))
          : null,
      date: _s(json, 'date') as String,
      createdAt: _s(json, 'createdAt', 'created_at') != null
          ? _parseDateTime(_s(json, 'createdAt', 'created_at'))
          : null,
      lastUpdatedAt: _s(json, 'lastUpdatedAt', 'last_updated_at') != null
          ? _parseDateTime(_s(json, 'lastUpdatedAt', 'last_updated_at'))
          : null,
    );
  }

  /// Gets value from json with optional snake_case fallback key.
  static dynamic _s(Map<String, dynamic> json, String key, [String? keySnake]) {
    if (json[key] != null) return json[key];
    if (keySnake != null && json[keySnake] != null) return json[keySnake];
    return null;
  }

  /// Parses a DateTime from Firestore Timestamp or ISO 8601 string.
  ///
  /// Supports multiple formats:
  /// - Firestore [Timestamp] object
  /// - Serialized Timestamp as Map with `_seconds` and `_nanoseconds`
  /// - ISO 8601 date string
  /// - Existing [DateTime] object
  ///
  /// All parsed dates are converted to Spanish timezone (Europe/Madrid).
  /// Throws [ArgumentError] if value is null or in an unsupported format.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      throw ArgumentError('DateTime value cannot be null');
    }

    DateTime utcDateTime;

    if (value is Map && value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int;
      final nanoseconds = (value['_nanoseconds'] as int?) ?? 0;
      utcDateTime = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
        isUtc: true,
      );
    } else if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        final dynamic timestamp = value;
        utcDateTime = (timestamp.toDate() as DateTime).toUtc();
      } catch (e) {
        // Parse date to string if fails
        utcDateTime = DateTime.parse(value.toString()).toUtc();
      }
    } else if (value is String) {
      utcDateTime = DateTime.parse(value).toUtc();
    } else if (value is DateTime) {
      utcDateTime = value.toUtc();
    } else {
      throw ArgumentError('Unsupported DateTime format: ${value.runtimeType}');
    }

    // Convert to Spanish timezone
    return TimezoneUtils.toSpainTime(utcDateTime);
  }

  /// Converts this [TimeRegistration] to a JSON map.
  ///
  /// DateTime fields are stored as Firestore [Timestamp] objects in UTC.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'shiftId': shiftId,
      'startTime': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(startTime)),
      'endTime': endTime != null
          ? Timestamp.fromDate(TimezoneUtils.toUtcForStorage(endTime!))
          : null,
      'pauseTime': pauseTime != null
          ? Timestamp.fromDate(TimezoneUtils.toUtcForStorage(pauseTime!))
          : null,
      'resumeTime': resumeTime != null
          ? Timestamp.fromDate(TimezoneUtils.toUtcForStorage(resumeTime!))
          : null,
      'date': date,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(TimezoneUtils.toUtcForStorage(createdAt!))
          : null,
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(TimezoneUtils.toUtcForStorage(lastUpdatedAt!))
          : null,
    };
  }

  /// Creates a copy of this [TimeRegistration] with the given fields replaced.
  TimeRegistration copyWith({
    String? id,
    String? employeeId,
    String? shiftId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pauseTime,
    DateTime? resumeTime,
    String? date,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return TimeRegistration(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      shiftId: shiftId ?? this.shiftId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pauseTime: pauseTime ?? this.pauseTime,
      resumeTime: resumeTime ?? this.resumeTime,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

/// Compliance status for a time registration based on target time comparison.
enum TimeRegistrationStatus {
  /// Compliant - within acceptable range of target time.
  green,

  /// Warning - moderately deviates from target time.
  orange,

  /// Critical - significantly deviates from target time.
  red,
}
