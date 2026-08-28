import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/role_router.dart';
import 'screens/onboarding/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabasePublishableKey,
  );

  runApp(const FreshLabelApp());
}

class FreshLabelApp extends StatelessWidget {
  const FreshLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshLabel Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// AuthGate listens to auth state and routes the user accordingly.
/// - If signed in → fetch role from profile → navigate to correct home.
/// - If not signed in → show role selection / onboarding.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // User is authenticated — determine their role
        final profile = await AuthService.fetchUserProfile();
        if (profile != null && profile['role'] != null) {
          final role = AuthService.roleFromDb(profile['role'] as String?);
          if (mounted) {
            setState(() {
              _destination = RoleRouter.homeScreenFor(role);
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (_) {
      // If anything fails, fall through to role selection
    }

    if (mounted) {
      setState(() {
        _destination = const RoleSelectionScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _destination!;
  }
}
