/// Supabase connection details.
///
/// Project: product-enquiry-demo (Mumbai, created 19 Nov 2026).
/// The Project URL and publishable key below are client keys — they are
/// designed to ship inside the app, so they are safe here.
/// NEVER put the service_role key or the database password in this file.
class AppConfig {
  static const String supabaseUrl = 'https://vefeviycsfwicrwwikiw.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_wExMPMX6vHHzpPr_Mf4byg_liHvhbbq';

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-REF') &&
      !supabaseAnonKey.contains('YOUR-ANON-KEY');
}
