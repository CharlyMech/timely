import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/services/shift_service.dart';

class FirebaseShiftService implements ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'shifts';

  @override
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('date', descending: false)
          .limit(limit);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Shift.fromJson(data as Map<String, dynamic>);
          })
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los turnos: $e');
    }
  }

  @override
  Future<List<Shift>> getUpcomingShifts(String employeeId,
      {int limit = 10}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: today)
          .orderBy('date', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Shift.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los próximos turnos: $e');
    }
  }

  @override
  Future<Shift?> getTodayShift(String employeeId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('date', isLessThan: tomorrow)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Shift.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error al obtener el turno de hoy: $e');
    }
  }

  @override
  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error al contar los turnos del mes: $e');
    }
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    try {
      final docRef = _firestore.collection(_collection).doc(shift.id);
      await docRef.set(shift.toJson());
      return shift;
    } catch (e) {
      throw Exception('Error al crear el turno: $e');
    }
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    try {
      final docRef = _firestore.collection(_collection).doc(shift.id);
      await docRef.update(shift.toJson());
      return shift;
    } catch (e) {
      throw Exception('Error al actualizar el turno: $e');
    }
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore.collection(_collection).doc(shiftId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el turno: $e');
    }
  }
}
