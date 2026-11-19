import 'package:flutter/material.dart';
import '../config.dart';
import '../notifications.dart';
import 'customer_enquiry_screen.dart';
import 'owner_list_screen.dart';

/// First screen: pick a role. Demo simplicity — both portals live in
/// one install, so Sai can demo the customer side on one phone and the
/// owner side on another.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ask for notification permission once the screen is visible:
    // asking before the app draws can be silently dropped by Android.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotifications.askPermissionAndRegister();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Enquiry Demo')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.settings, size: 48, color: Colors.teal),
              SizedBox(height: 16),
              Text(
                'Setup needed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Open lib/config.dart and fill in your Supabase URL and anon key, '
                'then run supabase-setup.sql in your Supabase SQL Editor. '
                'See README.md for the steps.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product Enquiry Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.storefront, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Ask about a product',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a photo and ask if it is available. The shop replies right inside the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerEnquiryScreen()),
              ),
              icon: const Icon(Icons.person),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('I am a Customer', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerListScreen()),
              ),
              icon: const Icon(Icons.business),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('I am the Business Owner', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
            // Live push status — if a push ever goes missing, this line
            // says on the phone itself where it got stuck.
            ValueListenableBuilder<String>(
              valueListenable: PushNotifications.statusNotifier,
              builder: (context, status, _) => Text(
                'Notifications: $status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
