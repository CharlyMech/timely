import 'package:timely/services/api/api_client.dart';

/// Result of a successful PIN login against the API.
///
/// The API returns [accessToken] (JWT) and the [employeeId] of the employee
/// that owns the PIN. Use the token for subsequent API calls and navigate
/// to the employee profile with [employeeId].
class AuthPinResult {
  final String accessToken;
  final String employeeId;

  const AuthPinResult({
    required this.accessToken,
    required this.employeeId,
  });
}

/// API authentication service (PIN login for app access).
///
/// Calls POST /api/{companyId}/auth/pin. Does not require a prior JWT;
/// uses x-app-token only. After success, the app should set the returned
/// [AuthPinResult.accessToken] so [ApiClient] sends it as Bearer for data requests.
class ApiAuthService {
  ApiAuthService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  /// Logs in with the given PIN. Returns [AuthPinResult] on success, null on failure.
  ///
  /// Body: `{ "pin": "string" }`.
  /// Response: `{ "accessToken": "JWT", "employee": { "id", "firstName", "lastName", "roleId", "statusId" } }`.
  Future<AuthPinResult?> loginWithPin(String pin) async {
    final res = await _client.post(
      '$_prefix/auth/pin',
      body: {'pin': pin},
    );
    if (!res.success) return null;
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return null;
    final accessToken = map['accessToken'] as String?;
    final employee = map['employee'];
    if (accessToken == null || accessToken.isEmpty) return null;
    String? employeeId;
    if (employee is Map<String, dynamic>) {
      employeeId = employee['id'] as String?;
    }
    if (employeeId == null || employeeId.isEmpty) return null;
    return AuthPinResult(accessToken: accessToken, employeeId: employeeId);
  }
}
