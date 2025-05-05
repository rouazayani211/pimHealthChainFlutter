import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 690));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                _buildHeader(),
                SizedBox(height: 16.h),
                Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildHealthMetricsSection(),
                SizedBox(height: 24.h),
                Text(
                  'Latest Report',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildReportItem(
                  icon: Icons.description,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.shade100,
                  title: 'General health',
                  fileCount: 5,
                ),
                SizedBox(height: 16.h),
                _buildReportItem(
                  icon: Icons.description, 
                  iconColor: Colors.purple,
                  iconBgColor: Colors.purple.shade100,
                  title: 'Diabetes',
                  fileCount: 8,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'DHIRAJ KHADKA',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildHealthMetricsSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade100,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '96',
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(
                          'bpm',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 140.w,
                height: 70.h,
                child: CustomPaint(
                  painter: HeartRateGraphPainter(),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(),
                        Icon(Icons.more_horiz, color: Colors.black),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Blood Group',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'A+',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.fitness_center, color: Colors.green),
                        Icon(Icons.more_horiz, color: Colors.black),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Weight',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '80',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required int fileCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: iconColor, size: 30.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$fileCount files',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                _navigateToFileUpload(title);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFileUpload(String category) async {
    final result = await Navigator.pushNamed(
      context,
      '/file-upload',
      arguments: {'category': category},
    );
    
    // If we got a result back (true), we successfully uploaded a file
    if (result == true) {
      // You could refresh the documents list here if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NFT created successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Custom painter for heart rate graph
class HeartRateGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    
    // Starting point
    path.moveTo(0, size.height * 0.7);
    
    // Draw the heartbeat pattern
    path.lineTo(size.width * 0.15, size.height * 0.65);
    path.lineTo(size.width * 0.3, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.1); // Peak
    path.lineTo(size.width * 0.5, size.height * 0.9); // Valley
    path.lineTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.4);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
