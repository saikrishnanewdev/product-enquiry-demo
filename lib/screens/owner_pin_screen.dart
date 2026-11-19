import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../owner_pin.dart';

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
  String? _error;

  bool get _isSet => widget.mode == OwnerPinMode.set;

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
        border: const OutlineInputBorder(),
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
      appBar: AppBar(title: Text(_isSet ? 'Set owner PIN' : 'Owner PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              _isSet
                  ? 'Choose a 4-digit PIN to protect the owner portal.'
                  : 'Enter your 4-digit owner PIN to continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _pinField(_pinController, _isSet ? 'New PIN' : 'PIN'),
            if (_isSet) ...[
              const SizedBox(height: 16),
              _pinField(_confirmController, 'Confirm PIN'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _isSet ? 'Save PIN' : 'Unlock',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
