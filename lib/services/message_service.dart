import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'auth_service.dart';
import 'package:logger/logger.dart';

class MessageService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();
  final Logger logger = Logger();

  Future<List<Message>> getConversation(String otherUserId) async {
    final token = await _authService.getToken();
    if (token == null) {
      logger.e('No token found for fetching conversation');
      throw Exception('Not authenticated. Please log in again.');
    }

    logger.i('Fetching conversation with user: $otherUserId, token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$otherUserId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    logger.i(
        'Get conversation response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Message.fromJson(item)).toList();
    } else {
      final errorMessage = _parseError(response);
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 500) {
        throw Exception('Server error. Please try again or log in again.');
      }
      throw Exception('Failed to get conversation: $errorMessage');
    }
  }

  Future<List<Conversation>> getRecentConversations() async {
    final token = await _authService.getToken();
    if (token == null) {
      logger.e('No token found for fetching recent conversations');
      throw Exception('Not authenticated. Please log in again.');
    }

    logger.i('Fetching recent conversations with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    logger.i(
        'Get recent conversations response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Conversation.fromJson(item)).toList();
    } else {
      final errorMessage = _parseError(response);
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 500) {
        throw Exception('Server error. Please try again or log in again.');
      }
      throw Exception('Failed to get recent conversations: $errorMessage');
    }
  }

  Future<List<Message>> getUnreadMessages() async {
    final token = await _authService.getToken();
    if (token == null) {
      logger.e('No token found for fetching unread messages');
      throw Exception('Not authenticated. Please log in again.');
    }

    logger.i('Fetching unread messages with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/messages/unread'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    logger.i(
        'Get unread messages response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Message.fromJson(item)).toList();
    } else {
      final errorMessage = _parseError(response);
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 500) {
        throw Exception('Server error. Please try again or log in again.');
      }
      throw Exception('Failed to get unread messages: $errorMessage');
    }
  }

  Future<Message> markMessageAsRead(String messageId) async {
    final token = await _authService.getToken();
    if (token == null) {
      logger.e('No token found for marking message as read');
      throw Exception('Not authenticated. Please log in again.');
    }

    logger.i('Marking message as read: $messageId, token: $token');
    final response = await http.post(
      Uri.parse('$baseUrl/messages/mark-read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'messageId': messageId,
      }),
    );

    logger.i(
        'Mark message as read response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Message.fromJson(json.decode(response.body));
    } else {
      final errorMessage = _parseError(response);
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 500) {
        throw Exception('Server error. Please try again or log in again.');
      }
      throw Exception('Failed to mark message as read: $errorMessage');
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
