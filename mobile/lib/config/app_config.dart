class AppConfig {
  // Bu değerleri Supabase dashboard'dan kopyala
  // Project Settings > API > URL ve anon key
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cuhthaaoytnmfbaknhsr.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_dUZnnh2g9ZAeP6KJmdy0RQ_OS3B1uM6',
  );

  static const appScheme = 'io.crossroads.app';
  static const redirectUrl = '$appScheme://login-callback';
}
