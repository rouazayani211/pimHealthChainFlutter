import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_provider.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger logger = Logger();
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final Color primaryColor = const Color(0xFF45B3CB);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
        logger.i('Loaded saved credentials: email=${_emailController.text}');
      } else {
        logger.i('No saved credentials found.');
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
      logger.i('Saved credentials: email=${_emailController.text}');
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
      logger.i('Cleared saved credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                Image.asset('assets/healththehain_logo.png', height: 100.h),
                SizedBox(height: 30.h),
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 24.sp, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 40.h),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Enter your email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Enter your password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    errorText: _errorMessage,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                        Text(
                          'Remember Me',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgotPassword');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                authProvider.isLoading
                    ? CircularProgressIndicator(color: primaryColor)
                    : SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              logger.i(
                                  'Attempting login with email: ${_emailController.text}');
                              final success = await authProvider.login(
                                _emailController.text,
                                _passwordController.text,
                              );
                              if (success) {
                                await _saveCredentials();
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('isLoggedIn', true);
                                
                                // Log user information after successful login
                                final user = authProvider.currentUser;
                                logger.i('Login successful! User info:');
                                logger.i('User ID: ${user?.id}');
                                logger.i('User Name: ${user?.name}');
                                logger.i('User Email: ${user?.email}');
                                logger.i('User Role: ${user?.role}');
                                logger.i('User Photo: ${user?.photo}');
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Login successful!')),
                                );
                                Navigator.pushReplacementNamed(
                                    context, '/bottomNavBar');
                              } else {
                                setState(() {
                                  _errorMessage = authProvider.error ??
                                      'Invalid email or password';
                                });
                              }
                            } catch (e) {
                              logger.e('Login error: $e');
                              setState(() {
                                _errorMessage = e
                                        .toString()
                                        .contains('Failed to login')
                                    ? 'Invalid email or password'
                                    : e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
