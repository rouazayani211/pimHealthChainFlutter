import 'package:HealthChain/config/app_config.dart';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

class WebSocketService {
  IO.Socket? _socket;
  final AuthProvider _authProvider;
  final String _baseUrl = AppConfig.apiBaseUrl;
  final Logger logger = Logger();
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onMessageSent;
  Function(String)? _onMessageError;
  bool _isConnecting = false;

  WebSocketService(this._authProvider) {
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    if (_isConnecting) return;
    _isConnecting = true;

    final token = await _authProvider.getValidToken();
    if (token == null) {
      logger.e('No valid token for WebSocket connection');
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
        logger.i('WebSocket connected');
        _isConnecting = false;
      });

      _socket!.onDisconnect((_) {
        logger.i('WebSocket disconnected');
        _isConnecting = false;
        Future.delayed(Duration(seconds: 5), () {
          if (!_authProvider.isAuthenticated) return;
          _initializeSocket();
        });
      });

      _socket!.onConnectError((data) {
        logger.e('WebSocket connect error: $data');
        _isConnecting = false;
        Future.delayed(Duration(seconds: 5), () {
          if (!_authProvider.isAuthenticated) return;
          _initializeSocket();
        });
      });

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

      _socket!.connect();
    } catch (e) {
      logger.e('WebSocket initialization error: $e');
      _isConnecting = false;
      Future.delayed(Duration(seconds: 5), () {
        if (!_authProvider.isAuthenticated) return;
        _initializeSocket();
      });
    }
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  void onMessageSent(Function(Map<String, dynamic>) callback) {
    _onMessageSent = callback;
  }

  void onMessageError(Function(String) callback) {
    _onMessageError = callback;
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
      _initializeSocket();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnecting = false;
    logger.i('WebSocket disconnected manually');
  }
}
