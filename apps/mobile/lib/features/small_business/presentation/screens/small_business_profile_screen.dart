import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../screens/onboarding/role_selection_screen.dart';

class SmallBusinessProfileScreen extends StatefulWidget {
  const SmallBusinessProfileScreen({super.key});

  @override
  State<SmallBusinessProfileScreen> createState() =>
      _SmallBusinessProfileScreenState();
}

class _SmallBusinessProfileScreenState extends State<SmallBusinessProfileScreen> {
  bool _isLoading = true;
  bool _isSigningOut = false;

  String _businessName = 'Small Business Enterprise';
  String _ownerName = 'Business Owner';
  String _email = 'business@labellens.in';
  String _createdAt = '2026';
  final String _officialId = 'SB-REG-2026-4401';
  final String _departmentName = 'Ministry of Corporate Affairs & Legal Metrology';
  final String _jurisdiction = 'National & State Compliance Division';

  @override
  void initState() {
    super.initState();
    _loadBusinessDetails();
  }

  Future<void> _loadBusinessDetails() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        if (user.email != null && user.email!.isNotEmpty) {
          _email = user.email!;
        }
        final metadata = user.userMetadata;
        if (metadata != null) {
          if (metadata['organization_name'] != null && (metadata['organization_name'] as String).isNotEmpty) {
            _businessName = metadata['organization_name'] as String;
          } else if (metadata['business_name'] != null && (metadata['business_name'] as String).isNotEmpty) {
            _businessName = metadata['business_name'] as String;
          }
          if (metadata['full_name'] != null && (metadata['full_name'] as String).isNotEmpty) {
            _ownerName = metadata['full_name'] as String;
          }
        }
        if (user.createdAt.isNotEmpty) {
          final dt = DateTime.tryParse(user.createdAt);
          if (dt != null) {
            _createdAt = '${dt.day}/${dt.month}/${dt.year}';
          }
        }
      }

      final profile = await AuthService.fetchUserProfile();
      if (profile != null) {
        if (profile['full_name'] != null && (profile['full_name'] as String).isNotEmpty) {
          _ownerName = profile['full_name'] as String;
          if (_businessName == 'Small Business Enterprise') {
            _businessName = profile['full_name'] as String;
          }
        }
        if (profile['email'] != null && (profile['email'] as String).isNotEmpty) {
          _email = profile['email'] as String;
        }
        if (profile['created_at'] != null) {
          final dt = DateTime.tryParse(profile['created_at'].toString());
          if (dt != null) {
            _createdAt = '${dt.day}/${dt.month}/${dt.year}';
          }
        }
      }
    } catch (_) {
      // Fallback
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Sign Out',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your business session?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusDefault)),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Log Out',
              style: AppTypography.labelMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSigningOut = true);
    try {
      await AuthService.signOut();
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(
          'Logged out successfully.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 60.0,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.onSurfaceVariant,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          height: 1.0,
        ),
      ),
      title: Text(
        'Business Profile',
        style: AppTypography.headlineSm.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Banner Card
                  _buildProfileHeaderCard(),
                  const SizedBox(height: AppSpacing.md),

                  // Official Credential Information
                  _buildSectionHeader('Business Credentials'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildCredentialsCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // Authority & Department Details
                  _buildSectionHeader('Department & Jurisdiction'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDepartmentCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // Session & Security Status
                  _buildSectionHeader('Security & System Status'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSecurityCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Prominent Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelMd.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          // Circular Profile Icon matching regulator style
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.18),
              border: Border.all(color: AppColors.primaryContainer, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Business Name
          Text(
            _businessName,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _email,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Enterprise Registration / GSTIN',
            value: _officialId,
            isMonospace: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.work_outline_rounded,
            label: 'Authorized Signatory',
            value: _ownerName,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Registered Email',
            value: _email,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _createdAt,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Department',
            value: _departmentName,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.map_outlined,
            label: 'Jurisdiction',
            value: _jurisdiction,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.policy_outlined,
            label: 'Statutory Act',
            value: 'Legal Metrology Act, 2009 & Packaged Commodities Rules',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.lock_outline_rounded,
            label: 'Authentication Provider',
            value: 'Supabase Auth (Role-based RLS)',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Clearance Level',
            value: 'Tier 1 - Label Specification & Artwork Publishing',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.terminal_rounded,
            label: 'App Version',
            value: 'Label Lens v1.0.0 (SIH 2026)',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.errorContainer.withValues(alpha: 0.5),
        foregroundColor: AppColors.error,
        elevation: 0,
        side: const BorderSide(color: AppColors.error, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      onPressed: _isSigningOut ? null : _handleSignOut,
      child: _isSigningOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Log Out',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }
}
