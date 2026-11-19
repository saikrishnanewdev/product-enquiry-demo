import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'notifications.dart';
import 'screens/role_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    // Closed-app push notifications (needs google-services.json).
    await PushNotifications.init();
  }

  runApp(const EnquiryDemoApp());
}

class EnquiryDemoApp extends StatelessWidget {
  const EnquiryDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Enquiry Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const RoleGate(),
    );
  }
}

/// Shortcut to the Supabase client. Only use after [AppConfig.isConfigured].
SupabaseClient get supabase => Supabase.instance.client;
