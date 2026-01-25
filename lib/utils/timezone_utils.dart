import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Utility class for handling Spanish timezone (Europe/Madrid).
///
/// All datetime operations in the app should use this utility to ensure
/// consistent timezone handling across the application.
class TimezoneUtils {
  static const String _spainTimezone = 'Europe/Madrid';
  static tz.Location? _spainLocation;
  static bool _initialized = false;

  /// Initializes the timezone database.
  /// Must be called before any other timezone operations.
  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _spainLocation = tz.getLocation(_spainTimezone);
    tz.setLocalLocation(_spainLocation!);
    _initialized = true;
  }

  /// Gets the Spain timezone location.
  static tz.Location get spainLocation {
    if (!_initialized || _spainLocation == null) {
      throw StateError(
        'TimezoneUtils not initialized. Call TimezoneUtils.initialize() first.',
      );
    }
    return _spainLocation!;
  }

  /// Returns the current time in Spanish timezone.
  static tz.TZDateTime now() {
    return tz.TZDateTime.now(spainLocation);
  }

  /// Converts a UTC DateTime to Spanish timezone.
  static tz.TZDateTime fromUtc(DateTime utcDateTime) {
    return tz.TZDateTime.from(utcDateTime.toUtc(), spainLocation);
  }

  /// Converts a local DateTime to Spanish timezone.
  /// Use this when you have a DateTime that was created with DateTime.now()
  /// or any other local time.
  static tz.TZDateTime fromLocal(DateTime localDateTime) {
    return tz.TZDateTime.from(localDateTime, spainLocation);
  }

  /// Creates a TZDateTime in Spanish timezone from components.
  static tz.TZDateTime create(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
  ]) {
    return tz.TZDateTime(
      spainLocation,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  /// Parses an ISO 8601 string and returns it in Spanish timezone.
  static tz.TZDateTime parse(String isoString) {
    final utcDateTime = DateTime.parse(isoString);
    return fromUtc(utcDateTime);
  }

  /// Converts a TZDateTime to a regular DateTime (preserving the time values).
  static DateTime toDateTime(tz.TZDateTime tzDateTime) {
    return DateTime(
      tzDateTime.year,
      tzDateTime.month,
      tzDateTime.day,
      tzDateTime.hour,
      tzDateTime.minute,
      tzDateTime.second,
      tzDateTime.millisecond,
    );
  }

  /// Converts any DateTime to Spanish timezone and returns as regular DateTime.
  /// This is useful for displaying times in the UI.
  static DateTime toSpainTime(DateTime dateTime) {
    final tzDateTime = fromUtc(dateTime.toUtc());
    return toDateTime(tzDateTime);
  }

  /// Converts a DateTime in Spanish timezone to UTC for storage.
  static DateTime toUtcForStorage(DateTime spainDateTime) {
    final tzDateTime = tz.TZDateTime(
      spainLocation,
      spainDateTime.year,
      spainDateTime.month,
      spainDateTime.day,
      spainDateTime.hour,
      spainDateTime.minute,
      spainDateTime.second,
      spainDateTime.millisecond,
    );
    return tzDateTime.toUtc();
  }

  /// Returns today's date at midnight in Spanish timezone.
  static DateTime todayInSpain() {
    final nowInSpain = now();
    return DateTime(nowInSpain.year, nowInSpain.month, nowInSpain.day);
  }

  /// Checks if a DateTime represents today in Spanish timezone.
  static bool isToday(DateTime dateTime) {
    final spainNow = now();
    final spainDateTime = fromUtc(dateTime.toUtc());
    return spainDateTime.year == spainNow.year &&
        spainDateTime.month == spainNow.month &&
        spainDateTime.day == spainNow.day;
  }

  /// Returns the start of day (00:00:00) in Spanish timezone.
  static DateTime startOfDay(DateTime dateTime) {
    final spainDateTime = fromUtc(dateTime.toUtc());
    return DateTime(spainDateTime.year, spainDateTime.month, spainDateTime.day);
  }

  /// Returns the end of day (23:59:59) in Spanish timezone.
  static DateTime endOfDay(DateTime dateTime) {
    final spainDateTime = fromUtc(dateTime.toUtc());
    return DateTime(
      spainDateTime.year,
      spainDateTime.month,
      spainDateTime.day,
      23,
      59,
      59,
    );
  }
}
