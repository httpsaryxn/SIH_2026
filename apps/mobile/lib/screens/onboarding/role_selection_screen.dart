import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/user_role.dart';
import '../../widgets/custom_button.dart';
import '../auth/auth_screen.dart';
import 'widgets/ambient_background.dart';
import 'widgets/role_card.dart';

class RoleSelectionScreen extends StatefulWidget {
  final UserRole? initialRole;

  const RoleSelectionScreen({super.key, this.initialRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _proceedToAuth({bool isLogin = false}) {
    final role = _selectedRole ?? UserRole.smallBusiness;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(
          selectedRole: role,
          initialIsLogin: isLogin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 720;
    final horizontalPadding = isWideScreen ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Brand Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'FreshLabel Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.sm,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // Heading
                          Text(
                            'How will you use the platform?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isWideScreen ? 36 : 26,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.5,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Subtitle
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Text(
                              'Choose your role to get an experience tailored to your specific compliance needs.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isWideScreen ? 17 : 15,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Role Cards Grid
                          if (isWideScreen) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RoleCard(
                                    role: UserRole.smallBusiness,
                                    isSelected: _selectedRole == UserRole.smallBusiness,
                                    onSelect: () => _onRoleSelected(UserRole.smallBusiness),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: RoleCard(
                                    role: UserRole.largeBusiness,
                                    isSelected: _selectedRole == UserRole.largeBusiness,
                                    onSelect: () => _onRoleSelected(UserRole.largeBusiness),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RoleCard(
                                    role: UserRole.consumer,
                                    isSelected: _selectedRole == UserRole.consumer,
                                    onSelect: () => _onRoleSelected(UserRole.consumer),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: RoleCard(
                                    role: UserRole.regulator,
                                    isSelected: _selectedRole == UserRole.regulator,
                                    onSelect: () => _onRoleSelected(UserRole.regulator),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            ...UserRole.values.map(
                              (role) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: RoleCard(
                                  role: role,
                                  isSelected: _selectedRole == role,
                                  onSelect: () => _onRoleSelected(role),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed / Pinned Bottom Actions
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  border: const Border(
                    top: BorderSide(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Continue Button
                        CustomButton(
                          text: 'Continue',
                          onPressed: _selectedRole != null
                              ? () => _proceedToAuth(isLogin: false)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Login Link
                        TextButton(
                          onPressed: () => _proceedToAuth(isLogin: true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.tertiary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          child: Text(
                            'Already have an account? Log in',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
