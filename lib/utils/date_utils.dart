import 'package:intl/intl.dart';
import 'package:timely/models/time_registration.dart';

/// Utility class for date and time formatting and calculations.
///
/// Provides methods for formatting dates/times, calculating differences,
/// and working with time registrations.
class DateTimeUtils {
  /// Formats a date as DD/MM/YYYY.
  ///
  /// Example: `15/01/2025`
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formats a time as HH:mm in 24-hour format.
  ///
  /// Example: `14:30`
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Returns today's date formatted as DD/MM/YYYY.
  static String getTodayFormatted() {
    return formatDate(DateTime.now());
  }

  /// Checks if two dates represent the same calendar day.
  ///
  /// Returns `false` if either date is null.
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Calculates remaining minutes to reach target time for a registration.
  ///
  /// Returns:
  /// - `null` if registration doesn't exist (not started)
  /// - `0` if registration is completed
  /// - Remaining minutes if still active
  static int? getRemainingMinutes(
    TimeRegistration? registration,
    int targetTimeMinutes,
  ) {
    if (registration == null) {
      return null; // Not Started
    }

    if (!registration.isActive) {
      return 0; // Finished
    }

    return registration.remainingMinutes(targetTimeMinutes); // Remaining minutes
  }

  /// Returns a DateTime representing the start of the given day (00:00:00).
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns a DateTime representing the end of the given day (23:59:59).
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Converts minutes to a human-readable format.
  ///
  /// Returns:
  /// - `"X m"` if less than 60 minutes
  /// - `"H:MM"` for hours and minutes (e.g., "8:30")
  static String minutesToReadable(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins m';
    } else {
      return '$hours:${mins.toString().padLeft(2, '0')}';
    }
  }

  /// Parses a date string in DD/MM/YYYY format to a DateTime.
  ///
  /// Returns `null` if parsing fails.
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Calcula la diferencia en minutos entre dos fechas con redondeo inteligente
  /// que considera si los minutos mostrados en la UI son diferentes.
  ///
  /// Lógica:
  /// 1. Si los minutos mostrados (HH:MM) son diferentes → cuenta al menos 1 minuto
  /// 2. Si los minutos mostrados son iguales y diferencia < 30s → 0 minutos
  /// 3. Si los minutos mostrados son iguales y diferencia >= 30s → redondea
  ///
  /// Ejemplos:
  /// - 17:30:45 → 17:31:10 = UI muestra 17:30→17:31 → 1 minuto ✓
  /// - 17:30:00 → 17:30:25 = UI muestra 17:30→17:30 → 0 minutos ✓
  /// - 17:30:00 → 17:30:45 = UI muestra 17:30→17:30 → 1 minuto (45s redondea)
  static int differenceInMinutesRounded(DateTime start, DateTime end) {
    final seconds = end.difference(start).inSeconds;
    final absSeconds = seconds.abs();

    // Extraer los minutos que se muestran en la UI (sin segundos)
    final startMinute = start.hour * 60 + start.minute;
    final endMinute = end.hour * 60 + end.minute;
    final displayedMinutesDiff = (endMinute - startMinute).abs();

    // Si los minutos mostrados en la UI son diferentes, contar al menos esa diferencia
    if (displayedMinutesDiff > 0) {
      // La UI muestra minutos diferentes, así que retornar al menos esa diferencia
      return seconds >= 0 ? displayedMinutesDiff : -displayedMinutesDiff;
    }

    // Los minutos mostrados son iguales (mismo HH:MM en la UI)
    // Aplicar umbral de 30 segundos para evitar mostrar "1m" al inicio
    if (absSeconds < 30) {
      return 0;
    }

    // Si hay >= 30 segundos de diferencia dentro del mismo minuto, redondear
    if (seconds >= 0) {
      return (seconds / 60).round();
    } else {
      return -(absSeconds / 60).round();
    }
  }
}
