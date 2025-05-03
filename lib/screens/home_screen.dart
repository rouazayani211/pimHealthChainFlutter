import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../utils/themes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('token');
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('rememberMe', false);
    print('Logged out: Cleared SharedPreferences.');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/healththehain_logo.png',
              height: 100.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            'Welcome${user != null ? ", ${user.name}" : ""}!',
            style: CustomTextStyle.h1.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 20.h),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your HealthChain Dashboard',
                    style: CustomTextStyle.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Access your documents, appointments, messages, and profile using the navigation bar below.',
                    style: CustomTextStyle.h4.copyWith(
                      color: AppColors.textInputColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Logout',
              style: CustomTextStyle.buttonText,
            ),
          ),
        ],
      ),
    );
  }
}
