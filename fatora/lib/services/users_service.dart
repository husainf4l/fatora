import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';

class UsersService {
  final String _baseUrl = ApiConstants.baseUrl;

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
        return User.fromJson({...userData, 'accessToken': accessToken});
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
