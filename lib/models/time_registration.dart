import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/utils/date_utils.dart';

class TimeRegistration {
  final String id;
  final String employeeId;
  final String shiftId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pauseTime;
  final DateTime? resumeTime;
  final String date; // DD/MM/YYYY

  const TimeRegistration({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.startTime,
    this.endTime,
    this.pauseTime,
    this.resumeTime,
    required this.date,
  });

  int get totalMinutes {
    final end = endTime ?? DateTime.now();

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
      // Currently on pause, subtract from pause time to now
      final pauseDuration = DateTimeUtils.differenceInMinutesRounded(
        pauseTime!,
        DateTime.now(),
      );
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

  /// Calcula el estado del registro basado en el objetivo de tiempo y umbrales configurados
  ///
  /// - Green: Dentro del rango aceptable (target - warningThreshold <= minutes <= target + warningThreshold)
  /// - Orange: Fuera del rango aceptable pero dentro del umbral rojo
  /// - Red: Fuera del umbral rojo (más de redThreshold minutos de diferencia con el target)
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

  /// Getter de conveniencia que usa valores por defecto (8h target, 15min warning, 60min red)
  /// Para compatibilidad con código existente
  @Deprecated('Usa getStatus() con los parámetros de AppConfig en su lugar')
  TimeRegistrationStatus get status => getStatus(targetMinutes: 480);

  factory TimeRegistration.fromJson(Map<String, dynamic> json) {
    return TimeRegistration(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      shiftId: json['shiftId'] as String,
      startTime: _parseDateTime(json['startTime']),
      endTime: json['endTime'] != null
          ? _parseDateTime(json['endTime'])
          : null,
      pauseTime: json['pauseTime'] != null
          ? _parseDateTime(json['pauseTime'])
          : null,
      resumeTime: json['resumeTime'] != null
          ? _parseDateTime(json['resumeTime'])
          : null,
      date: json['date'] as String,
    );
  }

  /// Helper para parsear DateTime desde Firestore Timestamp o String ISO 8601
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      throw ArgumentError('DateTime value cannot be null');
    }

    // Si es un Timestamp de Firestore (tiene el método toDate)
    if (value is Map && value.containsKey('_seconds')) {
      // Firestore Timestamp serializado como Map
      final seconds = value['_seconds'] as int;
      final nanoseconds = (value['_nanoseconds'] as int?) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
        isUtc: true,
      );
    }

    // Si tiene el método toDate (Timestamp de Firestore)
    if (value.runtimeType.toString().contains('Timestamp')) {
      // Intentar llamar al método toDate() dinámicamente
      try {
        final dynamic timestamp = value;
        return timestamp.toDate() as DateTime;
      } catch (e) {
        // Si falla, intentar parsear como string
        return DateTime.parse(value.toString());
      }
    }

    // Si es un String (formato ISO 8601)
    if (value is String) {
      return DateTime.parse(value);
    }

    // Si ya es un DateTime
    if (value is DateTime) {
      return value;
    }

    throw ArgumentError('Unsupported DateTime format: ${value.runtimeType}');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'shiftId': shiftId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'pauseTime': pauseTime != null ? Timestamp.fromDate(pauseTime!) : null,
      'resumeTime': resumeTime != null ? Timestamp.fromDate(resumeTime!) : null,
      'date': date,
    };
  }

  TimeRegistration copyWith({
    String? id,
    String? employeeId,
    String? shiftId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pauseTime,
    DateTime? resumeTime,
    String? date,
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
    );
  }
}

enum TimeRegistrationStatus { green, orange, red }
