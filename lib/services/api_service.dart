import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../providers/app_config_provider.dart';

class ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, dynamic>? data;

  ApiResponse({required this.statusCode, required this.body, this.data});

  bool get isSuccess => statusCode == 200;
  bool get isForbidden => statusCode == 403;
  bool get hasData => data != null;
}

class ApiService {
  final AppConfigProvider _config;
  final String _baseUrl;

  ApiService(this._config, [String? baseUrl])
    : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  String get baseUrl => _baseUrl;

  Uri _buildUri(String endpoint) => Uri.parse('$_baseUrl$endpoint');

  Map<String, String> get _defaultHeaders => ApiConfig.defaultHeaders;

  Future<ApiResponse> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;
      Map<String, dynamic>? data;

      if (response.body.isNotEmpty) {
        try {
          data = json.decode(response.body);
        } catch (_) {}
      }

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse> get(String endpoint, {Duration? timeout}) async {
    final request = http
        .get(_buildUri(endpoint), headers: _defaultHeaders)
        .timeout(timeout ?? ApiConfig.defaultTimeout);
    return _handleRequest(request);
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? body,
    Duration? timeout,
  }) async {
    final request = http
        .post(_buildUri(endpoint), headers: _defaultHeaders, body: body)
        .timeout(timeout ?? ApiConfig.defaultTimeout);
    return _handleRequest(request);
  }

  Future<ApiResponse> postUrlEncoded(
    String endpoint, {
    required String body,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http
        .post(uri, headers: _defaultHeaders, body: body)
        .timeout(timeout ?? ApiConfig.defaultTimeout);
    return _handleRequest(request);
  }

  String get loginEndpoint {
    return _config.isWfa ? ApiEndpoints.loginGlobal : ApiEndpoints.login;
  }

  String get pingEndpoint {
    return _config.isWfa ? ApiEndpoints.pingGlobal : ApiEndpoints.ping;
  }

  Future<ApiResponse> login({
    required String username,
    required String password,
  }) async {
    return postUrlEncoded(
      loginEndpoint,
      body: 'username=$username&password=$password',
    );
  }

  Future<ApiResponse> ping({Duration? timeout}) async {
    return post(
      ApiEndpoints.pingGlobal,
      body: {'get_status': 'ON'},
      timeout: timeout ?? ApiConfig.shortTimeout,
    );
  }

  Future<ApiResponse> whoami({Duration? timeout}) async {
    return get(
      ApiEndpoints.whoami,
      timeout: timeout ?? ApiConfig.defaultTimeout,
    );
  }
}
