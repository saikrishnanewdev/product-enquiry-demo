import 'package:shared_preferences/shared_preferences.dart';

/// Which portal this phone uses. Set once on first launch — the
/// customer taps "Get Started" on the welcome screen, the owner
/// enters through the hidden logo tap — and remembered on the phone.
/// The other portal is never shown, and there is no in-app way to
/// change the role; only reinstalling the app clears it.
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
