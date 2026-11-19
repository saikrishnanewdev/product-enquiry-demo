import 'package:flutter/material.dart';
import '../app_role.dart';
import '../config.dart';
import '../owner_pin.dart';
import 'customer_home_screen.dart';
import 'owner_list_screen.dart';
import 'owner_pin_screen.dart';
import 'role_pick_screen.dart';

/// Root screen: reads the saved role and opens the right portal.
///
/// - No role saved yet -> [RolePickScreen] (choose once).
/// - Customer -> [CustomerHomeScreen].
/// - Owner -> [OwnerGate] (PIN, then the enquiries list).
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

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

    return FutureBuilder<String?>(
      future: AppRole.getRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return switch (snapshot.data) {
          AppRole.customer => const CustomerHomeScreen(),
          AppRole.owner => const OwnerGate(),
          _ => const RolePickScreen(),
        };
      },
    );
  }
}

/// Owner entry: asks for the 4-digit PIN first, then shows the
/// enquiries list. If the user backs out of the PIN screen, the
/// saved role is cleared so the picker shows again.
class OwnerGate extends StatefulWidget {
  const OwnerGate({super.key});

  @override
  State<OwnerGate> createState() => _OwnerGateState();
}

class _OwnerGateState extends State<OwnerGate> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPin());
  }

  Future<void> _askPin() async {
    final navigator = Navigator.of(context);
    final hasPin = await OwnerPin.hasPin();
    final ok = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerPinScreen(
          mode: hasPin ? OwnerPinMode.verify : OwnerPinMode.set,
        ),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      setState(() => _unlocked = true);
    } else {
      await AppRole.clear();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleGate()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const OwnerListScreen();
  }
}
