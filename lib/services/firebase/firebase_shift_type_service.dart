import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/services/shift_type_service.dart';

class FirebaseShiftTypeService implements ShiftTypeService {
  final FirebaseFirestore _firestore;
  List<ShiftType>? _cachedShiftTypes;

  FirebaseShiftTypeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    if (_cachedShiftTypes != null) {
      return _cachedShiftTypes!;
    }

    try {
      final querySnapshot = await _firestore.collection('shift_types').get();

      _cachedShiftTypes = querySnapshot.docs
          .map((doc) => ShiftType.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return _cachedShiftTypes!;
    } catch (e) {
      throw Exception('Error al cargar tipos de turno desde Firebase: $e');
    }
  }

  @override
  Future<ShiftType?> getShiftTypeById(String id) async {
    try {
      final doc = await _firestore.collection('shift_types').doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return ShiftType.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar tipo de turno desde Firebase: $e');
    }
  }
}
