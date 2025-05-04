import 'dart:async';
import 'dart:ui';
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
  final bool isVideoCall;

  const CallScreen({
    Key? key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.isCaller = false,
    this.isVideoCall = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Logger logger = Logger();
  bool _isCallAccepted = false;
  Timer? _timeoutTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOn = true;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    if (!widget.isCaller) {
      setState(() {
        _isCallAccepted = true;
      });
      _startCallDurationTimer();
    } else {
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
        _startCallDurationTimer();
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
          NotificationService().cancelAllNotifications();
          logger.i('Call rejected for callID: ${widget.callID}');
        }
      }
    });
  }

  void _startCallDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = _callDuration + const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            _isCallAccepted
                ? widget.isVideoCall
                    ? _buildVideoCallBackground()
                    : _buildAudioCallBackground()
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Waiting for recipient to accept...'),
                      ],
                    ),
                  ),

            // ZEGOCLOUD Call UI (for video calls when accepted)
            if (_isCallAccepted && widget.isVideoCall)
              ZegoUIKitPrebuiltCall(
                appID: 94379796,
                appSign:
                    "3f6903ba3536aa80793be481a29e73f56c70d891c11adc98cc981b62c204c413",
                userID: widget.userID,
                userName: widget.userName,
                callID: widget.callID,
                config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
                onDispose: () {
                  logger.i('ZegoUIKitPrebuiltCall disposed');
                },
              ),

            // UI Elements
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row (Avatar for Audio Call, Name and Timer for Video Call)
                if (_isCallAccepted)
                  widget.isVideoCall
                      ? Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade300,
                                  // Replace with actual recipient image if available
                                  child: const Icon(Icons.person,
                                      size: 40, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatDuration(_callDuration),
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black54),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade300,
                            // Replace with actual caller image if available
                            child: const Icon(Icons.person,
                                size: 50, color: Colors.white),
                          ),
                        ),

                // Spacer for Audio Call
                if (_isCallAccepted && !widget.isVideoCall)
                  Expanded(
                    child: Center(
                      child: Text(
                        _formatDuration(_callDuration),
                        style: const TextStyle(
                            fontSize: 24, color: Colors.black54),
                      ),
                    ),
                  ),

                // Bottom Buttons and Swipe Back Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left Button (Mute for Audio, Camera Toggle for Video)
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                if (widget.isVideoCall) {
                                  _isCameraOn = !_isCameraOn;
                                } else {
                                  _isMuted = !_isMuted;
                                }
                              });
                            },
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              widget.isVideoCall
                                  ? (_isCameraOn
                                      ? Icons.videocam
                                      : Icons.videocam_off)
                                  : (_isMuted ? Icons.mic_off : Icons.mic),
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Center Button (End Call)
                          FloatingActionButton(
                            onPressed: () {
                              final socketService =
                                  Provider.of<WebSocketService>(context,
                                      listen: false);
                              socketService.emitCallEvent('reject_call', {
                                'callId': widget.callID,
                                'userId': widget.userID,
                              });
                              _timeoutTimer?.cancel();
                              _durationTimer?.cancel();
                              Navigator.of(context).pop();
                              NotificationService().cancelAllNotifications();
                              logger
                                  .i('Call ended for callID: ${widget.callID}');
                            },
                            backgroundColor: Colors.red,
                            child:
                                const Icon(Icons.call_end, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          // Right Button (Speaker for Both)
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _isSpeakerOn = !_isSpeakerOn;
                              });
                            },
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.grey),
                          SizedBox(width: 5),
                          Text(
                            'Swipe back to menu',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCallBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder for blurred background image (replace with actual image if available)
        Container(
          color: Colors.grey.shade200,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCallBackground() {
    return Container(
      color: Colors.white,
      // Replace with actual caller image if available
      child: const Center(
        child: Icon(Icons.person, size: 200, color: Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    socketService.socket?.off('call_accepted');
    socketService.socket?.off('call_rejected');
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
