import 'package:timely/services/api/api_client.dart';

/// API authentication service – PIN verification for employee identity.
///
/// Calls POST /api/{companyId}/auth/pin with `{ pin, uuid }`.
/// Does not require a prior JWT; uses x-app-token only.
/// Returns `true` when the API confirms the PIN is correct.
class ApiAuthService {
  ApiAuthService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  /// Verifies [pin] for the employee identified by [employeeId] (UUID).
  ///
  /// Body: `{ "pin": "string", "employeeId": "string" }`.
  /// Response: `{ "success": true, "data": { "success": true } }`.
  /// Returns `true` on success, `false` otherwise.
  Future<bool> verifyPin(String pin, String employeeId) async {
    final res = await _client.post(
      '$_prefix/auth/pin',
      body: {'pin': pin, 'employeeId': employeeId},
    );
    if (!res.success) return false;
    // ApiClient unwraps { success, data } → res.data is the inner payload.
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'];
      if (success is bool) return success;
    }
    return res.success;
  }
}
