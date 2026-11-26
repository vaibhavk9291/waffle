class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://euqwrodmioczbrbicmoi.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_NxRBm9ABw3WMXJPTY43ErA_Cxv6vwn-',
  );

  static const String appTitle = 'Shrimant Street Food';
  static const String currencySymbol = '₹';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'https://placeholder.supabase.co';
}
