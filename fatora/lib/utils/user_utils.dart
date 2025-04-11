import '../services/users_service.dart';
import '../models/user_model.dart';

class UserUtils {
  static final UsersService _usersService = UsersService();

  /// Example method to create a user with the specified payload structure
  /// This demonstrates how to use the UsersService to create a user
  static Future<User> createExampleUser() async {
    try {
      // Sample payload matching the specified format:
      // {
      //   "email": "user@example.com",
      //   "password": "Password123!",
      //   "firstName": "John",
      //   "lastName": "Doe"
      // }
      return await _usersService.createUser(
        email: "user@example.com",
        password: "Password123!",
        firstName: "John",
        lastName: "Doe",
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create a user with custom data
  static Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      return await _usersService.createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (e) {
      rethrow;
    }
  }
}
