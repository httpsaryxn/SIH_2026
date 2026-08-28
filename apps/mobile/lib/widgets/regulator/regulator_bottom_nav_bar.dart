import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../screens/regulator/regulator_home_screen.dart';
import '../../screens/regulator/regulator_audit_intake_screen.dart';
import '../../screens/regulator/regulator_company_tracking_screen.dart';
import '../../screens/regulator/regulator_complaint_inbox_screen.dart';
import '../../screens/regulator/regulator_profile_screen.dart';

enum RegulatorNavTab {
  home,
  audit,
  violations,
  inbox,
  profile,
}

class RegulatorBottomNavBar extends StatelessWidget {
  final RegulatorNavTab currentTab;
  final ValueChanged<RegulatorNavTab>? onTabSelected;

  const RegulatorBottomNavBar({
    super.key,
    required this.currentTab,
    this.onTabSelected,
  });

  /// Standard tab navigation handler that cleanly switches between the main regulator screens.
  static void navigateToTab(
    BuildContext context,
    RegulatorNavTab currentTab,
    RegulatorNavTab targetTab,
  ) {
    if (currentTab == targetTab) return;

    Widget targetScreen;
    switch (targetTab) {
      case RegulatorNavTab.home:
        targetScreen = const RegulatorHomeScreen();
        break;
      case RegulatorNavTab.audit:
        targetScreen = const RegulatorAuditIntakeScreen();
        break;
      case RegulatorNavTab.violations:
        targetScreen = const RegulatorCompanyTrackingScreen();
        break;
      case RegulatorNavTab.inbox:
        targetScreen = const RegulatorComplaintInboxScreen();
        break;
      case RegulatorNavTab.profile:
        targetScreen = const RegulatorProfileScreen();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context: context,
                tab: RegulatorNavTab.home,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                context: context,
                tab: RegulatorNavTab.audit,
                icon: Icons.assignment_turned_in_rounded,
                label: 'Audit',
              ),
              _buildNavItem(
                context: context,
                tab: RegulatorNavTab.violations,
                icon: Icons.gavel_rounded,
                label: 'Violations',
              ),
              _buildNavItem(
                context: context,
                tab: RegulatorNavTab.inbox,
                icon: Icons.inbox_rounded,
                label: 'Inbox',
              ),
              _buildNavItem(
                context: context,
                tab: RegulatorNavTab.profile,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required RegulatorNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final isActive = currentTab == tab;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTabSelected != null) {
              onTabSelected!(tab);
            } else {
              navigateToTab(context, currentTab, tab);
            }
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? AppSpacing.sm : 2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTypography.labelSm.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
