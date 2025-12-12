import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:uuid/uuid.dart';

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
}
