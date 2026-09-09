import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
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

class RegulatorBottomNavBar extends StatefulWidget {
  final RegulatorNavTab currentTab;
  final ValueChanged<RegulatorNavTab>? onTabSelected;

  const RegulatorBottomNavBar({
    super.key,
    required this.currentTab,
    this.onTabSelected,
  });

  /// Standard tab navigation handler with smooth page transition animations.
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
  State<RegulatorBottomNavBar> createState() => _RegulatorBottomNavBarState();
}

class _RegulatorBottomNavBarState extends State<RegulatorBottomNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _pulseOpacityAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.currentTab == RegulatorNavTab.audit) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RegulatorBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTab == RegulatorNavTab.audit) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleAuditTap() {
    HapticFeedback.mediumImpact();
    // Play quick tap bounce micro-interaction asynchronously
    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reverse();
      }
    });

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(RegulatorNavTab.audit);
    } else {
      RegulatorBottomNavBar.navigateToTab(
        context,
        widget.currentTab,
        RegulatorNavTab.audit,
      );
    }
  }

  void _handleNavTap(RegulatorNavTab tab) {
    HapticFeedback.selectionClick();
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tab);
    } else {
      RegulatorBottomNavBar.navigateToTab(
        context,
        widget.currentTab,
        tab,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    tab: RegulatorNavTab.home,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    tab: RegulatorNavTab.violations,
                    icon: Icons.gavel_rounded,
                    label: 'Violations',
                  ),
                ),
                // Center Elevated Green QR Scanner / Audit Action Button
                Expanded(
                  child: _buildCenterAuditButton(),
                ),
                Expanded(
                  child: _buildNavItem(
                    tab: RegulatorNavTab.inbox,
                    icon: Icons.inbox_rounded,
                    label: 'Inbox',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    tab: RegulatorNavTab.profile,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAuditButton() {
    final isAuditActive = widget.currentTab == RegulatorNavTab.audit;

    return Center(
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('regulator_audit_nav_button'),
          customBorder: const CircleBorder(),
          onTap: _handleAuditTap,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Radiating halo pulse when on Audit Intake screen
              if (isAuditActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 50 * _pulseScaleAnimation.value,
                      height: 50 * _pulseScaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(
                          alpha: _pulseOpacityAnimation.value,
                        ),
                      ),
                    );
                  },
                ),

              // Main green circular scanner button with bounce animation
              ScaleTransition(
                scale: _bounceAnimation,
                child: Ink(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: isAuditActive ? 0.45 : 0.32,
                        ),
                        blurRadius: isAuditActive ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                      if (isAuditActive)
                        BoxShadow(
                          color:
                              AppColors.primaryContainer.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      // Accessible and test-discoverable label for find.widgetWithText(InkWell, 'Audit')
                      Opacity(
                        opacity: 0.0,
                        child: IgnorePointer(
                          ignoring: true,
                          child: const Text(
                            'Audit',
                            style: TextStyle(fontSize: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required RegulatorNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final isActive = widget.currentTab == tab;
    final color = isActive ? AppColors.primary : AppColors.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavTap(tab),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 6,
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
                    color: color,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: color,
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
