import 'package:flutter/material.dart';
import '../app_role.dart';
import '../theme.dart';
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
                children: [
                  const Icon(Icons.storefront, size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Who is using this phone?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick once — the app remembers and opens straight into that side from then on.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              icon: Icons.person,
              label: 'I am a Customer',
              onPressed: () => _pick(context, AppRole.customer),
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
