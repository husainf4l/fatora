import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UsersService {
  final String _baseUrl = ApiConstants.baseUrl;
  static const String _userKey = 'user_data';

  // Demo user data (for development purposes)
  static final User _demoUser = User(
    id: 'demo-user-id',
    email: 'user@example.com',
    firstName: 'محمد',
    lastName: 'العبدالله',
    role: 'admin',
    phone: '0512345678',
    businessName: 'شركة فاتورة للفواتير',
    businessAddress: 'الرياض، المملكة العربية السعودية',
    taxNumber: '300123456700003',
    isEmailVerified: true,
    accessToken: 'demo-token',
  );

  /// Get the current logged-in user
  Future<User> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }

      // If no user found in SharedPreferences, save and return demo user
      await _saveDemoUser();
      return _demoUser;
    } catch (e) {
      // If there's an error, return demo user
      await _saveDemoUser();
      return _demoUser;
    }
  }

  /// Save demo user to SharedPreferences
  Future<void> _saveDemoUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_demoUser.toJson()));
    } catch (e) {
      // Ignore errors in demo mode
    }
  }

  /// Update the current user's data
  Future<User> updateCurrentUser(User updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // In a real app, we would send the updated data to the server:
      // final response = await http.put(
      //   Uri.parse('$_baseUrl/users/${updatedUser.id}'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer ${updatedUser.accessToken}',
      //   },
      //   body: jsonEncode(updatedUser.toJson()),
      // );

      // For demo purposes, just update locally
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      return updatedUser;
    } catch (e) {
      throw Exception('Error updating user: ${e.toString()}');
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);

      // In a real app, we would also invalidate the token on the server:
      // await http.post(
      //   Uri.parse('$_baseUrl/auth/logout'),
      //   headers: {
      //     'Authorization': 'Bearer $accessToken',
      //   },
      // );
    } catch (e) {
      throw Exception('Error logging out: ${e.toString()}');
    }
  }

  /// Creates a new user by sending a POST request to the /users endpoint
  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      print('Sending user creation request to: $_baseUrl/users');
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the access token
        final String accessToken = data['access_token'];

        // Extract the user data
        final Map<String, dynamic> userData = data['user'];

        // Create a user object with the access token
        final user = User.fromJson({...userData, 'accessToken': accessToken});

        // Save user to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));

        return user;
      } else {
        _handleError(response);
        throw Exception('Failed to create user');
      }
    } catch (e) {
      print('Error creating user: ${e.toString()}');
      throw Exception('Error creating user: ${e.toString()}');
    }
  }

  // Handle errors based on status code
  void _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw Exception('Invalid request data');
      case 401:
        throw Exception('Unauthorized');
      case 403:
        throw Exception('Access forbidden');
      case 409:
        throw Exception('Email already in use');
      case 422:
        throw Exception('Validation failed');
      case 500:
        throw Exception('Server error, please try again later');
      default:
        throw Exception('An unknown error occurred (${response.statusCode})');
    }
  }
}
