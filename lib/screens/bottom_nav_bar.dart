import 'package:HealthChain/screens/messages/conversation_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/rdv_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notification_screen.dart';
import '../utils/colors.dart';
import '../utils/themes.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int page = 0;

  static final List<Widget> _pagesAll = <Widget>[
    const HomeScreen(),
    const DocumentsScreen(),
    const RdvScreen(),
    const ConversationListScreen(),
    const ProfileScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final token = prefs.getString('token');
    if (email == null || token == null) {
      print('No saved credentials found.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0.w),
            child: IconButton(
              iconSize: 30.w,
              icon: const Icon(Icons.notifications_rounded),
              color: const Color(0xD25B5B5B),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
          ),
        ],
        title: Text(
          'HealthChain',
          style: CustomTextStyle.titleStyle.copyWith(
            color: AppColors.primaryColor,
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: page,
        height: 60.0,
        items: <Widget>[
          Image.asset('assets/icons/accueil.png', width: 25.w, height: 25.h),
          Image.asset('assets/icons/document.png', width: 25.w, height: 25.h),
          Image.asset('assets/icons/calendrier.png', width: 25.w, height: 25.h),
          Image.asset('assets/icons/bulle.png', width: 25.w, height: 25.h),
          Image.asset('assets/icons/utilisateur.png',
              width: 25.w, height: 25.h),
        ],
        color: AppColors.primaryColor,
        buttonBackgroundColor: AppColors.primaryColor,
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      body: _pagesAll[page],
    );
  }
}
