import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/employee_status.dart';
import 'package:timely/services/employee_status_service.dart';

/// Firebase implementation of [EmployeeStatusService].
///
/// Manages employee status data using Firestore's 'employee_statuses' collection.
/// Provides in-memory caching since statuses are relatively static reference data.
class FirebaseEmployeeStatusService implements EmployeeStatusService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// In-memory cache for employee statuses to minimize database reads.
  List<EmployeeStatus>? _cachedStatuses;

  /// Creates a new Firebase employee status service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseEmployeeStatusService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<EmployeeStatus>> getAllStatuses() async {
    // Return cached statuses if available to minimize Firestore reads
    if (_cachedStatuses != null) {
      return _cachedStatuses!;
    }

    try {
      final querySnapshot =
          await _firestore.collection('employee_statuses').get();

      _cachedStatuses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Use existing 'id' field if present, otherwise use Firestore document ID
        final statusData =
            data.containsKey('id') ? data : {...data, 'id': doc.id};
        return EmployeeStatus.fromJson(statusData);
      }).toList();

      return _cachedStatuses!;
    } catch (e) {
      throw Exception('Error al cargar estados de empleado desde Firebase: $e');
    }
  }

  @override
  Future<EmployeeStatus?> getStatusById(String id) async {
    try {
      final doc =
          await _firestore.collection('employee_statuses').doc(id).get();

      if (!doc.exists) {
        return null;
      }

      // Merge Firestore document ID with status data
      return EmployeeStatus.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar estado de empleado desde Firebase: $e');
    }
  }

  @override
  Future<EmployeeStatus?> getStatusByCode(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('employee_statuses')
          .where('status', isEqualTo: status)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return EmployeeStatus.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar estado de empleado desde Firebase: $e');
    }
  }
}
