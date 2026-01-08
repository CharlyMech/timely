import 'package:intl/intl.dart';
import 'package:timely/models/time_registration.dart';

class DateTimeUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String getTodayFormatted() {
    return formatDate(DateTime.now());
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

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

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static String minutesToReadable(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins m';
    } else {
      return '$hours:${mins.toString().padLeft(2, '0')}';
    }
  }

  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
