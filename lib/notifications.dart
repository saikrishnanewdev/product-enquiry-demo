import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// How it works:
/// - The phone's FCM token is saved in the Supabase `device_tokens`
///   table (role 'owner' or 'customer', plus the enquiry id for customers).
/// - The Supabase Edge Function `send-push` watches for new enquiries
///   and messages (via Database Webhooks) and sends a push to the
///   right tokens through FCM.
/// - If the app is closed, Android shows the push automatically.
/// - If the app is open, we show it with flutter_local_notifications.
///
/// This only works once `google-services.json` is in android/app/
/// (Sai creates the Firebase project and sends the file).
/// If Firebase fails to start, the app still runs — only push is off.
class PushNotifications {
  static final _local = FlutterLocalNotificationsPlugin();
  static String? _lastRole;
  static String? _lastEnquiryId;
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _local.initialize(settings);

      // Background handler: shows the push when the app is closed.
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Permission (Android 13+ asks the user once).
      await FirebaseMessaging.instance.requestPermission();

      // Foreground messages: show them as a local notification.
      FirebaseMessaging.onMessage.listen(_showForeground);

      // If the token changes, save the new one with the same role.
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveToken());

      _ready = true;
    } catch (e) {
      // Push stays off, the rest of the app keeps working.
      // ignore: avoid_print
      print('Push notifications unavailable: $e');
    }
  }

  /// Call after the user picks a role. Owner phones get every new
  /// enquiry; customer phones get replies to their own enquiry only.
  static Future<void> registerToken({
    required String role,
    String? enquiryId,
  }) async {
    _lastRole = role;
    _lastEnquiryId = enquiryId;
    await _saveToken();
  }

  static Future<void> _saveToken() async {
    if (!_ready || _lastRole == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'role': _lastRole,
          'enquiry_id': _lastEnquiryId,
          'token': token,
        },
        onConflict: 'token',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Could not save push token: $e');
    }
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'enquiries',
        'Enquiries',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}

/// Runs in a separate isolate when a push arrives and the app is closed.
/// Must be a top-level function. Kept small on purpose: just show it.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(settings);
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'enquiries',
      'Enquiries',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  await local.show(
    notification.hashCode,
    notification.title,
    notification.body,
    details,
  );
}
