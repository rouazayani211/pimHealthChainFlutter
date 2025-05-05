import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'package:logger/logger.dart';

class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final Logger logger = Logger();

  // Constants for SharedPreferences keys
  static const String TOKEN_KEY = 'token';
  static const String USER_ID_KEY = 'user_id';
  static const String USER_NAME_KEY = 'user_name';
  static const String USER_EMAIL_KEY = 'user_email';
  static const String USER_ROLE_KEY = 'user_role';
  static const String USER_PHOTO_KEY = 'user_photo';
  static const String IS_LOGGED_IN_KEY = 'is_logged_in';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_KEY);
    return token;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    logger.i('Saved token to SharedPreferences');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    logger.i('Cleared token from SharedPreferences');
  }
  
  // Save full user information to SharedPreferences
  Future<void> saveUserToPrefs(User user) async {
    logger.i('Saving user to SharedPreferences: ${user.name}, ID: ${user.id}');
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(USER_ID_KEY, user.id);
    logger.i('Saved user ID: ${user.id}');
    
    await prefs.setString(USER_NAME_KEY, user.name);
    await prefs.setString(USER_EMAIL_KEY, user.email);
    await prefs.setString(USER_ROLE_KEY, user.role);
    
    if (user.photo != null) {
      await prefs.setString(USER_PHOTO_KEY, user.photo!);
    }
    
    await prefs.setBool(IS_LOGGED_IN_KEY, true);
    
    logger.i('User information saved to SharedPreferences successfully');
  }
  
  // Get user information from SharedPreferences
  Future<User?> getUserFromPrefs() async {
    logger.i('Retrieving user from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    
    final isLoggedIn = prefs.getBool(IS_LOGGED_IN_KEY) ?? false;
    if (!isLoggedIn) {
      logger.i('No logged in user found in SharedPreferences');
      return null;
    }
    
    final id = prefs.getString(USER_ID_KEY);
    final name = prefs.getString(USER_NAME_KEY);
    final email = prefs.getString(USER_EMAIL_KEY);
    final role = prefs.getString(USER_ROLE_KEY);
    final photo = prefs.getString(USER_PHOTO_KEY);
    
    if (id == null || name == null || email == null || role == null) {
      logger.w('Incomplete user data in SharedPreferences');
      return null;
    }
    
    logger.i('User retrieved from SharedPreferences: $name');
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      photo: photo,
    );
  }
  
  // Clear all user information from SharedPreferences
  Future<void> clearUserFromPrefs() async {
    logger.i('Clearing user data from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USER_ID_KEY);
    await prefs.remove(USER_NAME_KEY);
    await prefs.remove(USER_EMAIL_KEY);
    await prefs.remove(USER_ROLE_KEY);
    await prefs.remove(USER_PHOTO_KEY);
    await prefs.remove(IS_LOGGED_IN_KEY);
    
    logger.i('User data cleared from SharedPreferences');
  }

  Future<User> login(String email, String password) async {
    logger.i('Attempting login with email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      logger.i('Login response: ${response.statusCode}');
      logger.i('Login response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('Login data: $data');
        
        // Log all keys in the response for debugging
        if (data is Map<String, dynamic>) {
          logger.i('Response keys: ${data.keys.join(', ')}');
          for (var key in data.keys) {
            logger.i('Key: $key, Value type: ${data[key]?.runtimeType}');
          }
        }
        
        final token = data['token'];
        await saveToken(token);

        // Try to extract user information directly from the response
        User? userFromResponse;
        if (data.containsKey('user')) {
          try {
            // Extract the user data with any photo path
            final userData = data['user'];
            logger.i('User data from response: $userData');
            
            if (userData is Map<String, dynamic>) {
              logger.i('User data keys: ${userData.keys.join(', ')}');
              
              // Check for photo field
              if (userData.containsKey('photo')) {
                final photoValue = userData['photo'];
                logger.i('Photo from response: $photoValue (type: ${photoValue.runtimeType})');
              } else {
                logger.w('No photo field in user data from server');
              }
            }
            
            userFromResponse = User.fromJson(userData);
            logger.i('User extracted directly from response: ${userFromResponse.name}, photo: ${userFromResponse.photo}');
            
            // Save user to SharedPreferences
            await saveUserToPrefs(userFromResponse);
            return userFromResponse;
          } catch (e) {
            logger.w('Failed to parse user from response: $e');
            // Continue with JWT extraction as fallback
          }
        } else {
          logger.w('No user data in response, only token');
          
          // Check if user object is at root level
          if (data.containsKey('_id') && data.containsKey('name') && data.containsKey('email')) {
            try {
              userFromResponse = User.fromJson(data);
              logger.i('User extracted from root response: ${userFromResponse.name}, photo: ${userFromResponse.photo}');
              
              // Save user to SharedPreferences
              await saveUserToPrefs(userFromResponse);
              return userFromResponse;
            } catch (e) {
              logger.w('Failed to parse user from root response: $e');
            }
          }
        }

        // Extract user ID and email from token payload as fallback
        final tokenParts = token.split('.');
        if (tokenParts.length != 3) {
          throw Exception('Invalid JWT token');
        }
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))),
        );
        final userId = payload['sub'];
        final userEmail = payload['email'];
        final userName = payload['name'] ?? email.split('@')[0]; // Use part before @ as name if not available

        // Fetch full user data using getCurrentUser
        final user = await getCurrentUser(token);
        if (user != null) {
          // Save user to SharedPreferences
          await saveUserToPrefs(user);
          return user;
        } else {
          // Fallback if getCurrentUser fails
          final fallbackUser = User(
            id: userId,
            email: userEmail,
            name: userName, // Use name from JWT or email prefix instead of "Unknown"
            role: 'user',
          );
          // Save fallback user to SharedPreferences
          await saveUserToPrefs(fallbackUser);
          return fallbackUser;
        }
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to login: $errorMessage');
      }
    } catch (e) {
      logger.e('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<User?> getCurrentUser(String token) async {
    try {
      logger.i('Fetching current user with token');
      final uri = Uri.parse('$baseUrl/users/me');
      logger.i('Request URL: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i(
          'Get current user response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        logger.i('User data received: $userData');
        
        // Log photo information if available
        if (userData is Map<String, dynamic> && userData.containsKey('photo')) {
          logger.i('Photo in user data: ${userData['photo']}');
        } else {
          logger.w('No photo found in user data');
        }
        
        final user = User.fromJson(userData);
        logger.i('User created from JSON: ${user.name}, photo: ${user.photo}');
        
        // Save user to SharedPreferences
        await saveUserToPrefs(user);
        return user;
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to get current user: $errorMessage');
      }
    } catch (e) {
      logger.e('Error getting current user: $e');
      return null; // Gracefully handle failure
    }
  }
  
  // Check for cached credentials and try to validate them
  Future<User?> tryAutoLogin() async {
    try {
      logger.i('Attempting auto-login from stored credentials');
      final token = await getToken();
      final cachedUser = await getUserFromPrefs();
      
      if (token == null || cachedUser == null) {
        logger.i('No stored credentials found for auto-login');
        return null;
      }
      
      // Optionally verify token validity with the server
      // For now, we'll just return the cached user
      logger.i('Auto-login successful for user: ${cachedUser.name}');
      return cachedUser;
    } catch (e) {
      logger.e('Auto-login failed: $e');
      await clearUserFromPrefs(); // Clear invalid credentials
      return null;
    }
  }

  Future<String> refreshToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i(
          'Refresh token response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        await saveToken(newToken);
        return newToken;
      } else {
        final errorMessage = _parseError(response);
        throw Exception('Failed to refresh token: $errorMessage');
      }
    } catch (e) {
      logger.e('Refresh token error: $e');
      throw Exception('Failed to refresh token: $e');
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
