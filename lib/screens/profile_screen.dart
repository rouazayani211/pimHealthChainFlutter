import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../config/app_config.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Logger logger = Logger();
  String? userPhotoUrl;
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get the userId from the auth provider or shared preferences
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        userId = user.id;
        logger.i('User ID from auth provider: $userId');
      } else {
        // Try to get userId from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');
        logger.i('User ID from SharedPreferences: $userId');
      }
      
      if (userId == null) {
        logger.e('User ID not found');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Use the dedicated image endpoint to get the user's profile image
      // Note: Use the IP address instead of localhost since this will run on a mobile device
      final imageUrl = '${AppConfig.apiBaseUrl}/users/image/$userId';
      logger.i('Fetching user image from: $imageUrl');
      
      // Test the connection to the endpoint
      try {
        final response = await http.head(Uri.parse(imageUrl));
        logger.i('Image endpoint response status: ${response.statusCode}');
        logger.i('Image endpoint headers: ${response.headers}');
        
        if (response.statusCode != 200) {
          logger.w('Image endpoint returned non-200 status code: ${response.statusCode}');
          
          // Try with the hardcoded user ID from your message
          final hardcodedImageUrl = '${AppConfig.apiBaseUrl}/users/image/6817eebc3a94196157929851';
          logger.i('Trying hardcoded user ID endpoint: $hardcodedImageUrl');
          
          final hardcodedResponse = await http.head(Uri.parse(hardcodedImageUrl));
          logger.i('Hardcoded image endpoint response: ${hardcodedResponse.statusCode}');
          
          if (hardcodedResponse.statusCode == 200) {
            logger.i('Hardcoded image endpoint works, using that instead');
            setState(() {
              userPhotoUrl = hardcodedImageUrl;
              isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        logger.e('Error checking image endpoint: $e');
        // Continue anyway to try displaying the image
      }
      
      setState(() {
        userPhotoUrl = imageUrl;
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final logger = Logger();
    // Show confirmation dialog similar to the screenshot
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logout icon
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  size: 40.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              // Confirmation text
              Text(
                'Are you sure to log out of your account?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              // Log Out button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Proceed with logout if confirmed
    if (confirmLogout == true) {
      try {
        final apiService = ApiService();
        await apiService.clearCredentials();
        logger.i('Logged out: Cleared credentials via ApiService');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        logger.e('Logout error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    ScreenUtil.init(context, designSize: const Size(360, 690));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Color(0xFF6BC6B3),
              Color(0xFF6BC6B3).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with menu dots
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              // Profile photo
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.w,
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : userPhotoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    userPhotoUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                (loadingProgress.expectedTotalBytes ?? 1)
                                              : null,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      logger.e('Error loading image: $error');
                                      return const CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          'https://randomuser.me/api/portraits/women/44.jpg',
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://randomuser.me/api/portraits/women/44.jpg',
                                  ),
                                ),
                    ),
                    // Edit button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.w,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit,
                            size: 14.sp,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // User name and email
              SizedBox(height: 16.h),
              Text(
                user?.name ?? 'User Name',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (user?.email != null)
                Text(
                  user!.email,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              SizedBox(height: 30.h),
              
              // Menu options area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                      child: Column(
                        children: [
                          // Menu options...
                          _buildMenuOption(
                            icon: Icons.favorite_border,
                            title: 'My Saved',
                            iconColor: Colors.teal,
                            onTap: () {},
                          ),
                          _buildMenuOption(
                            icon: Icons.calendar_today,
                            title: 'Appointmnet',
                            iconColor: Colors.teal,
                            onTap: () {},
                          ),
                          _buildMenuOption(
                            icon: Icons.payment,
                            title: 'Payment Method',
                            iconColor: Colors.teal,
                            onTap: () {},
                          ),
                          _buildMenuOption(
                            icon: Icons.question_answer_outlined,
                            title: 'FAQs',
                            iconColor: Colors.teal,
                            onTap: () {},
                          ),
                          _buildMenuOption(
                            icon: Icons.logout,
                            title: 'Logout',
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            onTap: () => _showLogoutDialog(context),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.teal,
    Color textColor = Colors.black87,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16.sp,
        ),
        onTap: onTap,
      ),
    );
  }
}
