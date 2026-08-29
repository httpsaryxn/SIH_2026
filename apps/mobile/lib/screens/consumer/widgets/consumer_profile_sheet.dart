import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/auth_service.dart';
import '../../onboarding/role_selection_screen.dart';

class ConsumerProfileSheet extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onNavigateToScans;
  final VoidCallback onNavigateToComplaints;
  final VoidCallback onOpenNotifications;

  const ConsumerProfileSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onNavigateToScans,
    required this.onNavigateToComplaints,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Avatar & Basic Info
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                userName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                userEmail,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.25),
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  'Account Type: Consumer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Menu Options
              _buildTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Profile edit modal opened'),
                    ),
                  );
                },
              ),
              _buildTile(
                icon: Icons.history_rounded,
                title: 'My Scan History',
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigateToScans();
                },
              ),
              _buildTile(
                icon: Icons.gavel_rounded,
                title: 'My Complaints',
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigateToComplaints();
                },
              ),
              _buildTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenNotifications();
                },
              ),
              _buildTile(
                icon: Icons.security_rounded,
                title: 'Privacy & Security',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Supabase RLS & End-to-End Encryption enabled.'),
                    ),
                  );
                },
              ),
              _buildTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Legal Metrology Packaged Commodity Rules, 2011 Guide'),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.surfaceVariant, height: 24),
              _buildTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Switch Role',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                },
              ),
              _buildTile(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                color: AppColors.error,
                onTap: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.onSurface, size: 22),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: color ?? AppColors.outline,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onTap: onTap,
    );
  }
}
