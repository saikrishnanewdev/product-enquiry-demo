import 'package:shared_preferences/shared_preferences.dart';

/// Which portal this phone uses. Chosen once on first launch
/// ("one app, choose role once") and remembered on the phone.
/// The owner picks owner, customers pick customer; the other
/// portal is never shown. Switching role clears this (with a
/// confirm step, and the owner's PIN first).
class AppRole {
  static const _key = 'app_role';
  static const customer = 'customer';
  static const owner = 'owner';

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_key);
    return (role == customer || role == owner) ? role : null;
  }

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
