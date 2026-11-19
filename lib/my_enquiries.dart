import 'package:shared_preferences/shared_preferences.dart';

/// The customer's own enquiries, remembered on their phone.
///
/// The demo has no login, so a customer is recognised by their phone:
/// every enquiry they submit is saved here (newest first). Opening
/// "My queries" from the home screen lists them again, so going back
/// never loses a query.
class MyEnquiries {
  static const _key = 'my_enquiry_ids';

  static Future<void> add(String enquiryId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    if (!ids.contains(enquiryId)) {
      ids.insert(0, enquiryId);
      await prefs.setStringList(_key, ids);
    }
  }

  static Future<List<String>> listIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
