import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';

/// Firebase implementation of [EmployeeService].
///
/// Manages employee data using Firestore's 'employees' collection.
/// Each employee document is identified by its Firestore document ID.
class FirebaseEmployeeService implements EmployeeService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// Name of the Firestore collection storing employee data.
  final String _collection = 'employees';

  /// Creates a new Firebase employee service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseEmployeeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Map Firestore document ID to Employee.id
        data['id'] = doc.id;
        return Employee.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar empleados desde Firebase: $e');
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      // Map Firestore document ID to Employee.id
      data['id'] = doc.id;
      return Employee.fromJson(data);
    } catch (e) {
      throw Exception('Error al cargar empleado desde Firebase: $e');
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(employee.id)
          .update(employee.toJson());
    } catch (e) {
      throw Exception('Error al actualizar empleado en Firebase: $e');
    }
  }
}
