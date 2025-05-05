import 'package:HealthChain/screens/call/incoming_call_screen.dart';
import 'package:HealthChain/screens/call/landing_page.dart';
import 'package:HealthChain/screens/call/call_screen.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/bottom_nav_bar.dart';
import '../screens/home_screen.dart';
import '../screens/messages/conversation_list_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/messages/direct_conversation_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/file_upload_screen.dart';
import '../screens/rdv_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notification_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => SignUpScreen());
      case '/forgotPassword':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case '/bottomNavBar':
        return MaterialPageRoute(builder: (_) => BottomNavBar());
      case '/home':
        return MaterialPageRoute(builder: (_) => BottomNavBar());
      case '/conversations':
      case '/messages':
        return MaterialPageRoute(builder: (_) => ConversationListScreen());
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('recipientId') ||
            !args.containsKey('recipientName')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: Missing chat parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            recipientId: args['recipientId'],
            recipientName: args['recipientName'],
          ),
        );
      case '/direct-chat':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('userId')) {
          // Hardcoded ID for testing
          return MaterialPageRoute(
            builder: (_) => const DirectConversationScreen(
              userId: '6817e404d2f32269d6c6c59d',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => DirectConversationScreen(
            userId: args['userId'],
          ),
        );
      case '/documents':
        return MaterialPageRoute(builder: (_) => DocumentsScreen());
      case '/file-upload':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('category')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: Missing file upload parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => FileUploadScreen(
            category: args['category'],
          ),
        );
      case '/rdv':
        return MaterialPageRoute(builder: (_) => RdvScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => NotificationScreen());
      case '/landing':
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case '/call':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('callID') ||
            !args.containsKey('userID') ||
            !args.containsKey('userName')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: Missing call parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CallScreen(
            callID: args['callID'],
            userID: args['userID'],
            userName: args['userName'],
            isCaller: args['isCaller'] ?? false,
            isVideoCall: args['isVideoCall'] ?? false,
          ),
        );
      case '/incoming-call':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('callID') ||
            !args.containsKey('callerID') ||
            !args.containsKey('callerName')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                  child: Text('Error: Missing incoming call parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callID: args['callID'],
            callerID: args['callerID'],
            callerName: args['callerName'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
