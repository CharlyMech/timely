import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';
import 'package:uuid/uuid.dart';

/// Firebase implementation of [EmployeeService].
class FirebaseEmployeeService implements EmployeeService {
  FirebaseEmployeeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String _collection = 'employees';
  final _uuid = const Uuid();

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final employees = <Employee>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        employees.add(Employee.fromJson(data));
      }
      return employees;
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

  Future<Employee> createEmployee(Employee employee) async {
    try {
      final employeeWithId = Employee(
        id: employee.id.isEmpty ? _uuid.v4() : employee.id,
        firstName: employee.firstName,
        lastName: employee.lastName,
        avatarUrl: employee.avatarUrl,
        pin: employee.pin,
        statusId: employee.statusId,
        email: employee.email,
        phone: employee.phone,
        address: employee.address,
        personId: employee.personId,
        roleId: employee.roleId,
        workType: employee.workType,
        socialSecurityNumber: employee.socialSecurityNumber,
      );
      await _firestore
          .collection(_collection)
          .doc(employeeWithId.id)
          .set(employeeWithId.toJson());
      return employeeWithId;
    } catch (e) {
      throw Exception('Error al crear empleado en Firebase: $e');
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestore.collection(_collection).doc(employeeId).delete();
    } catch (e) {
      throw Exception('Error al eliminar empleado en Firebase: $e');
    }
  }
}
