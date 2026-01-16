import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/role.dart';
import 'package:timely/services/role_service.dart';

class MockRoleService implements RoleService {
  List<Role>? _cachedRoles;

  @override
  Future<List<Role>> getAllRoles() async {
    if (_cachedRoles != null) {
      return _cachedRoles!;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final String response =
          await rootBundle.loadString('assets/mock/roles.json');
      final data = json.decode(response) as List<dynamic>;
      _cachedRoles = data
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedRoles!;
    } catch (e) {
      // If file doesn't exist or error loading, return empty list
      _cachedRoles = [];
      return _cachedRoles!;
    }
  }

  @override
  Future<Role?> getRoleById(String id) async {
    final roles = await getAllRoles();
    try {
      return roles.firstWhere((role) => role.id == id);
    } catch (e) {
      return null;
    }
  }
}
