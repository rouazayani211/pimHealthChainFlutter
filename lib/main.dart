import 'package:HealthChain/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import './routes/app_router.dart';
import './providers/message_provider.dart';
import './providers/auth_provider.dart';
import './services/api_service.dart';
import './config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final rememberMe = prefs.getBool('rememberMe') ?? false;
  final initialRoute = (isLoggedIn && rememberMe) ? '/bottomNavBar' : '/login';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(
          create: (_) => ApiService(),
        ),
        Provider(
          create: (context) => WebSocketService(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MessageProvider(
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<ApiService>(context, listen: false),
            Provider.of<WebSocketService>(context, listen: false),
          ),
        ),
      ],
      child: HealthChainApp(initialRoute: initialRoute),
    ),
  );
}

class HealthChainApp extends StatelessWidget {
  final String initialRoute;

  const HealthChainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HealthChain',
          theme: ThemeData(
            primaryColor: const Color(0xFF45B3CB),
            scaffoldBackgroundColor: Colors.white,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF45B3CB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF45B3CB)),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF45B3CB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF45B3CB)),
              ),
            ),
          ),
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
