import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';

/// Implementación Firebase del servicio de empleados
class FirebaseEmployeeService implements EmployeeService {
  final FirebaseFirestore _firestore;
  final String _collection = 'employees';

  FirebaseEmployeeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Usar el ID del documento
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

  /// Crea un nuevo empleado (método adicional para Firebase)
  Future<String> createEmployee(Employee employee) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(employee.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear empleado en Firebase: $e');
    }
  }

  /// Elimina un empleado (método adicional para Firebase)
  Future<void> deleteEmployee(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar empleado en Firebase: $e');
    }
  }
}
