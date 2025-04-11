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

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        _handleError(response);
        throw Exception('Failed to create user');
      }
    } catch (e) {
      print('Error creating user: ${e.toString()}');
      // Handle any other errors that may occur
      // This could be network issues, JSON parsing errors, etc.
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
