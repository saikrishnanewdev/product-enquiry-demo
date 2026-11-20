import 'package:flutter/material.dart';
import '../notifications.dart';
import '../theme.dart';
import 'customer_enquiry_screen.dart';
import 'my_enquiries_screen.dart';

/// CUSTOMER portal home: ask about a product, or find past queries.
///
/// Shown when this phone picked the customer role. The owner side
/// is never reachable from here — there is no role switcher in the
/// app; the role is set once and only reinstalling clears it.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
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
    return Scaffold(
      appBar: AppTheme.gradientAppBar(
        title: const Text('Product Enquiry Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Ask about a product',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send a photo and ask if it is available. The shop replies right inside the app.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.photo_camera,
                      size: 48, color: AppTheme.teal),
                  const SizedBox(height: 16),
                  GradientButton(
                    icon: Icons.photo_camera,
                    label: 'Ask about a product',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CustomerEnquiryScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MyEnquiriesScreen()),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child:
                          Text('My queries', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Live push status — if a reply push ever goes missing,
            // this line says on the phone itself where it got stuck.
            ValueListenableBuilder<String>(
              valueListenable: PushNotifications.statusNotifier,
              builder: (context, status, _) => Text(
                'Notifications: $status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
