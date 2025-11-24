import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'auth_service.dart';

/// Centralized HTTP service that automatically injects authentication headers
/// Handles 401 (expired token) and 403 (insufficient permissions) responses
class HttpService {
  static const String baseUrl = 'http://localhost:3000';

  static final AuthService _authService = AuthService();

  /// GET request with auto-injected auth headers
  static Future<http.Response> get(
    String endpoint, {
    BuildContext? context,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(url, headers: _buildHeaders());

      return _handleResponse(response, context);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST request with auto-injected auth headers
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    BuildContext? context,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response, context);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PUT request with auto-injected auth headers
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    BuildContext? context,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response, context);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request with auto-injected auth headers
  static Future<http.Response> delete(
    String endpoint, {
    BuildContext? context,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(url, headers: _buildHeaders());

      return _handleResponse(response, context);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Build headers with Authorization token if user is logged in
  static Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};

    // Add Authorization header if user is logged in
    if (_authService.isLoggedIn()) {
      final token = _authService.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle response errors (401, 403)
  static http.Response _handleResponse(
    http.Response response,
    BuildContext? context,
  ) {
    // Handle 401 Unauthorized (expired or invalid token)
    if (response.statusCode == 401) {
      _handle401(context);
      throw Exception('Authentication required');
    }

    // Handle 403 Forbidden (insufficient permissions)
    if (response.statusCode == 403) {
      _handle403(context);
      throw Exception('Insufficient permissions');
    }

    return response;
  }

  /// Handle 401 Unauthorized - logout and redirect to login
  static void _handle401(BuildContext? context) {
    // Logout user (clear token)
    _authService.logout();

    // Show session expired message
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please login again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  /// Handle 403 Forbidden - show permission error
  static void _handle403(BuildContext? context) {
    if (context != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content: const Text(
            'You do not have permission to perform this action. '
            'Admin access is required.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
