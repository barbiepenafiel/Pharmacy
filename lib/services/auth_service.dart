import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Backend URL - use local IP for emulator/real device, localhost for web
  static String get baseUrl {
    // For web (Chrome, Firefox, etc), use localhost
    // For Android emulator or real device, use local IP
    // For iOS simulator, use localhost
    return 'http://192.168.1.7:3000';
  }

  // In-memory token storage
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  /// Login user via backend API
  Future<({bool success, String message, String? fullName})> login({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      return (
        success: false,
        message: 'Email and password are required',
        fullName: null,
      );
    }

    try {
      // Call backend API
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'action': 'login',
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Connection timeout - backend not responding'),
          );

      // Check if response is valid JSON
      if (response.body.isEmpty) {
        return (
          success: false,
          message: 'Server returned empty response',
          fullName: null,
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Store token
        _authToken = responseData['token'];

        // Store user info
        _currentUser = {
          'id': responseData['user']['id'].toString(),
          'email': responseData['user']['email'],
          'fullName': responseData['user']['fullName'],
          'isAdmin': responseData['user']['isAdmin'] ?? false,
        };

        return (
          success: true,
          message: 'Login successful',
          fullName: responseData['user']['fullName'] as String?,
        );
      } else {
        return (
          success: false,
          message:
              responseData['message'] as String? ?? 'Invalid email or password',
          fullName: null,
        );
      }
    } on FormatException {
      return (
        success: false,
        message:
            'Server returned invalid data. Please check backend is running on $baseUrl',
        fullName: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Error connecting to server: ${e.toString()}',
        fullName: null,
      );
    }
  }

  /// Register user via backend API
  Future<({bool success, String message})> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validate inputs
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      return (success: false, message: 'All fields are required');
    }

    if (password.length < 6) {
      return (
        success: false,
        message: 'Password must be at least 6 characters',
      );
    }

    if (password != confirmPassword) {
      return (success: false, message: 'Passwords do not match');
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      return (success: false, message: 'Please enter a valid email address');
    }

    try {
      // Call backend API
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'action': 'register',
              'fullName': fullName,
              'email': email,
              'password': password,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success'] == true) {
        return (
          success: true,
          message: 'Registration successful. Please login.',
        );
      } else {
        return (
          success: false,
          message: responseData['message'] as String? ?? 'Registration failed',
        );
      }
    } catch (e) {
      return (
        success: false,
        message: 'Error connecting to server: ${e.toString()}',
      );
    }
  }

  /// Get current auth token
  String? getAuthToken() {
    return _authToken;
  }

  /// Get current logged-in user
  Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  /// Check if current user is admin
  bool isAdmin() {
    return _currentUser?['isAdmin'] ?? false;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _authToken != null && _currentUser != null;
  }

  /// Logout user
  void logout() {
    _authToken = null;
    _currentUser = null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
