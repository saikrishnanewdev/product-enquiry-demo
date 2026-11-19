import 'package:flutter/material.dart';
import '../app_role.dart';
import '../notifications.dart';
import '../theme.dart';
import 'customer_enquiry_screen.dart';
import 'my_enquiries_screen.dart';
import 'role_gate.dart';

/// CUSTOMER portal home: ask about a product, or find past queries.
///
/// Shown when this phone picked the customer role. The owner side
/// is never reachable from here — switching role needs the swap
/// icon in the AppBar (with a confirm step).
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

  Future<void> _switchRole() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch role?'),
        content: const Text(
          'This phone will forget it is a customer and ask again '
          'whether it is the shop owner or a customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AppRole.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar(
        title: const Text('Product Enquiry Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch role',
            onPressed: _switchRole,
          ),
        ],
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
