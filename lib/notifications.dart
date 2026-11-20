import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  /// Live status shown on the home screen so a missing push can be
  /// diagnosed on the phone itself instead of guessing.
  static final ValueNotifier<String> statusNotifier =
      ValueNotifier<String>('starting…');
  static String get status => statusNotifier.value;

  static Future<void> init() async {
    // No Firebase web config exists, and FCM is Android-only here:
    // on web push is simply off (the home screen says so).
    if (kIsWeb) {
      statusNotifier.value = 'not available on web — open the app to see replies';
      return;
    }
    try {
      await Firebase.initializeApp();
    } catch (e) {
      statusNotifier.value = 'Firebase failed to start: $e';
      // ignore: avoid_print
      print('Push notifications unavailable: $e');
      return;
    }
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _local.initialize(settings);

      // Background handler: shows the push when the app is closed.
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Foreground messages: show them as a local notification.
      FirebaseMessaging.onMessage.listen(_showForeground);

      // If the token changes, save the new one with the same role.
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveToken());

      _ready = true;
      statusNotifier.value = 'ready — waiting for permission';
    } catch (e) {
      statusNotifier.value = 'setup failed: $e';
      // ignore: avoid_print
      print('Push notifications unavailable: $e');
    }
  }

  /// Ask for notification permission and save this phone's push token.
  /// Call this AFTER the first screen is visible: asking before the
  /// app has drawn can be silently dropped by Android, which is why
  /// the permission prompt never appeared in earlier builds.
  static Future<void> askPermissionAndRegister() async {
    if (!_ready) return;
    try {
      // Both calls ask for the Android 13+ notification permission;
      // whichever shows the prompt is enough.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await FirebaseMessaging.instance.requestPermission();
      if (_lastRole == null) {
        statusNotifier.value =
            'permission done — open Customer or Owner to finish registering';
        return;
      }
      statusNotifier.value = 'permission done — saving token…';
      await _saveToken();
    } catch (e) {
      statusNotifier.value = 'permission request failed: $e';
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
      if (token == null) {
        statusNotifier.value =
            'no token from Firebase (Play services missing?)';
        return;
      }
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'role': _lastRole,
          'enquiry_id': _lastEnquiryId,
          'token': token,
        },
        onConflict: 'token',
      );
      statusNotifier.value = 'ON — this phone is registered for pushes';
    } catch (e) {
      statusNotifier.value = 'could not save token: $e';
      // ignore: avoid_print
      print('Could not save push token: $e');
    }
  }

  /// Title/body of a push. The server sends DATA-ONLY messages
  /// (title/body live in `data`), so read those first; fall back to
  /// the notification payload if one is ever present.
  static String _titleOf(RemoteMessage message) =>
      message.data['title'] as String? ??
      message.notification?.title ??
      'Product Enquiry Demo';

  static String _bodyOf(RemoteMessage message) =>
      message.data['body'] as String? ?? message.notification?.body ?? '';

  static Future<void> _showForeground(RemoteMessage message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'enquiries',
        'Enquiries',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _local.show(
      message.hashCode,
      _titleOf(message),
      _bodyOf(message),
      details,
    );
  }
}

/// Runs in a separate isolate when a push arrives and the app is closed.
/// Must be a top-level function. Kept small on purpose: just show it.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
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
    message.hashCode,
    PushNotifications._titleOf(message),
    PushNotifications._bodyOf(message),
    details,
  );
}
