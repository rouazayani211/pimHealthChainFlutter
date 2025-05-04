import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/services/notification_service.dart';
import 'package:HealthChain/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callID;
  final String callerID;
  final String callerName;
  final Logger logger = Logger();

  IncomingCallScreen({
    Key? key,
    required this.callID,
    required this.callerID,
    required this.callerName,
  }) : super(key: key);

  Future<bool> _requestCallPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.bluetoothConnect,
    ].request();

    bool allGranted = true;
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      logger.w('Microphone permission denied');
      allGranted = false;
    }
    if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      logger.w('Bluetooth connect permission denied');
      allGranted = false;
    }

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please grant microphone and Bluetooth permissions to accept the call')),
      );
    }
    return allGranted;
  }

  void _acceptCall(BuildContext context) async {
    bool permissionsGranted = await _requestCallPermissions(context);
    if (!permissionsGranted) return;

    final socketService = Provider.of<WebSocketService>(context, listen: false);
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final userName =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
            'User';
    if (userId == null) {
      logger.w('Cannot accept call: User ID is null');
      return;
    }
    socketService.emitCallEvent('accept_call', {
      'callId': callID,
      'callerId': callerID,
      'recipientId': userId,
    });
    // Cancel the notification
    NotificationService().cancelAllNotifications();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          callID: callID,
          userID: userId,
          userName: userName,
          isCaller: false,
        ),
      ),
    );
  }

  void _rejectCall(BuildContext context) {
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) {
      logger.w('Cannot reject call: User ID is null');
      return;
    }
    socketService.emitCallEvent('reject_call', {
      'callId': callID,
      'userId': userId,
    });
    // Cancel the notification
    NotificationService().cancelAllNotifications();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Incoming Call from $callerName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptCall(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _rejectCall(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
