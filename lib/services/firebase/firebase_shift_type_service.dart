import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/services/shift_type_service.dart';
import 'package:uuid/uuid.dart';

/// Firebase implementation of [ShiftTypeService].
class FirebaseShiftTypeService implements ShiftTypeService {
  final FirebaseFirestore _firestore;
  List<ShiftType>? _cachedShiftTypes;
  final String _collection = 'shift_types';
  final _uuid = const Uuid();

  FirebaseShiftTypeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    if (_cachedShiftTypes != null) return _cachedShiftTypes!;
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      _cachedShiftTypes = querySnapshot.docs
          .map((doc) => ShiftType.fromJson({...doc.data(), 'id': doc.id}))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return _cachedShiftTypes!;
    } catch (e) {
      throw Exception('Error al cargar tipos de turno desde Firebase: $e');
    }
  }

  @override
  Future<ShiftType?> getShiftTypeById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return ShiftType.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar tipo de turno desde Firebase: $e');
    }
  }

  Future<ShiftType> createShiftType(ShiftType shiftType) async {
    try {
      final shiftTypeWithId = ShiftType(
        id: shiftType.id.isEmpty ? _uuid.v4() : shiftType.id,
        name: shiftType.name,
        colorHex: shiftType.colorHex,
        startTime: shiftType.startTime,
        endTime: shiftType.endTime,
        pauseTime: shiftType.pauseTime,
        resumeTime: shiftType.resumeTime,
        targetTimeMinutes: shiftType.targetTimeMinutes,
      );
      await _firestore
          .collection(_collection)
          .doc(shiftTypeWithId.id)
          .set(_shiftTypeToJson(shiftTypeWithId));
      _cachedShiftTypes = null;
      return shiftTypeWithId;
    } catch (e) {
      throw Exception('Error al crear tipo de turno en Firebase: $e');
    }
  }

  Future<ShiftType> updateShiftType(ShiftType shiftType) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shiftType.id)
          .update(_shiftTypeToJson(shiftType));
      _cachedShiftTypes = null;
      return shiftType;
    } catch (e) {
      throw Exception('Error al actualizar tipo de turno en Firebase: $e');
    }
  }

  Future<void> deleteShiftType(String shiftTypeId) async {
    try {
      await _firestore.collection(_collection).doc(shiftTypeId).delete();
      _cachedShiftTypes = null;
    } catch (e) {
      throw Exception('Error al eliminar tipo de turno en Firebase: $e');
    }
  }

  Map<String, dynamic> _shiftTypeToJson(ShiftType shiftType) {
    return {
      'id': shiftType.id,
      'name': shiftType.name,
      'colorHex': shiftType.colorHex,
      'startTime': shiftType.startTime,
      'endTime': shiftType.endTime,
      'pauseTime': shiftType.pauseTime,
      'resumeTime': shiftType.resumeTime,
      'targetTimeMinutes': shiftType.targetTimeMinutes,
    };
  }
}
