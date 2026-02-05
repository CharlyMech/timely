import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/timezone_utils.dart';
import 'package:uuid/uuid.dart';

/// Firebase implementation of [TimeRegistrationService].
class FirebaseTimeRegistrationService implements TimeRegistrationService {
  final FirebaseFirestore _firestore;
  final String _collection = 'time_registrations';
  final _uuid = const Uuid();

  FirebaseTimeRegistrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    try {
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
      final existing = await getTodayRegistration(employeeId);
      if (existing != null) throw Exception('Ya existe un registro para hoy');
      final registration = TimeRegistration(
        id: _uuid.v4(),
        employeeId: employeeId,
        shiftId: shiftId,
        startTime: now,
        date: today,
        createdAt: now,
        lastUpdatedAt: now,
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
      final doc = await _firestore.collection(_collection).doc(registrationId).get();
      if (!doc.exists) throw Exception('Registro no encontrado');
      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);
      if (registration.endTime != null) throw Exception('La jornada ya ha sido finalizada');
      final now = DateTime.now();
      final updated = registration.copyWith(endTime: now, lastUpdatedAt: now);
      await _firestore.collection(_collection).doc(registrationId).update({
        'endTime': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(updated.endTime!)),
        'lastUpdatedAt': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(now)),
      });
      return updated;
    } catch (e) {
      throw Exception('Error al finalizar jornada en Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(registrationId).get();
      if (!doc.exists) throw Exception('Registro no encontrado');
      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);
      if (registration.pauseTime != null) throw Exception('La jornada ya está pausada');
      final now = DateTime.now();
      final updated = registration.copyWith(pauseTime: now, lastUpdatedAt: now);
      await _firestore.collection(_collection).doc(registrationId).update({
        'pauseTime': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(updated.pauseTime!)),
        'lastUpdatedAt': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(now)),
      });
      return updated;
    } catch (e) {
      throw Exception('Error al pausar jornada en Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(registrationId).get();
      if (!doc.exists) throw Exception('Registro no encontrado');
      final data = doc.data()!;
      data['id'] = doc.id;
      final registration = TimeRegistration.fromJson(data);
      if (registration.pauseTime == null) throw Exception('La jornada no está pausada');
      if (registration.resumeTime != null) throw Exception('La jornada ya ha sido reanudada');
      final now = DateTime.now();
      final updated = registration.copyWith(resumeTime: now, lastUpdatedAt: now);
      await _firestore.collection(_collection).doc(registrationId).update({
        'resumeTime': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(updated.resumeTime!)),
        'lastUpdatedAt': Timestamp.fromDate(TimezoneUtils.toUtcForStorage(now)),
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
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TimeRegistration.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar registros del empleado desde Firebase: $e');
    }
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error al contar registros del empleado desde Firebase: $e');
    }
  }

  @override
  Future<List<TimeRegistration>> getMonthlyRegistrations(
    String employeeId,
    DateTime month,
  ) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
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
      throw Exception('Error al cargar registros mensuales desde Firebase: $e');
    }
  }

  @override
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error al contar registros mensuales desde Firebase: $e');
    }
  }

  @override
  Future<Map<String, TimeRegistration>> getAllTodayRegistrations() async {
    try {
      final today = DateTimeUtils.getTodayFormatted();
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isEqualTo: today)
          .get();
      final Map<String, TimeRegistration> registrationsByEmployee = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final registration = TimeRegistration.fromJson(data);
        registrationsByEmployee[registration.employeeId] = registration;
      }
      return registrationsByEmployee;
    } catch (e) {
      throw Exception('Error al cargar registros de hoy desde Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration?> getRegistrationById(String registrationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(registrationId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return TimeRegistration.fromJson(data);
    } catch (e) {
      throw Exception('Error al cargar registro desde Firebase: $e');
    }
  }

  @override
  Future<TimeRegistration?> getActiveRegistration(String employeeId) async {
    final today = await getTodayRegistration(employeeId);
    if (today == null || !today.isActive) return null;
    return today;
  }

  @override
  Future<List<TimeRegistration>> getAllActiveRegistrations() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('endTime', isEqualTo: null)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TimeRegistration.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar registros activos desde Firebase: $e');
    }
  }

  @override
  Future<void> addNoteToRegistration(String registrationId, String note) async {
    // Firebase: notes are API-only in this setup; no-op so callers do not break.
  }

  @override
  Future<TimeRegistration> autoCloseRegistration(String registrationId) async {
    return endWorkday(registrationId);
  }
}
