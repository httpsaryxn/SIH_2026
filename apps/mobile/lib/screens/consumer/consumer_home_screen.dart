import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/consumer_complaint_model.dart';
import '../../core/models/consumer_saved_product.dart';
import '../../core/models/consumer_scan_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/consumer_data_service.dart';
import '../onboarding/role_selection_screen.dart';
import 'widgets/my_complaints_section.dart';
import 'widgets/product_summary_modal.dart';
import 'widgets/quick_feature_strip.dart';
import 'widgets/recent_scans_section.dart';
import 'widgets/report_complaint_dialog.dart';
import 'widgets/report_issue_hero_card.dart';
import 'widgets/saved_products_section.dart';
import 'widgets/scan_hero_card.dart';
import 'widgets/scanner_modal_sheet.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  String _userName = 'Consumer';

  List<ConsumerScanModel> _recentScans = [];
  List<ConsumerSavedProduct> _savedProducts = [];
  List<ConsumerComplaintModel> _myComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadAllConsumerData();
  }

  Future<void> _loadAllConsumerData() async {
    setState(() => _isLoading = true);

    // Fetch user profile name
    final userProfile = await AuthService.fetchUserProfile();
    if (userProfile != null && userProfile['full_name'] != null && (userProfile['full_name'] as String).isNotEmpty) {
      _userName = (userProfile['full_name'] as String).split(' ').first;
    } else {
      final email = AuthService.currentUser?.email;
      if (email != null && email.contains('@')) {
        _userName = email.split('@').first;
      }
    }

    // Fetch all real Supabase data in parallel
    final results = await Future.wait([
      ConsumerDataService.fetchRecentScans(),
      ConsumerDataService.fetchSavedProducts(),
      ConsumerDataService.fetchMyComplaints(),
    ]);

    if (mounted) {
      setState(() {
        _recentScans = results[0] as List<ConsumerScanModel>;
        _savedProducts = results[1] as List<ConsumerSavedProduct>;
        _myComplaints = results[2] as List<ConsumerComplaintModel>;
        _isLoading = false;
      });
    }
  }

  void _openScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScannerModalSheet(
        onScanCompleted: (newScan) {
          setState(() {
            _recentScans.insert(0, newScan);
          });
          _showProductSummary(newScan);
        },
      ),
    );
  }

  void _openReportDialog({String? prefilledProductName, String? prefilledBrand}) {
    showDialog(
      context: context,
      builder: (context) => ReportComplaintDialog(
        prefilledProductName: prefilledProductName,
        prefilledBrand: prefilledBrand,
        onComplaintSubmitted: (newComplaint) {
          setState(() {
            _myComplaints.insert(0, newComplaint);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Complaint ${newComplaint.complaintCode} submitted successfully to authorities!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProductSummary(ConsumerScanModel scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductSummaryModal(
        scan: scan,
        onReportIssue: () {
          _openReportDialog(
            prefilledProductName: scan.productName,
            prefilledBrand: scan.brand,
          );
        },
      ),
    );
  }

  Future<void> _handleUnsave(ConsumerSavedProduct item) async {
    final success = await ConsumerDataService.unsaveProduct(item.productId);
    if (success && mounted) {
      setState(() {
        _savedProducts.removeWhere((p) => p.productId == item.productId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Removed ${item.productName} from saved items'),
        ),
      );
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final horizontalPadding = isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(isDesktop, horizontalPadding),
      body: RefreshIndicator(
        onRefresh: _loadAllConsumerData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Bento Hero & Feature Strip
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ScanHeroCard(
                            onScanPressed: _openScannerModal,
                            onUploadPressed: _openScannerModal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          flex: 1,
                          child: QuickFeatureStrip(
                            onFeatureTap: (feature) => _openScannerModal(),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ScanHeroCard(
                      onScanPressed: _openScannerModal,
                      onUploadPressed: _openScannerModal,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QuickFeatureStrip(
                      onFeatureTap: (feature) => _openScannerModal(),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Dynamic Grid Section (Scans & Saved on Left, Report & Complaints on Right)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RecentScansSection(
                                scans: _recentScans,
                                isLoading: _isLoading,
                                onScanTap: _showProductSummary,
                                onViewAllTap: _openScannerModal,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SavedProductsSection(
                                savedProducts: _savedProducts,
                                isLoading: _isLoading,
                                onProductTap: (item) {
                                  // Find in scans or show summary
                                  final matchingScan = _recentScans.firstWhere(
                                    (s) => s.productName == item.productName,
                                    orElse: () => ConsumerScanModel(
                                      id: item.id,
                                      consumerId: item.consumerId,
                                      productId: item.productId,
                                      productName: item.productName,
                                      brand: item.brand,
                                      netQuantity: item.quantity ?? '1 unit',
                                      imageUrl: item.imageUrl,
                                      complianceStatus: 'compliant',
                                      scannedAt: item.savedAt,
                                    ),
                                  );
                                  _showProductSummary(matchingScan);
                                },
                                onUnsaveTap: _handleUnsave,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),

                        // Right Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReportIssueHeroCard(
                                onReportTap: () => _openReportDialog(),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              MyComplaintsSection(
                                complaints: _myComplaints,
                                isLoading: _isLoading,
                                onComplaintTap: (complaint) {
                                  _openReportDialog(
                                    prefilledProductName: complaint.productName,
                                    prefilledBrand: complaint.brand,
                                  );
                                },
                                onViewAllTap: () => _openReportDialog(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Mobile Stack Layout
                    RecentScansSection(
                      scans: _recentScans,
                      isLoading: _isLoading,
                      onScanTap: _showProductSummary,
                      onViewAllTap: _openScannerModal,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SavedProductsSection(
                      savedProducts: _savedProducts,
                      isLoading: _isLoading,
                      onProductTap: (item) {
                        final matchingScan = _recentScans.firstWhere(
                          (s) => s.productName == item.productName,
                          orElse: () => ConsumerScanModel(
                            id: item.id,
                            consumerId: item.consumerId,
                            productId: item.productId,
                            productName: item.productName,
                            brand: item.brand,
                            netQuantity: item.quantity ?? '1 unit',
                            imageUrl: item.imageUrl,
                            complianceStatus: 'compliant',
                            scannedAt: item.savedAt,
                          ),
                        );
                        _showProductSummary(matchingScan);
                      },
                      onUnsaveTap: _handleUnsave,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ReportIssueHeroCard(
                      onReportTap: () => _openReportDialog(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    MyComplaintsSection(
                      complaints: _myComplaints,
                      isLoading: _isLoading,
                      onComplaintTap: (complaint) {
                        _openReportDialog(
                          prefilledProductName: complaint.productName,
                          prefilledBrand: complaint.brand,
                        );
                      },
                      onViewAllTap: () => _openReportDialog(),
                    ),
                  ],

                  const SizedBox(height: 80), // Padding for bottom navbar
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
    );
  }

  PreferredSizeWidget _buildTopAppBar(bool isDesktop, double horizontalPadding) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      title: Row(
        children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'FreshLabel Pro',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          TextButton(
            onPressed: () => setState(() => _currentNavIndex = 0),
            child: Text(
              'Home',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: _currentNavIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                color: _currentNavIndex == 0 ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: _openScannerModal,
            child: Text(
              'Scans',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openReportDialog(),
            child: Text(
              'Complaints',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],

        // User Avatar Menu
        PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedDefault),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Consumer Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'switch_role',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text('Switch Role', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sign_out',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'switch_role') {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            } else if (value == 'sign_out') {
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            }
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $_userName 👋',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scan a product to understand its label and check for potential Legal Metrology compliance issues.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.surfaceVariant, width: 1)),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_rounded,
                label: 'Scans',
                onTap: _openScannerModal,
              ),
              // Center Scan FAB
              GestureDetector(
                onTap: _openScannerModal,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppSpacing.primaryButtonShadow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.report_problem_rounded,
                label: 'Complaints',
                onTap: () => _openReportDialog(),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Logged in as $_userName (Consumer)'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isActive = _currentNavIndex == index;
    final color = isActive ? AppColors.primary : AppColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
