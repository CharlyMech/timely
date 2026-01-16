import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:uuid/uuid.dart';

/// Firebase implementation of [TimeRegistrationService].
///
/// Manages employee time tracking using Firestore's 'time_registrations'
/// collection. Provides workday lifecycle management (start, pause, resume, end)
/// and optimized queries for monthly data and counts.
class FirebaseTimeRegistrationService implements TimeRegistrationService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// Name of the Firestore collection storing time registration data.
  final String _collection = 'time_registrations';

  /// UUID generator for creating unique registration IDs.
  final _uuid = const Uuid();

  /// Creates a new Firebase time registration service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseTimeRegistrationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    try {
      // Query by formatted date string (dd/MM/yyyy) for today
      final today = DateTimeUtils.getTodayFormatted();

      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return TimeRegistration.fromJson(data);
    } catch (e) {
      throw Exception('Error al cargar registro horario desde Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId) async {
    try {
      final now = DateTime.now();
      final today = DateTimeUtils.getTodayFormatted();

      // Prevent duplicate registrations for the same day
      final existing = await getTodayRegistration(employeeId);
      if (existing != null) {
        throw Exception('Ya existe un registro para hoy');
      }

      // Create new registration with current timestamp
      final registration = TimeRegistration(
        id: _uuid.v4(),
        employeeId: employeeId,
        shiftId: shiftId,
        startTime: now,
        date: today,
      );

      await _firestore
          .collection(_collection)
          .doc(registration.id)
          .set(registration.toJson());

      return registration;
    } catch (e) {
      throw Exception('Error al iniciar jornada en Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> endWorkday(String registrationId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(registrationId)
          .get();

      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);

      // Prevent ending an already completed workday
      if (registration.endTime != null) {
        throw Exception('La jornada ya ha sido finalizada');
      }

      // Set end time to current timestamp
      final updated = registration.copyWith(endTime: DateTime.now());

      await _firestore.collection(_collection).doc(registrationId).update({
        'endTime': Timestamp.fromDate(updated.endTime!),
      });

      return updated;
    } catch (e) {
      throw Exception('Error al finalizar jornada en Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(registrationId)
          .get();

      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);

      // Prevent pausing an already paused workday
      if (registration.pauseTime != null) {
        throw Exception('La jornada ya está pausada');
      }

      // Set pause time to current timestamp
      final updated = registration.copyWith(pauseTime: DateTime.now());

      await _firestore.collection(_collection).doc(registrationId).update({
        'pauseTime': Timestamp.fromDate(updated.pauseTime!),
      });

      return updated;
    } catch (e) {
      throw Exception('Error al pausar jornada en Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(registrationId)
          .get();

      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);

      // Validate workday is paused before resuming
      if (registration.pauseTime == null) {
        throw Exception('La jornada no está pausada');
      }

      // Prevent resuming an already resumed workday
      if (registration.resumeTime != null) {
        throw Exception('La jornada ya ha sido reanudada');
      }

      // Set resume time to current timestamp
      final updated = registration.copyWith(resumeTime: DateTime.now());

      await _firestore.collection(_collection).doc(registrationId).update({
        'resumeTime': Timestamp.fromDate(updated.resumeTime!),
      });

      return updated;
    } catch (e) {
      throw Exception('Error al reanudar jornada en Firebase: $e');
    }
  }

  @override
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Query registrations sorted by most recent first
      final query = _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('startTime', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TimeRegistration.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception(
        'Error al cargar registros del empleado desde Firebase: $e',
      );
    }
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    try {
      // Use Firestore count aggregation for efficient counting
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception(
        'Error al contar registros del empleado desde Firebase: $e',
      );
    }
  }

  @override
  Future<List<TimeRegistration>> getMonthlyRegistrations(
    String employeeId,
    DateTime month,
  ) async {
    try {
      // Calculate month boundaries
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Query registrations within month range, sorted descending
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TimeRegistration.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception(
        'Error al cargar registros mensuales desde Firebase: $e',
      );
    }
  }

  @override
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month) async {
    try {
      // Calculate month boundaries
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Use Firestore count aggregation for efficient counting
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception(
        'Error al contar registros mensuales desde Firebase: $e',
      );
    }
  }
}
