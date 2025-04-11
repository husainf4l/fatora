import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  // Using a constant from utils for easier configuration
  static const String _baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Register a new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? businessName,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'businessName': businessName,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);

      // Save token and user data
      await _saveAuthData(data['token'], user);

      return user;
    } else {
      // Handle errors based on status code
      _handleAuthError(response);
      throw Exception('Registration failed');
    }
  }

  // Login existing user
  Future<User> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print("response: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);

      // Save token and user data
      await _saveAuthData(data['token'], user);

      return user;
    } else {
      _handleAuthError(response);
      throw Exception('Login failed');
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    // Optional: Call logout endpoint on server
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // Ignore errors during logout
      }
    }
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }

    // Try to fetch from API if we have token
    final token = await getToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final user = User.fromJson(jsonDecode(response.body));
          await _saveUser(user);
          return user;
        }
      } catch (e) {
        // Token might be invalid
        await logout();
      }
    }

    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save auth data
  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Save user only
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Handle authentication errors
  void _handleAuthError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw Exception('Invalid request data');
      case 401:
        throw Exception('Invalid credentials');
      case 403:
        throw Exception('Access forbidden');
      case 404:
        throw Exception('Resource not found');
      case 409:
        throw Exception('Email already in use');
      case 422:
        throw Exception('Validation failed');
      case 500:
        throw Exception('Server error, please try again later');
      default:
        throw Exception('An unknown error occurred');
    }
  }
}
