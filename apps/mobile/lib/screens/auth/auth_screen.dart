import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/user_role.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/role_router.dart';
import '../../core/widgets/label_lens_brand.dart';
import '../../widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  final UserRole selectedRole;
  final bool initialIsLogin;

  const AuthScreen({
    super.key,
    required this.selectedRole,
    this.initialIsLogin = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;
  late UserRole _currentRole;
  StreamSubscription<AuthState>? _authSubscription;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _currentRole = widget.selectedRole;

    // Listen for auth state changes (e.g. Google OAuth redirect or session restoration)
    _authSubscription = AuthService.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted && !_isLoading) {
        _navigateAfterSuccessfulAuth();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSuccessfulAuth([UserRole? fallbackRole]) async {
    UserRole targetRole = fallbackRole ?? _currentRole;
    try {
      final profile = await AuthService.fetchUserProfile();
      if (profile != null && profile['role'] != null) {
        targetRole = AuthService.roleFromDb(profile['role'] as String?);
      }
    } catch (_) {}

    if (!mounted) return;
    RoleRouter.navigateToHome(context, targetRole);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        UserRole targetRole = _currentRole;
        try {
          await AuthService.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          final profile = await AuthService.fetchUserProfile();
          if (profile != null && profile['role'] != null) {
            targetRole = AuthService.roleFromDb(profile['role'] as String?);
          }
        } on AuthException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Text(
                e.message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Text(
                e.toString().contains('TimeoutException')
                    ? 'Connection timeout. Please check your network.'
                    : 'Sign in failed. Please check your credentials.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              'Logged in successfully as ${targetRole.title}!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        await _navigateAfterSuccessfulAuth(targetRole);
      } else {
        try {
          final res = await AuthService.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            role: _currentRole,
            organizationName: _orgController.text.isNotEmpty ? _orgController.text : null,
          );
          if (res.session == null && res.user != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Account created! Please check your email for confirmation.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
            setState(() => _isLogin = true);
            return;
          }
        } on AuthException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Text(
                e.message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Text(
                e.toString().contains('TimeoutException')
                    ? 'Connection timeout. Please check your network.'
                    : 'Account creation failed. Please try again.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              'Account created as ${_currentRole.title}!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        await _navigateAfterSuccessfulAuth();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await AuthService.signInWithGoogle(targetRole: _currentRole);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasOrgField = !_isLogin && _currentRole.organizationFieldLabel != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                  boxShadow: AppSpacing.modalShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Logo / Header
                      const Center(
                        child: LabelLensBrand(
                          logoSize: 42,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Role Indicator Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentRole.icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isLogin
                                          ? 'Logging in as ${_currentRole.title}. '
                                          : '${_currentRole.authRoleLabel} ',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                'Change role',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Mode Segmented Control Toggle
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildToggleButton(
                                title: 'Create Account',
                                isActive: !_isLogin,
                                onTap: () => setState(() => _isLogin = false),
                              ),
                            ),
                            Expanded(
                              child: _buildToggleButton(
                                title: 'Log In',
                                isActive: _isLogin,
                                onTap: () => setState(() => _isLogin = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Name Field (Create Account only)
                      if (!_isLogin) ...[
                        _buildFieldLabel('Full Name'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                          ),
                          validator: (value) {
                            if (!_isLogin && (value == null || value.trim().isEmpty)) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Email Field
                      _buildFieldLabel('Email Address'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Organization Field (If applicable)
                      if (hasOrgField) ...[
                        _buildFieldLabel(_currentRole.organizationFieldLabel!),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _orgController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: _currentRole.organizationFieldPlaceholder,
                          ),
                          validator: (value) {
                            if (!_isLogin && (value == null || value.trim().isEmpty)) {
                              return 'Please enter this field';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Password Field
                      _buildFieldLabel('Password'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: _isLogin ? 'Enter your password' : 'Create a password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.outline,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (!_isLogin && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Forgot Password Link (Login mode)
                      if (_isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password reset instructions sent!')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Confirm Password (Create Account only)
                      if (!_isLogin) ...[
                        _buildFieldLabel('Confirm Password'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.outline,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (!_isLogin) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Primary Action Button
                      CustomButton(
                        text: _isLogin ? 'Log In' : 'Create Account',
                        isLoading: _isLoading,
                        borderRadius: AppSpacing.roundedDefault,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Switch Login / Register link
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.secondary,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: _isLogin ? 'Create Account' : 'Log in',
                                  style: const TextStyle(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // OR Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              'OR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.outlineVariant)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Google Social Button
                      CustomButton(
                        text: 'Continue with Google',
                        variant: ButtonVariant.outline,
                        borderRadius: AppSpacing.roundedDefault,
                        icon: _buildGoogleIcon(),
                        onPressed: _handleGoogleLogin,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Footer Terms
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 1.45,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: AppSpacing.roundedSm,
          boxShadow: isActive ? AppSpacing.cardShadow : null,
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(w, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 0, -1.2, false)
      ..close();
    canvas.drawPath(pathBlue, bluePaint);

    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -1.2, -1.5, false)
      ..close();
    canvas.drawPath(pathRed, redPaint);

    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -2.7, -1.5, false)
      ..close();
    canvas.drawPath(pathYellow, yellowPaint);

    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -4.2, -1.5, false)
      ..close();
    canvas.drawPath(pathGreen, greenPaint);

    final whitePaint = Paint()..color = AppColors.surfaceContainerLowest;
    canvas.drawCircle(center, radius * 0.55, whitePaint);

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.22, radius * 0.95, radius * 0.44),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
