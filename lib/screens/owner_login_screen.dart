import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme.dart';

/// OWNER sign-in: email + password, checked by Supabase Auth.
///
/// This is what stops anyone from claiming the owner side: the
/// password lives only as a hash on the server, never in the app.
/// Demo account: admin@productenquiry.demo / admin@123 — the first
/// sign-in forces a password change (see OwnerChangePasswordScreen).
/// Pops `true` on a successful sign-in.
class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supabase.auth
          .signInWithPassword(email: email, password: password);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Wrong email or password. Try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not sign in: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar(title: const Text('Owner sign in')),
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
              child: const Column(
                children: [
                  Icon(Icons.business, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Sign in as the business owner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    onSubmitted: (_) => _signIn(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    onSubmitted: (_) => _signIn(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Sign in',
                    onPressed: _busy ? null : _signIn,
                    busy: _busy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
