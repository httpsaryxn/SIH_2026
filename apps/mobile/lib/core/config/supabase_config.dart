/// SupabaseConfig holds the unified configuration for the FreshLabel Pro project.
abstract class SupabaseConfig {
  static const String supabaseUrl = 'https://tyshfugxmwvhbmoydlnl.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_GY9lF1xMPLtaGflK296b4Q_GlBlU2DP';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5c2hmdWd4bXd2aGJtb3lkbG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDkzMDQsImV4cCI6MjEwMzQyNTMwNH0.URx0CbCB5qqRk_S3gUTIG8h2xevzrruGwmPYQYqCAik';
  static const String authRedirectScheme = 'io.supabase.freshlabel';

  // Backwards-compatible aliases
  static const String url = supabaseUrl;
  static const String anonKey = supabaseAnonKey;
  static const String publishableKey = supabasePublishableKey;
}
