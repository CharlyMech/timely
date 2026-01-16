import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/role.dart';
import 'package:timely/services/role_service.dart';

/// Mock implementation of [RoleService] for testing and development.
///
/// Loads role data from a local JSON file (assets/mock/roles.json)
/// instead of a remote database. Provides in-memory caching and simulated
/// network delays for realistic testing.
class MockRoleService implements RoleService {
  /// In-memory cache for roles to simulate persistent storage.
  List<Role>? _cachedRoles;

  @override
  Future<List<Role>> getAllRoles() async {
    // Return cached roles if available
    if (_cachedRoles != null) {
      return _cachedRoles!;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      // Load roles from asset bundle
      final String response =
          await rootBundle.loadString('assets/mock/roles.json');
      final data = json.decode(response) as List<dynamic>;
      _cachedRoles = data
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedRoles!;
    } catch (e) {
      // Return empty list if JSON file is missing
      _cachedRoles = [];
      return _cachedRoles!;
    }
  }

  @override
  Future<Role?> getRoleById(String id) async {
    // Load all roles from cache or JSON, then find by ID
    final roles = await getAllRoles();
    try {
      return roles.firstWhere((role) => role.id == id);
    } catch (e) {
      return null;
    }
  }
}
