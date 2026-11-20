import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../owner_pin.dart';
import '../theme.dart';

enum OwnerPinMode { set, verify }

/// 4-digit PIN gate for the business owner portal.
///
/// - `set`: first time the owner opens the portal (or when changing
///   the PIN) — enter a new PIN and confirm it.
/// - `verify`: every later visit — enter the PIN to unlock.
///
/// Pops `true` when the PIN was set or verified, nothing otherwise.
class OwnerPinScreen extends StatefulWidget {
  const OwnerPinScreen({super.key, required this.mode});

  final OwnerPinMode mode;

  @override
  State<OwnerPinScreen> createState() => _OwnerPinScreenState();
}

class _OwnerPinScreenState extends State<OwnerPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = LocalAuthentication();
  String? _error;
  // Verify mode only: fingerprint / face unlock, with the PIN as fallback.
  bool _biometricsAvailable = false;
  String _biometricLabel = 'fingerprint';
  bool _biometricPrompted = false;

  bool get _isSet => widget.mode == OwnerPinMode.set;

  @override
  void initState() {
    super.initState();
    // local_auth has no web implementation — PIN only on web.
    if (!_isSet && !kIsWeb) {
      // Offer the system biometric prompt once, right after the screen
      // opens. If it fails or is cancelled, the PIN keypad is right there.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tryBiometrics(firstTime: true));
    }
  }

  /// True when the phone has enrolled biometrics the app can use.
  Future<void> _checkBiometrics() async {
    // local_auth has no web implementation — PIN only on web.
    if (kIsWeb) return;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck || !mounted) return;
      final available = await _auth.getAvailableBiometrics();
      if (!mounted) return;
      if (available.isEmpty) return;
      final hasFace = available.contains(BiometricType.face);
      final hasFingerprint = available.contains(BiometricType.fingerprint);
      setState(() {
        _biometricsAvailable = true;
        _biometricLabel = hasFace && hasFingerprint
            ? 'fingerprint or face'
            : hasFace
                ? 'face'
                : 'fingerprint';
      });
    } on PlatformException {
      // Biometrics not usable on this phone — PIN only, silently.
    }
  }

  /// Shows the system fingerprint / face dialog. On success this
  /// unlocks exactly like a correct PIN. Anything else leaves the
  /// owner on the PIN screen. With [firstTime] the dialog is only
  /// shown once (the auto-prompt when the screen opens); the button
  /// can always ask again.
  Future<void> _tryBiometrics({bool firstTime = false}) async {
    // local_auth has no web implementation — PIN only on web.
    if (kIsWeb) return;
    if (firstTime) {
      if (_biometricPrompted || !mounted) return;
      _biometricPrompted = true;
    }
    await _checkBiometrics();
    if (!_biometricsAvailable || !mounted) return;
    final navigator = Navigator.of(context);
    bool ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason:
            'Unlock the owner portal with your $_biometricLabel.',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      if (mounted) {
        setState(() =>
            _error = 'Biometric unlock is not available. Use your PIN.');
      }
      return;
    }
    if (ok) navigator.pop(true);
    // Failed or cancelled: stay on the PIN screen, no error shown.
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = 'Enter a 4-digit PIN.');
      return;
    }
    if (_isSet) {
      if (_confirmController.text.trim() != pin) {
        setState(() => _error = 'PINs do not match. Try again.');
        return;
      }
      await OwnerPin.set(pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final ok = await OwnerPin.check(pin);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Wrong PIN. Try again.');
        _pinController.clear();
      }
    }
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      maxLength: 4,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, letterSpacing: 12),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar(
        title: Text(_isSet ? 'Set owner PIN' : 'Owner PIN'),
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
                  const Icon(Icons.lock_outline,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _isSet
                        ? 'Choose a 4-digit PIN to protect the owner portal.'
                        : 'Enter your 4-digit owner PIN to continue.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
                  _pinField(_pinController, _isSet ? 'New PIN' : 'PIN'),
                  if (_isSet) ...[
                    const SizedBox(height: 16),
                    _pinField(_confirmController, 'Confirm PIN'),
                  ],
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
                    label: _isSet ? 'Save PIN' : 'Unlock',
                    onPressed: _submit,
                  ),
                  if (!_isSet && _biometricsAvailable) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _tryBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text('Unlock with $_biometricLabel'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
