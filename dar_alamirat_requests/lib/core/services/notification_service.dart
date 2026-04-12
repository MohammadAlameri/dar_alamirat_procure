import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level function to handle background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dar_alamirat_notifications',
    'Dar Alamirat Notifications',
    description: 'Notifications for purchase and expense request updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Callback for when user taps a notification
  Function(String? requestId, String? requestType)? onNotificationTap;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Set foreground notification presentation options (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification when terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Save FCM token to Supabase for current user
  Future<void> saveTokenToDatabase() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('[FCM] Saving token for user $userId: ${token.substring(0, 20)}...');

      // Upsert the token (update if exists, insert if not)
      await Supabase.instance.client.from('fcm_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );

      debugPrint('[FCM] Token saved successfully');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed, saving new token...');
        await Supabase.instance.client.from('fcm_tokens').upsert(
          {
            'user_id': userId,
            'token': newToken,
            'device_type': Platform.isIOS ? 'ios' : 'android',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,token',
        );
      });
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Remove FCM token from database on logout
  Future<void> removeTokenFromDatabase() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('token', token);

      debugPrint('[FCM] Token removed from database');
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }

  /// Send notification to specific users via Supabase Edge Function
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String? requestId,
    String? requestType,
  }) async {
    try {
      debugPrint('[FCM] Sending notification to users: $userIds');

      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'user_ids': userIds,
          'title': title,
          'body': body,
          'data': {
            'request_id': requestId ?? '',
            'request_type': requestType ?? '',
          },
        },
      );

      debugPrint('[FCM] Notification sent successfully');
    } catch (e) {
      debugPrint('[FCM] Error sending notification: $e');
    }
  }

  /// Handle foreground messages — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap when app is in background/terminated
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');

    final requestId = message.data['request_id'] as String?;
    final requestType = message.data['request_type'] as String?;

    if (onNotificationTap != null) {
      onNotificationTap!(requestId, requestType);
    }
  }

  /// Handle local notification response (when user taps foreground notification)
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final requestId = data['request_id'] as String?;
        final requestType = data['request_type'] as String?;

        if (onNotificationTap != null) {
          onNotificationTap!(requestId, requestType);
        }
      } catch (e) {
        debugPrint('[FCM] Error parsing notification payload: $e');
      }
    }
  }
}
