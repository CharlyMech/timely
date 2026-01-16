import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/role.dart';
import 'package:timely/services/role_service.dart';

class FirebaseRoleService implements RoleService {
  final FirebaseFirestore _firestore;
  List<Role>? _cachedRoles;

  FirebaseRoleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Role>> getAllRoles() async {
    if (_cachedRoles != null) {
      return _cachedRoles!;
    }

    try {
      final querySnapshot = await _firestore.collection('roles').get();

      _cachedRoles = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // If the data already has an 'id' field, use it; otherwise use doc.id
        final roleData = data.containsKey('id') ? data : {...data, 'id': doc.id};
        return Role.fromJson(roleData);
      }).toList();

      return _cachedRoles!;
    } catch (e) {
      throw Exception('Error al cargar roles desde Firebase: $e');
    }
  }

  @override
  Future<Role?> getRoleById(String id) async {
    try {
      final doc = await _firestore.collection('roles').doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return Role.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar rol desde Firebase: $e');
    }
  }
}
