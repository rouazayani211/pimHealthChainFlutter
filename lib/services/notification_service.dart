import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            // Parse the payload as a Map
            final payload = response.payload as String;
            final data = Map<String, dynamic>.from(Map.fromEntries(
              payload.split('&').map((e) {
                final parts = e.split('=');
                return MapEntry(parts[0], parts[1]);
              }),
            ));
            navigatorKey.currentState?.pushNamed(
              '/incoming-call',
              arguments: {
                'callID': data['callId'],
                'callerID': data['callerId'],
                'callerName': data['callerName'],
              },
            );
          }
        },
      );

      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> showIncomingCallNotification({
    required String callId,
    required String callerId,
    required String callerName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        0, // Notification ID
        'Incoming Call',
        'Call from $callerName',
        platformDetails,
        payload: 'callId=$callId&callerId=$callerId&callerName=$callerName',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }
}
