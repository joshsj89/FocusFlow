import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Wraps Firebase Cloud Messaging: permission, token sync to Firestore, and
/// in-app banner display for foreground messages.
class NotificationService {
  NotificationService._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static String? _currentToken;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Local notifications (badge earned, etc.)
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _currentToken = await _messaging.getToken();
    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _writeToken(uid, token);
    });

    // Sync token whenever a user signs in 
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) syncTokenForUser(user.uid);
    });
  }

  /// Shows a local push-style notification — used when a badge is earned.
  static Future<void> showBadgeNotification({
    required String title,
    required String body,
  }) async {
    await _local.show(
      title.hashCode.abs() % 10000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focusflow_badges',
          'Badge Notifications',
          channelDescription: 'Shown when you earn a new badge',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Persist this device's FCM token to the user's Firestore doc.
  static Future<void> syncTokenForUser(String uid) async {
    final token = _currentToken ?? await _messaging.getToken();
    if (token == null) return;
    _currentToken = token;
    await _writeToken(uid, token);
  }

  static Future<void> clearTokenForUser(String uid) async {
    final token = _currentToken;
    if (token != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('clearTokenForUser: $e');
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  static Future<void> _writeToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final title = notification.title;
    final body = notification.body;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (body != null && body.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: title != null ? 4 : 0),
                child: Text(body),
              ),
          ],
        ),
      ),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification opened app: ${message.data}');
    }
  }
}
