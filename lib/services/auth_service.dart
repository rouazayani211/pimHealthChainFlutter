import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'package:logger/logger.dart';

class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final Logger logger = Logger();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    logger.i('Retrieved token: $token');
    return token;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    logger.i('Saved token to SharedPreferences: $token');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    logger.i('Cleared token from SharedPreferences');
  }

  Future<User> login(String email, String password) async {
    logger.i('Attempting login with email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      logger.i('Login response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await saveToken(token);

        // Extract user ID from token payload
        final tokenParts = token.split('.');
        if (tokenParts.length != 3) {
          throw Exception('Invalid JWT token');
        }
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))),
        );
        final userId = payload['sub'];
        final userEmail = payload['email'];

        // Create minimal User object
        return User(
          id: userId,
          email: userEmail,
          name: 'Unknown', // Placeholder, update if backend provides name
          role: 'user', // Placeholder, update if backend provides role
        );
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to login: $errorMessage');
      }
    } catch (e) {
      logger.e('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) {
      logger.w('No token found for getCurrentUser');
      return null;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i(
          'Get current user response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to get current user: $errorMessage');
      }
    } catch (e) {
      logger.e('Error getting current user: $e');
      return null; // Gracefully handle failure
    }
  }

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ??
          'Unknown error (status: ${response.statusCode})';
    } catch (_) {
      return 'Unknown error (status: ${response.statusCode})';
    }
  }
}
