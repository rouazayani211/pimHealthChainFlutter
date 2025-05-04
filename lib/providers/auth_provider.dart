import 'package:HealthChain/services/socket_service.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'package:logger/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final Logger logger = Logger();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  WebSocketService? _webSocketService; // To initialize WebSocket after login

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  void setWebSocketService(WebSocketService webSocketService) {
    _webSocketService = webSocketService;
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final user = await _authService.login(email, password);
      _currentUser = user;
      _isAuthenticated = true;
      logger.i('Login successful for user: ${user.email}, name: ${user.name}');

      // Initialize WebSocket connection after login
      if (_webSocketService != null) {
        await _webSocketService!.initializeSocket();
        logger.i('WebSocket initialized after login for user: ${user.id}');
      } else {
        logger.w('WebSocketService not set, cannot initialize WebSocket');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      logger.e('Login failed: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getValidToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      logger.w('No valid token found');
      return null;
    }
    return token;
  }

  Future<void> refreshToken() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        logger.w('No token to refresh');
        throw Exception('No token available');
      }
      final newToken = await _authService.refreshToken(token);
      logger.i('Token refreshed successfully');

      // Re-initialize WebSocket connection after token refresh
      if (_webSocketService != null) {
        await _webSocketService!.initializeSocket();
        logger.i(
            'WebSocket re-initialized after token refresh for user: ${_currentUser?.id}');
      }

      notifyListeners();
    } catch (e) {
      logger.e('Token refresh error: $e');
      await logout();
      throw e;
    }
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    logger.i('User logged out');

    // Disconnect WebSocket on logout
    if (_webSocketService != null) {
      _webSocketService!.disconnect();
      logger.i('WebSocket disconnected on logout');
    }

    notifyListeners();
  }
}
