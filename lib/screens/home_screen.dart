import 'package:HealthChain/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../utils/themes.dart';
import '../models/doctor.dart';
import '../config/app_config.dart';
import 'package:logger/logger.dart';
import 'messages/direct_conversation_screen.dart'; // Import the direct conversation screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final Logger logger = Logger();
  
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }
  
  Future<void> _loadDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final doctors = await _apiService.getDoctors();
      
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
      
      logger.i('Loaded ${doctors.length} doctors');
    } catch (e) {
      logger.e('Error loading doctors: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final Logger logger = Logger();
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              size: 40.sp,
              color: AppColors.primaryColor,
            ),
            SizedBox(height: 20.h),
            Text(
              'Are you sure to log out of your account?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm logout
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    // Proceed with logout if confirmed
    if (confirmLogout == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        logger.i('Logged out: Cleared credentials via AuthProvider');
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

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              
              // Header with user image, name and notification icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // User profile image
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        child: Container(
                          width: 46.w,
                          height: 46.h,
                          margin: EdgeInsets.only(right: 12.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              width: 2.w,
                            ),
                          ),
                          child: ClipOval(
                            child: user?.id != null 
                                ? Image.network(
                                    '${AppConfig.apiBaseUrl}/users/image/${user!.id}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const CircleAvatar(
                                        backgroundColor: Colors.blueGrey,
                                        child: Icon(Icons.person, color: Colors.white),
                                      );
                                    },
                                  )
                                : const CircleAvatar(
                                    backgroundColor: Colors.blueGrey,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      // User name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            user?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Notification icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: Colors.black,
                      iconSize: 26.sp,
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Search bar
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search Medical',
                          hintStyle: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(4.r),
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Medical services banner
              Container(
                width: double.infinity,
                height: 180.h,
                decoration: BoxDecoration(
                  color: Color(0xFFD2EAF0), // Light blue background
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20.w,
                      top: 30.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get the Best',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF489A9F), // Teal-like color
                            ),
                          ),
                          Text(
                            'Medical Services',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF489A9F), // Teal-like color
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: 180.w,
                            child: Text(
                              'We provide best quality medical services without further cost',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 160.h,
                        child: Image.asset(
                          'assets/healththehain_logo.png', // Use existing logo instead of doctor.png
                          height: 160.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Doctors section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Doctors',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to doctors list screen
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Doctors list
              _buildDoctorsList(),
              
              SizedBox(height: 24.h),
              
              // Upcoming appointments section
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Appointment card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF516E79), // Dark teal/blue color
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    // Date container
                    Container(
                      width: 100.w,
                      height: 110.h,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Color(0xFF5CB0C9), // Lighter blue accent
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          bottomLeft: Radius.circular(16.r),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '12',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tue',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Appointment details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '09:30 AM',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Dr. Mim Ankhtr',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Depression',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDoctorsList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            children: [
              Text(
                'Failed to load doctors',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: _loadDoctors,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: Text(
            'No doctors available at the moment',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
    );
  }
  
  Widget _buildDoctorCard(Doctor doctor) {
    // Use the dedicated doctor image endpoint with IP address instead of localhost
    final String photoUrl = '${AppConfig.apiBaseUrl}/users/doctor/image/${doctor.id}';
    logger.i('Loading doctor image from: $photoUrl');
    
    return Container(
      width: 160.w,
      height: 190.h, // Fix height to prevent overflow
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use mainAxisSize.min to prevent overflow
        children: [
          SizedBox(height: 12.h), // Reduce spacing
          ClipOval(
            child: Container(
              width: 90.w,
              height: 90.h,
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  logger.e('Error loading doctor image: $error');
                  // Try a hardcoded doctor image for testing
                  if (doctor.id == "6817e4e1d2f32269d6c6c5a3") {
                    return Image.network(
                      '${AppConfig.apiBaseUrl}/users/doctor/image/6817e4e1d2f32269d6c6c5a3',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          radius: 45.r,
                          backgroundColor: Colors.blueGrey[100],
                          child: Icon(
                            Icons.person,
                            size: 40.sp,
                            color: Colors.blueGrey[700],
                          ),
                        );
                      },
                    );
                  }
                  return CircleAvatar(
                    radius: 45.r,
                    backgroundColor: Colors.blueGrey[100],
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: Colors.blueGrey[700],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8.h), // Less space
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              doctor.name,
              style: TextStyle(
                fontSize: 14.sp, // Smaller font
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 2.h), // Minimal spacing
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              doctor.specialization ?? 'General Doctor',
              style: TextStyle(
                fontSize: 11.sp, // Smaller font
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 8.h), // Less space
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Book Now button
              Container(
                height: 26.h, // Smaller height
                width: 78.w, // Smaller width
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 11.sp, // Smaller font
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              // Chat button
              InkWell(
                onTap: () {
                  // Use the special conversation endpoint with the hardcoded ID for testing
                  final hardcodedUserId = "6817e404d2f32269d6c6c59d";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectConversationScreen(
                        userId: hardcodedUserId,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 26.h, // Smaller height
                  width: 32.w, // Smaller width
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chat,
                      size: 16.sp,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
