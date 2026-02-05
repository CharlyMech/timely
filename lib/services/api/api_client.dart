import 'package:dio/dio.dart';

/// Configuration for the API client.
class ApiConfig {
  /// Base URL for the API (e.g. http://localhost:3000/api).
  final String baseUrl;

  /// Company/tenant ID for multi-tenant API (e.g. timely-demo).
  final String appId;

  /// App token sent in [x-app-token] header for API authentication.
  final String appToken;

  /// Default timeout for requests in seconds.
  final int timeoutSeconds;

  /// Optional authorization token (Bearer).
  final String? authToken;

  const ApiConfig({
    required this.baseUrl,
    required this.appId,
    required this.appToken,
    this.timeoutSeconds = 30,
    this.authToken,
  });

  /// Path prefix for company-scoped resources; starts with / so Dio builds URL correctly.
  /// e.g. /api/timely-demo → GET /api/timely-demo/employees
  String get companiesPrefix => '/api/$appId';

  /// Creates a copy with the given fields replaced.
  ApiConfig copyWith({
    String? baseUrl,
    String? appId,
    String? appToken,
    int? timeoutSeconds,
    String? authToken,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      appId: appId ?? this.appId,
      appToken: appToken ?? this.appToken,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      authToken: authToken ?? this.authToken,
    );
  }
}

/// Response wrapper for API calls.
class ApiResponse<T> {
  /// Whether the request was successful.
  final bool success;

  /// HTTP status code.
  final int statusCode;

  /// Response data (if successful).
  final T? data;

  /// Error message (if failed).
  final String? error;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });

  /// Creates a successful response.
  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse(
      success: true,
      statusCode: statusCode,
      data: data,
    );
  }

  /// Creates an error response.
  factory ApiResponse.error(String error, int statusCode) {
    return ApiResponse(
      success: false,
      statusCode: statusCode,
      error: error,
    );
  }
}

/// Base API client for making HTTP requests using Dio.
///
/// This client is designed to be used when the app migrates from
/// Firebase to a REST API. Currently a placeholder for future implementation.
class ApiClient {
  /// Dio instance for HTTP requests.
  late final Dio _dio;

  /// API configuration.
  ApiConfig _config;

  /// Creates a new API client.
  ApiClient({
    Dio? dio,
    required ApiConfig config,
  }) : _config = config {
    _dio = dio ?? Dio();
    _configureClient();
  }

  /// Configures the Dio client with base options.
  void _configureClient() {
    _dio.options = BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: Duration(seconds: _config.timeoutSeconds),
      receiveTimeout: Duration(seconds: _config.timeoutSeconds),
      sendTimeout: Duration(seconds: _config.timeoutSeconds),
      headers: _defaultHeaders,
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_config.authToken != null) {
            options.headers['Authorization'] = 'Bearer ${_config.authToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Transform DioException to a more user-friendly format
          handler.next(error);
        },
      ),
    );
  }

  /// Updates the configuration.
  void updateConfig(ApiConfig config) {
    _config = config;
    _configureClient();
  }

  /// Gets the current configuration.
  ApiConfig get config => _config;

  /// Gets the default headers for requests.
  Map<String, String> get _defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-app-token': _config.appToken,
    };
  }

  /// Makes a GET request.
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Makes a POST request.
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Makes a PUT request.
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Makes a PATCH request.
  Future<ApiResponse<Map<String, dynamic>>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Makes a DELETE request.
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Handles a successful response.
  ///
  /// If the API returns a raw array (e.g. `[...]`), it is wrapped as
  /// `{ "data": [...] }` so services that expect `res.data['data'] ?? res.data`
  /// receive the list correctly.
  ApiResponse<Map<String, dynamic>> _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      final raw = response.data;
      final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is List) {
        data = <String, dynamic>{'data': raw};
      } else {
        data = <String, dynamic>{};
      }
      return ApiResponse.success(data, statusCode);
    } else {
      final error = _extractErrorMessage(response.data);
      return ApiResponse.error(error, statusCode);
    }
  }

  /// Handles a Dio error.
  ApiResponse<Map<String, dynamic>> _handleError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    String error;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        error = 'Tiempo de espera agotado. Por favor, inténtelo de nuevo.';
        break;
      case DioExceptionType.connectionError:
        error = 'Error de conexión. Compruebe su conexión a internet.';
        break;
      case DioExceptionType.badResponse:
        error = _extractErrorMessage(e.response?.data);
        break;
      case DioExceptionType.cancel:
        error = 'La solicitud fue cancelada.';
        break;
      default:
        error = 'Error inesperado: ${e.message}';
    }

    return ApiResponse.error(error, statusCode);
  }

  /// Extracts error message from response data.
  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Error desconocido';

    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          'Error desconocido';
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return 'Error desconocido';
  }

  /// Closes the client and releases resources.
  void dispose() {
    _dio.close();
  }
}
