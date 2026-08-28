import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_role.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Helper to convert UserRole enum to database string
  static String roleToDb(UserRole role) {
    switch (role) {
      case UserRole.smallBusiness:
        return 'small_business';
      case UserRole.largeBusiness:
        return 'large_business';
      case UserRole.consumer:
        return 'consumer';
      case UserRole.regulator:
        return 'regulator';
    }
  }

  /// Helper to parse database string to UserRole enum
  static UserRole roleFromDb(String? value) {
    switch (value) {
      case 'small_business':
        return UserRole.smallBusiness;
      case 'large_business':
        return UserRole.largeBusiness;
      case 'regulator':
        return UserRole.regulator;
      case 'consumer':
      default:
        return UserRole.consumer;
    }
  }

  /// Sign Up with Email and Password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? organizationName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'role': roleToDb(role),
        'organization_name': organizationName?.trim(),
      },
    );
    return response;
  }

  /// Sign In with Email and Password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Initiate Google Sign In (OAuth / Deep Linking)
  static Future<bool> signInWithGoogle({UserRole? targetRole}) async {
    final redirectTo = kIsWeb
        ? null
        : SupabaseConfig.authRedirectScheme;

    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      queryParams: targetRole != null
          ? {'role': roleToDb(targetRole)}
          : null,
    );
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Sign Out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch User Profile from public.users
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  /// Fetch role-specific details from dedicated table
  static Future<Map<String, dynamic>?> fetchRoleData(UserRole role) async {
    final user = currentUser;
    if (user == null) return null;

    String tableName;
    switch (role) {
      case UserRole.smallBusiness:
        tableName = 'small_businesses';
        break;
      case UserRole.largeBusiness:
        tableName = 'large_businesses';
        break;
      case UserRole.consumer:
        tableName = 'consumers';
        break;
      case UserRole.regulator:
        tableName = 'regulators';
        break;
    }

    final data = await _client
        .from(tableName)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }
}
