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
  bool _isInitialized = false;
  WebSocketService? _webSocketService; // To initialize WebSocket after login

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  void setWebSocketService(WebSocketService webSocketService) {
    _webSocketService = webSocketService;
  }
  
  // Initialize the auth state by checking for cached user information
  Future<void> initializeAuth() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to get user from SharedPreferences
      final user = await _authService.tryAutoLogin();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        logger.i('Auto-login successful for: ${user.name}');
        
        // Initialize WebSocket connection after auto-login
        if (_webSocketService != null) {
          await _webSocketService!.initializeSocket();
          logger.i('WebSocket initialized after auto-login for user: ${user.id}');
        }
      } else {
        logger.i('No cached credentials found for auto-login');
      }
    } catch (e) {
      logger.e('Error during auth initialization: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
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
      logger.i('User photo path: ${user.photo ?? "null"}');
      
      if (user.photo != null) {
        logger.i('Photo URL format check:');
        if (user.photo!.startsWith('http')) {
          logger.i('Photo is already a full URL: ${user.photo}');
        } else if (user.photo!.startsWith('/uploads')) {
          logger.i('Photo is a server path starting with /uploads: ${user.photo}');
        } else {
          logger.i('Photo is a relative path: ${user.photo}');
        }
      }

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
    await _authService.clearUserFromPrefs(); // Clear all user data
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
  
  // Update user information in memory and SharedPreferences
  Future<void> updateUserInfo(User updatedUser) async {
    try {
      await _authService.saveUserToPrefs(updatedUser);
      _currentUser = updatedUser;
      logger.i('User information updated: ${updatedUser.name}');
      notifyListeners();
    } catch (e) {
      logger.e('Failed to update user information: $e');
      throw Exception('Failed to update user information: $e');
    }
  }
}
