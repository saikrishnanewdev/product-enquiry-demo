import 'package:flutter/material.dart';
import '../app_role.dart';
import 'customer_home_screen.dart';
import 'role_gate.dart';

/// First-run screen: "one app, choose role once".
///
/// The phone remembers the choice, so from then on the app opens
/// straight into that portal — the owner never sees the customer
/// side, and customers never see the owner side.
class RolePickScreen extends StatelessWidget {
  const RolePickScreen({super.key});

  Future<void> _pick(BuildContext context, String role) async {
    await AppRole.setRole(role);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == AppRole.owner
            ? const OwnerGate()
            : const CustomerHomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Who is using this phone?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick once — the app remembers and opens straight into that side from then on.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _pick(context, AppRole.customer),
              icon: const Icon(Icons.person),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child:
                    Text('I am a Customer', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pick(context, AppRole.owner),
              icon: const Icon(Icons.business),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('I am the Business Owner',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
