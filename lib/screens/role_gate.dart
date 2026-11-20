import 'package:flutter/material.dart';
import '../app_role.dart';
import '../config.dart';
import '../main.dart';
import '../owner_pin.dart';
import '../theme.dart';
import 'customer_home_screen.dart';
import 'owner_change_password_screen.dart';
import 'owner_list_screen.dart';
import 'owner_login_screen.dart';
import 'owner_pin_screen.dart';
import 'welcome_screen.dart';

/// Root screen: reads the saved role and opens the right portal.
///
/// - No role saved yet -> [WelcomeScreen] (Get Started = customer;
///   the owner enters through the hidden logo tap).
/// - Customer -> [CustomerHomeScreen].
/// - Owner -> [OwnerGate] (PIN, then the enquiries list).
/// Phones that already saved a role open straight into their portal
/// — the welcome screen only ever shows on a fresh install.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return Scaffold(
        appBar: AppTheme.gradientAppBar(
          title: const Text('Product Enquiry Demo'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.settings, size: 48, color: AppTheme.navy),
              SizedBox(height: 16),
              Text(
                'Setup needed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.heading,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Open lib/config.dart and fill in your Supabase URL and anon key, '
                'then run supabase-setup.sql in your Supabase SQL Editor. '
                'See README.md for the steps.',
                style: TextStyle(fontSize: 16, color: AppTheme.body),
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
          _ => const WelcomeScreen(),
        };
      },
    );
  }
}

/// Owner entry: sign in, then the PIN, then the enquiries list.
///
/// 1. If there is no Supabase Auth session yet, the owner signs in
///    with email + password (checked on the server — this is what
///    stops anyone from claiming the owner side).
/// 2. A first sign-in with the demo password forces a password
///    change before entering.
/// 3. The 4-digit PIN is the quick unlock after that; the owner
///    stays signed in, so the password is not asked every time.
/// Backing out of any step forgets the role and shows the welcome screen.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterOwner());
  }

  Future<void> _backToPicker() async {
    await AppRole.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleGate()),
      (_) => false,
    );
  }

  Future<void> _enterOwner() async {
    final navigator = Navigator.of(context);
    // 1. Sign in if there is no session yet.
    if (supabase.auth.currentSession == null) {
      final signedIn = await navigator.push<bool>(
        MaterialPageRoute(builder: (_) => const OwnerLoginScreen()),
      );
      if (signedIn != true || !mounted) {
        await _backToPicker();
        return;
      }
      // 2. First sign-in with the demo password: force a change.
      final mustChange = supabase.auth.currentUser?.userMetadata?[
              'must_change_password'] ==
          true;
      if (mustChange) {
        final changed = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                const OwnerChangePasswordScreen(forced: true),
          ),
        );
        if (changed != true || !mounted) {
          await supabase.auth.signOut();
          await _backToPicker();
          return;
        }
      }
    }
    // 3. Quick unlock with the 4-digit PIN.
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
      await _backToPicker();
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
