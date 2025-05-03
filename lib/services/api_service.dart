import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'auth_service.dart';
import 'package:logger/logger.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();
  final Logger logger = Logger();

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await _authService.clearToken();
    logger.i('Credentials cleared.');
  }

  Future<String> signup(
    String email,
    String password,
    String name,
    String role,
  ) async {
    logger.i('Sending signup request: email=$email, name=$name, role=$role');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'photo': null,
        }),
      );
      logger.i('Signup response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        final userId = jsonDecode(response.body)['user']['_id'];
        return userId;
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to sign up: $errorMessage');
      }
    } catch (e) {
      logger.e('Signup error: $e');
      throw Exception('Signup failed: $e');
    }
  }

  Future<Map<String, String>> forgotPassword(String email) async {
    logger.i('Sending forgot password request: email=$email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      logger.i(
          'Forgot password response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'OTP sent',
          'otp': data['otp'] ?? '',
          'userId': data['userId'] ?? '',
        };
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to request OTP: $errorMessage');
      }
    } catch (e) {
      logger.e('Forgot password error: $e');
      throw Exception('Failed to request OTP: $e');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    logger.i('Sending OTP verification request: email=$email, otp=$otp');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      logger.i(
          'OTP verification response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to verify OTP: $errorMessage');
      }
    } catch (e) {
      logger.e('OTP verification error: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    logger.i('Sending reset password request: email=$email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      logger.i(
          'Reset password response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        logger.i('Password reset successful for email: $email');
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to reset password: $errorMessage');
      }
    } catch (e) {
      logger.e('Reset password error: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<List<Conversation>> getConversations() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i(
          'Get conversations response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to fetch conversations: $errorMessage');
      }
    } catch (e) {
      logger.e('Error fetching conversations: $e');
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  Future<List<Message>> getMessages(String otherUserId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversation/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i(
          'Get messages response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to fetch messages: $errorMessage');
      }
    } catch (e) {
      logger.e('Error fetching messages: $e');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<Message> sendMessage(String recipientId, String content) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipientId': recipientId,
          'content': content,
        }),
      );
      logger.i(
          'Send message response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to send message: $errorMessage');
      }
    } catch (e) {
      logger.e('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messageId': messageId,
        }),
      );
      logger.i(
          'Mark message as read response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMessage = _parseError(response);
        throw Exception('Failed to mark message as read: $errorMessage');
      }
    } catch (e) {
      logger.e('Error marking message as read: $e');
      throw Exception('Failed to mark message as read: $e');
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
