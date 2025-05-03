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

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final user = await _authService.login(email, password);
      _currentUser = user;
      _isAuthenticated = true;
      logger.i('Login successful for user: ${user.email}');
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
    // Optional: Validate token expiration (decode JWT and check 'exp')
    return token;
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    logger.i('User logged out');
    notifyListeners();
  }
}
