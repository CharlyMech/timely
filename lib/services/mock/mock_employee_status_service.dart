import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:timely/models/employee_status.dart';
import 'package:timely/services/employee_status_service.dart';

/// Mock implementation of [EmployeeStatusService] for testing and development.
///
/// Loads employee status data from a local JSON file (assets/mock/employee_statuses.json)
/// instead of a remote database. Provides in-memory caching and simulated
/// network delays for realistic testing.
class MockEmployeeStatusService implements EmployeeStatusService {
  /// In-memory cache for employee statuses to simulate persistent storage.
  List<EmployeeStatus>? _cachedStatuses;

  /// Random generator for realistic network delay simulation.
  final _random = Random();

  /// Simulates network delay with random variation.
  Future<void> _simulateDelay(int minMs, int maxMs) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  @override
  Future<List<EmployeeStatus>> getAllStatuses() async {
    // Return cached statuses if available
    if (_cachedStatuses != null) {
      return _cachedStatuses!;
    }

    // Simulate network delay (small dataset)
    await _simulateDelay(250, 500);

    try {
      // Load statuses from asset bundle
      final String response =
          await rootBundle.loadString('assets/mock/employee_statuses.json');
      final data = json.decode(response) as List<dynamic>;
      _cachedStatuses = data
          .map((json) => EmployeeStatus.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedStatuses!;
    } catch (e) {
      // Return empty list if JSON file is missing
      _cachedStatuses = [];
      return _cachedStatuses!;
    }
  }

  @override
  Future<EmployeeStatus?> getStatusById(String id) async {
    // Load all statuses from cache or JSON, then find by ID
    final statuses = await getAllStatuses();
    try {
      return statuses.firstWhere((status) => status.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<EmployeeStatus?> getStatusByCode(String status) async {
    // Load all statuses from cache or JSON, then find by status code
    final statuses = await getAllStatuses();
    try {
      return statuses.firstWhere((s) => s.status == status);
    } catch (e) {
      return null;
    }
  }
}
