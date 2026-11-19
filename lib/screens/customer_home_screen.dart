import 'package:flutter/material.dart';
import '../app_role.dart';
import '../notifications.dart';
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
      appBar: AppBar(
        title: const Text('Product Enquiry Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch role',
            onPressed: _switchRole,
          ),
        ],
      ),
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
                MaterialPageRoute(
                    builder: (_) => const CustomerEnquiryScreen()),
              ),
              icon: const Icon(Icons.photo_camera),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Ask about a product',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            // Live push status — if a reply push ever goes missing,
            // this line says on the phone itself where it got stuck.
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
