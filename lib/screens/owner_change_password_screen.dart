import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme.dart';

/// Change the owner's password.
///
/// - `forced: true` — first sign-in with the demo password: the
///   owner must pick a new password before entering. Back is
///   disabled; "Cancel and sign out" signs out instead.
/// - `forced: false` — from the owner menu: changing is optional.
/// Pops `true` when the password was changed.
class OwnerChangePasswordScreen extends StatefulWidget {
  const OwnerChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  State<OwnerChangePasswordScreen> createState() =>
      _OwnerChangePasswordScreenState();
}

class _OwnerChangePasswordScreenState
    extends State<OwnerChangePasswordScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _change() async {
    final next = _newController.text;
    if (next.length < 6) {
      setState(() => _error = 'Use at least 6 characters.');
      return;
    }
    if (next != _confirmController.text) {
      setState(() => _error = 'Passwords do not match. Try again.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          password: next,
          data: {'must_change_password': false},
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not change password: $e';
        });
      }
    }
  }

  Future<void> _cancelAndSignOut() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        appBar: AppTheme.gradientAppBar(
          title: const Text('Change password'),
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
                    const Icon(Icons.key, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      widget.forced
                          ? 'You signed in with the demo password. Choose a new password to continue.'
                          : 'Choose a new password for the owner account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
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
                      controller: _newController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      onSubmitted: (_) => _change(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                      ),
                      onSubmitted: (_) => _change(),
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
                      label: 'Change password',
                      onPressed: _busy ? null : _change,
                      busy: _busy,
                    ),
                    if (widget.forced) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy ? null : _cancelAndSignOut,
                        child: const Text('Cancel and sign out'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
