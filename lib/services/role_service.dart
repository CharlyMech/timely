import 'package:timely/models/role.dart';

// Interface
abstract class RoleService {
  Future<List<Role>> getAllRoles();
  Future<Role?> getRoleById(String id);
}
