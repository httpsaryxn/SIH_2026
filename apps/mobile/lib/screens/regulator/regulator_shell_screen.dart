import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/motion.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import 'regulator_home_screen.dart';
import 'regulator_company_tracking_screen.dart';
import 'regulator_audit_intake_screen.dart';
import 'regulator_complaint_inbox_screen.dart';
import 'regulator_profile_screen.dart';

/// Single persistent shell screen for the entire Regulator module.
///
/// Owns the single Scaffold and bottom navigation bar once.
/// Hosts all 5 tab bodies inside a [DirectionalIndexedStack], ensuring:
/// - In-memory state preservation (scroll positions, text inputs, mid-capture photos).
/// - Fluid direction-aware tab animations (sliding left/right based on spatial position).
/// - Zero redundant rebuilding or re-fetching on tab changes.
class RegulatorShellScreen extends StatefulWidget {
  final RegulatorNavTab initialTab;

  const RegulatorShellScreen({
    super.key,
    this.initialTab = RegulatorNavTab.home,
  });

  @override
  State<RegulatorShellScreen> createState() => RegulatorShellScreenState();
}

class RegulatorShellScreenState extends State<RegulatorShellScreen> {
  late RegulatorNavTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  /// Switch the active tab within the shell without destroying or reloading screens.
  void switchTab(RegulatorNavTab tab) {
    if (_currentTab != tab) {
      setState(() => _currentTab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DirectionalIndexedStack(
        index: _currentTab.spatialIndex,
        duration: AppDurations.medium,
        curve: AppCurves.entrance,
        children: const [
          // Index 0: Home Overview
          RegulatorHomeBody(),

          // Index 1: Violations & Company Tracking
          RegulatorCompanyTrackingScreen(isStandalone: false),

          // Index 2: Audit Intake (Center QR Action)
          RegulatorAuditIntakeScreen(isStandalone: false),

          // Index 3: Unified Complaint Inbox
          RegulatorComplaintInboxScreen(isStandalone: false),

          // Index 4: Officer Profile
          RegulatorProfileScreen(isStandalone: false),
        ],
      ),
      bottomNavigationBar: RegulatorBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: switchTab,
      ),
    );
  }
}
