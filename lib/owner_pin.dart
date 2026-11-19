import 'package:shared_preferences/shared_preferences.dart';

/// The business owner's 4-digit PIN, kept on this phone.
///
/// The first time the owner opens the owner portal they set a PIN;
/// after that the PIN is asked every time. This is a demo-level lock
/// (stored on the phone, not on the server) — it makes the owner side
/// feel like a real protected portal. If the PIN is forgotten,
/// reinstalling the app clears it.
class OwnerPin {
  static const _key = 'owner_pin';

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_key) ?? '').length == 4;
  }

  static Future<bool> check(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) == pin;
  }

  static Future<void> set(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pin);
  }
}
