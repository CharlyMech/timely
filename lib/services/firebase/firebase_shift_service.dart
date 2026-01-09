import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/services/shift_service.dart';
import 'package:uuid/uuid.dart';

class FirebaseShiftService implements ShiftService {
  final FirebaseFirestore _firestore;
  final String _collection = 'shifts';
  final _uuid = const Uuid();

  FirebaseShiftService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
          .orderBy('date', descending: false);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Shift.fromJson(data);
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
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .orderBy('date', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Shift.fromJson(data);
          })
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
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(tomorrow))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Shift.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener el turno de hoy: $e');
    }
  }

  @override
  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error al contar los turnos del mes: $e');
    }
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    try {
      final shiftWithId = Shift(
        id: shift.id.isEmpty ? _uuid.v4() : shift.id,
        employeeId: shift.employeeId,
        date: shift.date,
        shiftTypeId: shift.shiftTypeId,
        notes: shift.notes,
      );

      await _firestore
          .collection(_collection)
          .doc(shiftWithId.id)
          .set(shiftWithId.toJson());

      return shiftWithId;
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
