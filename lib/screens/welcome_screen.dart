import 'package:flutter/material.dart';
import '../app_role.dart';
import '../theme.dart';
import 'customer_home_screen.dart';
import 'role_gate.dart';

/// First-run welcome screen: customers get straight in, and the
/// owner side is nowhere to be seen.
///
/// - "Get Started" saves role=customer and opens the customer home.
///   Next launch the saved role opens the customer home directly,
///   where "My queries" shows previous questions.
/// - Tapping the logo 5 times quickly is the (undocumented) owner
///   entry: it saves role=owner and opens [OwnerGate] (email +
///   password, then PIN / biometrics). After that the phone opens
///   straight into the owner side. Finding the hidden entry is not
///   a hole — the owner login still stands in the way.
/// There is no role switcher anywhere in the app: the role is set
/// once, and only reinstalling the app clears it.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _logoTaps = 0;
  DateTime? _lastLogoTap;

  Future<void> _getStarted() async {
    await AppRole.setRole(AppRole.customer);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
    );
  }

  Future<void> _openOwner() async {
    // Save the role first, like the old role picker did: OwnerGate
    // itself never writes the role. Backing out of the owner login
    // clears it again (see OwnerGate._backToPicker).
    await AppRole.setRole(AppRole.owner);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OwnerGate()),
    );
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTap == null ||
        now.difference(_lastLogoTap!) > const Duration(seconds: 3)) {
      _logoTaps = 1;
    } else {
      _logoTaps++;
    }
    _lastLogoTap = now;
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      _openOwner();
    }
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
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _onLogoTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.headerGradient,
                ),
                child: const Icon(
                  Icons.storefront,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.heading,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Send a photo of any product and ask — the shop will reply '
              'with availability and price.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.body),
            ),
            const SizedBox(height: 32),
            GradientButton(
              icon: Icons.arrow_forward,
              label: 'Get Started',
              onPressed: _getStarted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your previous queries stay saved on this phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.body),
            ),
          ],
        ),
      ),
    );
  }
}
