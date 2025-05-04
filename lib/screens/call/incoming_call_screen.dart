import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/services/socket_service.dart';
import 'package:HealthChain/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callID;
  final String callerID;
  final String callerName;

  const IncomingCallScreen({
    Key? key,
    required this.callID,
    required this.callerID,
    required this.callerName,
  }) : super(key: key);

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final Logger logger = Logger();
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  @override
  void initState() {
    super.initState();
    // Play ringtone when the screen is displayed
    _ringtonePlayer.play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
    );
  }

  Future<bool> _requestCallPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.camera,
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
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      logger.w('Camera permission denied');
      allGranted = false;
    }

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please grant microphone, camera, and Bluetooth permissions to accept the call')),
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
      'callId': widget.callID,
      'callerId': widget.callerID,
      'recipientId': userId,
    });
    // Stop the ringtone
    _ringtonePlayer.stop();
    NotificationService().cancelAllNotifications();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          callID: widget.callID,
          userID: userId,
          userName: widget.callerName,
          isCaller: false,
          isVideoCall: false, // Adjust based on callType if needed
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
      'callId': widget.callID,
      'userId': userId,
    });
    // Stop the ringtone
    _ringtonePlayer.stop();
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
              'Incoming Call from ${widget.callerName}',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
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

  @override
  void dispose() {
    // Stop the ringtone when the screen is disposed
    _ringtonePlayer.stop();
    super.dispose();
  }
}
