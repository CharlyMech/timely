import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:uuid/uuid.dart';

/// Implementación Firebase del servicio de registros horarios
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
  Future<TimeRegistration> startWorkday(String employeeId) async {
    try {
      final now = DateTime.now();
      final today = DateTimeUtils.getTodayFormatted();

      // Verificar que no exista un registro activo
      final existing = await getTodayRegistration(employeeId);
      if (existing != null) {
        throw Exception('Ya existe un registro para hoy');
      }

      final registration = TimeRegistration(
        id: _uuid.v4(),
        employeeId: employeeId,
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

      if (registration.endTime != null) {
        throw Exception('La jornada ya ha sido finalizada');
      }

      final updated = registration.copyWith(endTime: DateTime.now());

      await _firestore.collection(_collection).doc(registrationId).update({
        'endTime': updated.endTime!.toIso8601String(),
      });

      return updated;
    } catch (e) {
      throw Exception('Error al finalizar jornada en Firebase: $e');
    }
  }

  @override
  Future<List<TimeRegistration>> getRegistrationsByDate(String date) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TimeRegistration.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar registros desde Firebase: $e');
    }
  }

  /// Obtiene todos los registros de un empleado (método adicional)
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 30,
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
      throw Exception(
        'Error al cargar registros del empleado desde Firebase: $e',
      );
    }
  }
}
