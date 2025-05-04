import 'dart:async';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/services/socket_service.dart';
import 'package:HealthChain/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:logger/logger.dart';

class CallScreen extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isCaller;

  const CallScreen({
    Key? key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.isCaller = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Logger logger = Logger();
  bool _isCallAccepted = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    if (!widget.isCaller) {
      setState(() {
        _isCallAccepted = true; // Callee joins immediately after accepting
      });
    } else {
      // Set a timeout for the caller to reject the call if no response
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!_isCallAccepted) {
          logger.i('Call timeout for callID: ${widget.callID}, rejecting call');
          socketService.emitCallEvent('reject_call', {
            'callId': widget.callID,
            'userId': widget.userID,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Call timed out: No response from recipient')),
            );
            Navigator.of(context).pop();
          }
          // Cancel the notification
          NotificationService().cancelAllNotifications();
        }
      });
    }

    socketService.socket?.on('call_accepted', (data) {
      if (data['callId'] == widget.callID) {
        setState(() {
          _isCallAccepted = true;
        });
        _timeoutTimer?.cancel();
        logger.i('Call accepted for callID: ${widget.callID}');
      }
    });

    socketService.socket?.on('call_rejected', (data) {
      if (data['callId'] == widget.callID) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call rejected by recipient')),
          );
          _timeoutTimer?.cancel();
          Navigator.of(context).pop();
          // Cancel the notification
          NotificationService().cancelAllNotifications();
          logger.i('Call rejected for callID: ${widget.callID}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            widget.isCaller && !_isCallAccepted
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Waiting for recipient to accept...'),
                      ],
                    ),
                  )
                : ZegoUIKitPrebuiltCall(
                    appID: 94379796,
                    appSign:
                        "3f6903ba3536aa80793be481a29e73f56c70d891c11adc98cc981b62c204c413",
                    userID: widget.userID,
                    userName: widget.userName,
                    callID: widget.callID,
                    config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
                    onDispose: () {
                      logger.i('ZegoUIKitPrebuiltCall disposed');
                    },
                  ),
            Positioned(
              top: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  final socketService =
                      Provider.of<WebSocketService>(context, listen: false);
                  socketService.emitCallEvent('reject_call', {
                    'callId': widget.callID,
                    'userId': widget.userID,
                  });
                  _timeoutTimer?.cancel();
                  Navigator.of(context).pop();
                  // Cancel the notification
                  NotificationService().cancelAllNotifications();
                  logger.i('Call ended for callID: ${widget.callID}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('End Call'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    socketService.socket?.off('call_accepted');
    socketService.socket?.off('call_rejected');
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
