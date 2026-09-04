import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/consumer_complaint_model.dart';
import '../../core/models/consumer_saved_product.dart';
import '../../core/models/consumer_scan_model.dart';
import '../../core/models/product_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/camera_capture_service.dart';
import '../../core/services/consumer_data_service.dart';
import 'consumer_scan_analysis_screen.dart';
import 'widgets/complaint_detail_modal.dart';
import 'widgets/consumer_profile_sheet.dart';
import 'widgets/my_complaints_section.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/product_comparison_modal.dart';
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
  int _currentNavIndex = 0; // 0: Home, 1: My Scans, 2: Complaints, 3: Compare
  bool _isLoading = true;
  String _userName = 'Consumer';
  String _userEmail = 'consumer@labellens.in';

  List<ConsumerScanModel> _recentScans = [];
  List<ConsumerSavedProduct> _savedProducts = [];
  List<ConsumerComplaintModel> _myComplaints = [];

  // Scans view search filter
  String _scanSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllConsumerData();
  }

  Future<void> _loadAllConsumerData() async {
    setState(() => _isLoading = true);

    // Fetch user profile name
    final userProfile = await AuthService.fetchUserProfile();
    if (userProfile != null &&
        userProfile['full_name'] != null &&
        (userProfile['full_name'] as String).isNotEmpty) {
      _userName = (userProfile['full_name'] as String).split(' ').first;
    } else {
      final email = AuthService.currentUser?.email;
      if (email != null && email.contains('@')) {
        _userName = email.split('@').first;
        _userEmail = email;
      }
    }

    // Fetch live Supabase data
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

  Future<void> _openScanLauncher() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                'Scan & Verify Product',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Point camera at packaged food labels to check Legal Metrology compliance.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  side: const BorderSide(color: AppColors.surfaceVariant),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Instant camera capture & real-time OCR analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final capture = await CameraCaptureService.captureImage(
                    context: context,
                    sourceTag: 'consumer_scan',
                    imageSource: ImageSource.camera,
                  );
                  if (capture != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConsumerScanAnalysisScreen(
                          pendingCapture: capture,
                          onScanCompleted: (newScan) {
                            setState(() {
                              _recentScans.insert(0, newScan);
                            });
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  side: const BorderSide(color: AppColors.surfaceVariant),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                ),
                title: Text(
                  'Upload Label from Gallery',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Select existing photo from gallery',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final capture = await CameraCaptureService.captureImage(
                    context: context,
                    sourceTag: 'consumer_gallery',
                    imageSource: ImageSource.gallery,
                  );
                  if (capture != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConsumerScanAnalysisScreen(
                          pendingCapture: capture,
                          onScanCompleted: (newScan) {
                            setState(() {
                              _recentScans.insert(0, newScan);
                            });
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  side: const BorderSide(color: AppColors.surfaceVariant),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.tertiary),
                ),
                title: Text(
                  'Manual Entry & Guided Scan',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Prefill product name before scanning',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openScannerModal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScannerModal({bool startWithUpload = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScannerModalSheet(
        startWithUpload: startWithUpload,
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
        onCompare: () => _openComparisonModal(),
      ),
    );
  }

  void _showComplaintDetail(ConsumerComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComplaintDetailModal(complaint: complaint),
    );
  }

  void _openComparisonModal([ProductModel? p1, ProductModel? p2]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductComparisonModal(
        initialProduct1: p1,
        initialProduct2: p2,
      ),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConsumerProfileSheet(
        userName: _userName,
        userEmail: _userEmail,
        onNavigateToScans: () => setState(() => _currentNavIndex = 1),
        onNavigateToComplaints: () => setState(() => _currentNavIndex = 2),
        onOpenNotifications: _openNotificationsSheet,
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
      body: SafeArea(
        child: RefreshIndicator(
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
                child: _buildCurrentTabContent(isDesktop),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
    );
  }



  Widget _buildCurrentTabContent(bool isDesktop) {
    switch (_currentNavIndex) {
      case 1:
        return _buildMyScansView();
      case 2:
        return _buildMyComplaintsView();
      case 3:
        return _buildCompareView();
      case 0:
      default:
        return _buildHomeDashboard(isDesktop);
    }
  }

  // --- TAB 0: HOME DASHBOARD ---
  Widget _buildHomeDashboard(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Welcome Section
        _buildWelcomeSection(),
        const SizedBox(height: AppSpacing.xl),

        // 2. Primary Scan Hero Card & Feature Strip
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ScanHeroCard(
                  onScanPressed: _openScanLauncher,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                flex: 1,
                child: QuickFeatureStrip(
                  onFeatureTap: (feature) => _openScanLauncher(),
                ),
              ),
            ],
          )
        else ...[
          ScanHeroCard(
            onScanPressed: _openScanLauncher,
          ),
          const SizedBox(height: AppSpacing.md),
          QuickFeatureStrip(
            onFeatureTap: (feature) => _openScanLauncher(),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // 3. Dynamic 2-Column Grid (Scans & Saved on Left, Report & Complaints on Right)
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
                      onViewAllTap: () => setState(() => _currentNavIndex = 1),
                      onScanNewTap: _openScanLauncher,
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
                      onComplaintTap: _showComplaintDetail,
                      onViewAllTap: () => setState(() => _currentNavIndex = 2),
                      onReportNewTap: () => _openReportDialog(),
                    ),
                  ],
                ),
              ),
            ],
          )
        else ...[
          // Mobile Vertical Stack
          RecentScansSection(
            scans: _recentScans,
            isLoading: _isLoading,
            onScanTap: _showProductSummary,
            onViewAllTap: () => setState(() => _currentNavIndex = 1),
            onScanNewTap: _openScanLauncher,
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
            onComplaintTap: _showComplaintDetail,
            onViewAllTap: () => setState(() => _currentNavIndex = 2),
            onReportNewTap: () => _openReportDialog(),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  // --- TAB 1: MY SCANS FULL VIEW ---
  Widget _buildMyScansView() {
    final filtered = _scanSearchQuery.isEmpty
        ? _recentScans
        : _recentScans
            .where((s) =>
                s.productName.toLowerCase().contains(_scanSearchQuery.toLowerCase()) ||
                s.brand.toLowerCase().contains(_scanSearchQuery.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Scan History',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openScanLauncher,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Search Bar
        TextField(
          onChanged: (val) => setState(() => _scanSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search scanned products by name or brand...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.roundedDefault,
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        RecentScansSection(
          scans: filtered,
          isLoading: _isLoading,
          onScanTap: _showProductSummary,
          onViewAllTap: () {},
          onScanNewTap: _openScanLauncher,
        ),
      ],
    );
  }

  // --- TAB 2: MY COMPLAINTS FULL VIEW ---
  Widget _buildMyComplaintsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Reported Complaints',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openReportDialog(),
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text('File Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MyComplaintsSection(
          complaints: _myComplaints,
          isLoading: _isLoading,
          onComplaintTap: _showComplaintDetail,
          onViewAllTap: () {},
          onReportNewTap: () => _openReportDialog(),
        ),
      ],
    );
  }

  // --- TAB 3: COMPARE VIEW ---
  Widget _buildCompareView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Comparison',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Compare ingredients, nutrition facts, and Legal Metrology compliance between two products side-by-side.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _openComparisonModal(),
            icon: const Icon(Icons.compare_arrows_rounded),
            label: const Text('Launch Side-by-Side Comparison'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ),
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
          'Scan a product to understand its label and check for potential issues.',
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
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
                label: 'My Scans',
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              // Center Scan FAB
              GestureDetector(
                onTap: _openScanLauncher,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppSpacing.primaryButtonShadow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.gavel_rounded,
                label: 'Complaints',
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: _openProfileSheet,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
