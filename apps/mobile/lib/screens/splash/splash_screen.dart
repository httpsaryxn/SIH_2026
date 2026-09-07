import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/role_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/label_lens_brand.dart';
import '../onboarding/role_selection_screen.dart';

/// Animated Splash Screen for 'Label Lens'.
///
/// Displays the official logo, animated brand styling ('Label' in black, 'Lens' in green),
/// and checks the user's authentication state before smoothly transitioning to the next screen.
class SplashScreen extends StatefulWidget {
  final Duration minDuration;

  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Widget? _destination;
  bool _authResolved = false;
  bool _minTimeElapsed = false;
  Timer? _minTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();

    // Start minimum display timer
    _minTimer = Timer(widget.minDuration, () {
      _minTimeElapsed = true;
      _checkAndNavigate();
    });

    // Resolve Auth State
    _resolveAuthState();
  }

  Future<void> _resolveAuthState() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final profile = await AuthService.fetchUserProfile();
        if (profile != null && profile['role'] != null) {
          final role = AuthService.roleFromDb(profile['role'] as String?);
          _destination = RoleRouter.homeScreenFor(role);
          _authResolved = true;
          _checkAndNavigate();
          return;
        }
      }
    } catch (_) {
      // Fall through to role selection on any error
    }

    _destination = const RoleSelectionScreen();
    _authResolved = true;
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (_minTimeElapsed && _authResolved && mounted) {
      final target = _destination ?? const RoleSelectionScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => target,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF0FDF4), // soft emerald tint
                    Colors.white,
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          ),

          // Central Brand Presentation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          blurRadius: 36,
                          spreadRadius: 8,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/labellens_logo.png',
                        width: 108,
                        height: 108,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const LabelLensBrand(
                          showLogo: false,
                          fontSize: 34,
                          isStacked: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Legal Metrology & Packaging Compliance',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Version & Powered By
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Department of Consumer Affairs • SIH 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
