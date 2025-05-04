import 'package:HealthChain/config/app_config.dart';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../services/notification_service.dart';

class WebSocketService {
  IO.Socket? _socket;
  final AuthProvider _authProvider;
  final String _baseUrl = AppConfig.apiBaseUrl;
  final Logger logger = Logger();
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onMessageSent;
  Function(String)? _onMessageError;
  bool _isConnecting = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  WebSocketService(this._authProvider);

  IO.Socket? get socket => _socket;

  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    logger.i('Navigator key set for WebSocketService');
    NotificationService().initialize(navigatorKey);
  }

  Future<void> initializeSocket() async {
    if (_isConnecting) {
      logger.i('Already connecting, skipping initialization');
      return;
    }
    _isConnecting = true;
    _reconnectAttempts = 0;

    String? token = await _authProvider.getValidToken();
    if (token == null) {
      logger.w('No valid token, attempting to refresh');
      try {
        await _authProvider.refreshToken();
        token = await _authProvider.getValidToken();
      } catch (e) {
        logger.e('Failed to refresh token: $e');
        _isConnecting = false;
        return;
      }
    }
    if (token == null) {
      logger.e('No valid token after refresh attempt');
      _isConnecting = false;
      return;
    }

    try {
      _socket = IO.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
      });

      _socket!.onConnect((_) {
        logger
            .i('WebSocket connected for user ${_authProvider.currentUser?.id}');
        _isConnecting = false;
        _reconnectAttempts = 0;
        _setupEventListeners();
      });

      _socket!.onDisconnect((_) {
        logger.i(
            'WebSocket disconnected for user ${_authProvider.currentUser?.id}');
        _isConnecting = false;
        _reconnect();
      });

      _socket!.onConnectError((data) {
        logger.e(
            'WebSocket connect error for user ${_authProvider.currentUser?.id}: $data');
        _isConnecting = false;
        _reconnect();
      });

      _socket!.on('error', (data) {
        logger.e(
            'WebSocket error for user ${_authProvider.currentUser?.id}: $data');
        if (data.toString().contains('Authentication error') ||
            data.toString().contains('jwt expired')) {
          logger.w('Authentication error detected, refreshing token');
          _authProvider.refreshToken().then((_) {
            logger.i('Token refreshed, reconnecting');
            initializeSocket();
          }).catchError((e) {
            logger.e('Failed to refresh token: $e');
            _authProvider.logout();
          });
        }
      });

      _socket!.connect();
      logger.i(
          'WebSocket connection initiated for user ${_authProvider.currentUser?.id} with token: $token');
    } catch (e) {
      logger.e('WebSocket initialization error: $e');
      _isConnecting = false;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.e(
          'Max reconnect attempts reached for user ${_authProvider.currentUser?.id}, giving up');
      return;
    }
    _reconnectAttempts++;
    Future.delayed(Duration(seconds: 5 * _reconnectAttempts), () {
      if (!_authProvider.isAuthenticated) {
        logger.w('User not authenticated, aborting reconnect');
        return;
      }
      logger.i(
          'Attempting to reconnect WebSocket for user ${_authProvider.currentUser?.id} (Attempt $_reconnectAttempts/$_maxReconnectAttempts)');
      initializeSocket();
    });
  }

  void _setupEventListeners() {
    logger.i(
        'Setting up WebSocket event listeners for user ${_authProvider.currentUser?.id}');
    _socket!.on('newMessage', (data) {
      logger.i('New message received: $data');
      _onMessageReceived?.call(data);
    });

    _socket!.on('messageSent', (data) {
      logger.i('Message sent confirmation: $data');
      _onMessageSent?.call(data);
    });

    _socket!.on('messageError', (data) {
      logger.e('Message error: $data');
      _onMessageError?.call(data.toString());
    });

    _socket!.on('incoming_call', (data) {
      logger.i('Incoming call received: $data');
      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        logger.e('Cannot handle incoming call: User ID is null');
        return;
      }
      logger.i(
          'Comparing recipientId: ${data['recipientId']} with userId: $userId');
      if (data['recipientId'] == userId) {
        // Show local notification
        NotificationService().showIncomingCallNotification(
          callId: data['callId'],
          callerId: data['callerId'],
          callerName: data['callerName'],
        );

        // Play ringtone
        _ringtonePlayer.play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.glass,
          looping: true,
          volume: 1.0,
        );

        // Navigate to IncomingCallScreen
        logger.i(
            'Navigating to IncomingCallScreen for user $userId with callID: ${data['callId']}');
        if (_navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.pushNamed(
            '/incoming-call',
            arguments: {
              'callID': data['callId'],
              'callerID': data['callerId'],
              'callerName': data['callerName'],
            },
          );
        } else {
          logger.e('Cannot navigate: Navigator key is not set or invalid');
          if (_navigatorKey?.currentContext != null) {
            showDialog(
              context: _navigatorKey!.currentContext!,
              builder: (context) => AlertDialog(
                title: const Text('Incoming Call'),
                content: Text('Incoming call from ${data['callerName']}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _rejectCall(data['callId'], userId);
                    },
                    child: const Text('Reject'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigatorKey!.currentState!.pushNamed(
                        '/incoming-call',
                        arguments: {
                          'callID': data['callId'],
                          'callerID': data['callerId'],
                          'callerName': data['callerName'],
                        },
                      );
                    },
                    child: const Text('Accept'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        logger.w(
            'User ID mismatch: Expected ${data['recipientId']}, got $userId');
      }
    });

    // Handle call rejection by the recipient
    _socket!.on('call_rejected', (data) {
      logger.i('Call rejected: $data');
      final userId = _authProvider.currentUser?.id;
      if (userId == data['callerId']) {
        logger.i(
            'Call rejected by recipient for user $userId with callID: ${data['callId']}');
        if (_navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.pop(); // Pop the CallScreen
          ScaffoldMessenger.of(_navigatorKey!.currentContext!).showSnackBar(
            const SnackBar(content: Text('Call rejected by recipient')),
          );
        }
        // Stop ringtone and cancel notifications
        _ringtonePlayer.stop();
        NotificationService().cancelAllNotifications();
      }
    });

    // Handle call acceptance by the recipient
    _socket!.on('call_accepted', (data) {
      logger.i('Call accepted: $data');
      final userId = _authProvider.currentUser?.id;
      if (userId == data['callerId']) {
        logger.i(
            'Call accepted by recipient for user $userId with callID: ${data['callId']}');
        // Stop ringtone and cancel notifications
        _ringtonePlayer.stop();
        NotificationService().cancelAllNotifications();
      }
    });
  }

  void _rejectCall(String callId, String userId) {
    emitCallEvent('reject_call', {
      'callId': callId,
      'userId': userId,
    });
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
    _ensureConnection();
  }

  void onMessageSent(Function(Map<String, dynamic>) callback) {
    _onMessageSent = callback;
    _ensureConnection();
  }

  void onMessageError(Function(String) callback) {
    _onMessageError = callback;
    _ensureConnection();
  }

  void sendMessage(String recipientId, String content) {
    if (_socket?.connected ?? false) {
      logger.i('Sending message to $recipientId: $content');
      _socket!.emit('sendMessage', {
        'recipientId': recipientId,
        'content': content,
      });
    } else {
      logger.w('WebSocket not connected, attempting to reconnect');
      initializeSocket();
    }
  }

  void emitCallEvent(String event, Map<String, dynamic> data) {
    if (_socket?.connected ?? false) {
      logger.i('Emitting call event: $event with data: $data');
      _socket!.emit(event, data);
    } else {
      logger.w('WebSocket not connected for $event, attempting to reconnect');
      initializeSocket().then((_) {
        if (_socket?.connected ?? false) {
          logger.i('Reconnected, retrying $event');
          _socket!.emit(event, data);
        } else {
          logger.e('Failed to reconnect for $event');
          if (_navigatorKey?.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey!.currentContext!).showSnackBar(
              SnackBar(
                  content: Text('Failed to emit $event: Connection error')),
            );
          }
        }
      });
    }
  }

  void _ensureConnection() {
    if (_socket?.connected != true) {
      logger.w('WebSocket not connected, initializing connection');
      initializeSocket();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnecting = false;
    _navigatorKey = null;
    logger.i('WebSocket disconnected manually');
  }
}
