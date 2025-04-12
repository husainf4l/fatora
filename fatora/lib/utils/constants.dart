class ApiConstants {
  // Base URL for your NestJS backend
  // For local development using an emulator/simulator:
  //static const String baseUrl = 'http://localhost:3000/api';

  // For testing on a real device (replace with your computer's local IP):
  static const String baseUrl = 'http://192.168.0.167:3000';

  // For production:
  // static const String baseUrl = 'https://api.yourproduction.com/api';
}

class AppConstants {
  // App-wide constants
  static const String appName = 'فاتورة';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
}

class ValidationConstants {
  // Validation regex patterns
  static final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static const minPasswordLength = 6;
  static const maxNameLength = 50;
}
