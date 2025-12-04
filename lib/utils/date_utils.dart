import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Formatea una fecha al formato DD/MM/YYYY
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formatea una hora al formato HH:mm
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Obtiene la fecha actual en formato DD/MM/YYYY
  static String getTodayFormatted() {
    return formatDate(DateTime.now());
  }

  /// Verifica si dos fechas son del mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Obtiene el inicio del día (00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtiene el fin del día (23:59:59)
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Convierte minutos a formato legible "Xh Ym"
  static String minutesToReadable(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '${mins}m';
    } else if (mins == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${mins}m';
    }
  }

  /// Parsea una fecha desde string DD/MM/YYYY
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
