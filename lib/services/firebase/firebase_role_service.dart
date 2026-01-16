import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/role.dart';
import 'package:timely/services/role_service.dart';

/// Firebase implementation of [RoleService].
///
/// Manages role data using Firestore's 'roles' collection. Provides
/// in-memory caching since roles are relatively static reference data.
class FirebaseRoleService implements RoleService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// In-memory cache for roles to minimize database reads.
  List<Role>? _cachedRoles;

  /// Creates a new Firebase role service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseRoleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Role>> getAllRoles() async {
    // Return cached roles if available to minimize Firestore reads
    if (_cachedRoles != null) {
      return _cachedRoles!;
    }

    try {
      final querySnapshot = await _firestore.collection('roles').get();

      _cachedRoles = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Use existing 'id' field if present, otherwise use Firestore document ID
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

      // Merge Firestore document ID with role data
      return Role.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Error al cargar rol desde Firebase: $e');
    }
  }
}
