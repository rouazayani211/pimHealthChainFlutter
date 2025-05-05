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
      child: const HealthChainApp(),
    ),
  );
}

class HealthChainApp extends StatefulWidget {
  const HealthChainApp({super.key});

  @override
  State<HealthChainApp> createState() => _HealthChainAppState();
}

class _HealthChainAppState extends State<HealthChainApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitializing = true;
  String _initialRoute = '/login';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    
    // Set WebSocketService in AuthProvider
    authProvider.setWebSocketService(socketService);
    
    // Set navigator key for WebSocketService
    socketService.setNavigatorKey(_navigatorKey);
    
    // Initialize auth state (check for cached user)
    await authProvider.initializeAuth();
    
    setState(() {
      _initialRoute = authProvider.isAuthenticated ? '/bottomNavBar' : '/login';
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If still initializing, show a loading screen
    if (_isInitializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF45B3CB),
            ),
          ),
        ),
      );
    }
    
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
          initialRoute: _initialRoute,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
