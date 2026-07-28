import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw ApiException(
        error['error'] ?? 'An error occurred',
        response.statusCode,
      );
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: await _getHeaders(),
          body: json.encode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: await _getHeaders(),
          body: json.encode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
          headers: await _getHeaders(),
          body: json.encode({
            'email': email,
            'otp': otp,
          }),
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  // Shloka endpoints
  static Future<List<dynamic>> getShlokas({String? akshara}) async {
    final uri = akshara != null
        ? Uri.parse('${ApiConfig.baseUrl}/shlokas?akshara=$akshara')
        : Uri.parse('${ApiConfig.baseUrl}/shlokas');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(ApiConfig.timeout);

    final data = await _handleResponse(response);
    return data['shlokas'] as List<dynamic>;
  }

  static Future<List<String>> getAksharas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/shlokas/aksharas'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(ApiConfig.timeout);

    final data = await _handleResponse(response);
    return List<String>.from(data['aksharas']);
  }

  static Future<List<dynamic>> searchShlokas(String query) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/shlokas/search?q=${Uri.encodeComponent(query)}');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(ApiConfig.timeout);

    final data = await _handleResponse(response);
    return data['shlokas'] as List<dynamic>;
  }
}
