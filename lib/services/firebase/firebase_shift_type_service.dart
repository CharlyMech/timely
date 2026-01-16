import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/services/shift_type_service.dart';

/// Firebase implementation of [ShiftTypeService].
///
/// Manages shift type data using Firestore's 'shift_types' collection.
/// Provides in-memory caching since shift types are relatively static
/// reference data.
class FirebaseShiftTypeService implements ShiftTypeService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// In-memory cache for shift types to minimize database reads.
  List<ShiftType>? _cachedShiftTypes;

  /// Creates a new Firebase shift type service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseShiftTypeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    // Return cached shift types if available to minimize Firestore reads
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

      // Merge Firestore document ID with shift type data
      return ShiftType.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar tipo de turno desde Firebase: $e');
    }
  }
}
