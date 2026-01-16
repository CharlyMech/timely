import 'package:timely/models/role.dart';

/// Service interface for managing employee roles.
///
/// Defines the contract for retrieving role definitions including
/// names, descriptions, and associated permissions.
abstract class RoleService {
  /// Retrieves all available roles in the system.
  ///
  /// Returns a list of all [Role] records. Implementations may use
  /// caching to optimize repeated calls since roles rarely change.
  Future<List<Role>> getAllRoles();

  /// Retrieves a specific role by its unique identifier.
  ///
  /// Returns the [Role] with the given [id], or null if not found.
  Future<Role?> getRoleById(String id);
}
