import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/consumer_complaint_model.dart';
import '../../core/models/consumer_saved_product.dart';
import '../../core/models/consumer_scan_model.dart';
import '../../core/models/product_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/camera_capture_service.dart';
import '../../core/services/consumer_data_service.dart';
import '../../core/widgets/label_lens_brand.dart';
import '../onboarding/role_selection_screen.dart';
import 'consumer_profile_screen.dart';
import 'consumer_scan_analysis_screen.dart';
import 'widgets/complaint_detail_modal.dart';
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
  int _currentNavIndex = 0; // 0: Home, 1: My Scans, 2: Complaints, 3: Compare, 4: Profile
  bool _isLoading = true;
  bool _isSigningOut = false;
  String _userName = 'Consumer';
  String _fullProfileName = 'Consumer';
  String _userEmail = 'consumer@labellens.in';
  String _createdAt = '2026';

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
    if (userProfile != null) {
      if (userProfile['full_name'] != null &&
          (userProfile['full_name'] as String).isNotEmpty) {
        _fullProfileName = userProfile['full_name'] as String;
        _userName = _fullProfileName.split(' ').first;
      }
      if (userProfile['email'] != null &&
          (userProfile['email'] as String).isNotEmpty) {
        _userEmail = userProfile['email'] as String;
      }
      if (userProfile['created_at'] != null) {
        final dt = DateTime.tryParse(userProfile['created_at'].toString());
        if (dt != null) {
          _createdAt = '${dt.day}/${dt.month}/${dt.year}';
        }
      }
    } else {
      final user = AuthService.currentUser;
      if (user != null) {
        final email = user.email;
        if (email != null && email.contains('@')) {
          _userName = email.split('@').first;
          _userEmail = email;
        }
        if (user.userMetadata != null && user.userMetadata!['full_name'] != null) {
          _fullProfileName = user.userMetadata!['full_name'] as String;
          _userName = _fullProfileName.split(' ').first;
        }
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

  void _openReportDialog({
    String? prefilledProductName,
    String? prefilledBrand,
    ConsumerScanModel? prefilledScan,
    String? prefilledEvidenceUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => ReportComplaintDialog(
        prefilledProductName: prefilledProductName ?? prefilledScan?.productName,
        prefilledBrand: prefilledBrand ?? prefilledScan?.brand,
        prefilledScan: prefilledScan,
        prefilledEvidenceUrl: prefilledEvidenceUrl ?? prefilledScan?.imageUrl,
        recentScans: _recentScans,
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
          Navigator.of(context).pop();
          _openReportDialog(
            prefilledScan: scan,
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
    setState(() => _currentNavIndex = 4);
  }

  PreferredSizeWidget _buildProfileAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 60.0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          height: 1.0,
        ),
      ),
      title: Text(
        'Consumer Profile',
        style: AppTypography.headlineSm.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          fontSize: 18,
        ),
      ),
    );
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
          'Are you sure you want to log out of your consumer session?',
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
      appBar: _currentNavIndex == 4 ? _buildProfileAppBar() : null,
      body: SafeArea(
        top: _currentNavIndex != 4,
        child: RefreshIndicator(
          onRefresh: _loadAllConsumerData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: _currentNavIndex == 4 ? AppSpacing.gutter : horizontalPadding,
              vertical: _currentNavIndex == 4 ? AppSpacing.md : AppSpacing.lg,
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
      case 4:
        return ConsumerProfileBody(
          userName: _fullProfileName.isNotEmpty ? _fullProfileName : _userName,
          userEmail: _userEmail,
          createdAt: _createdAt,
          onSignOut: _handleSignOut,
          isSigningOut: _isSigningOut,
        );
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
                      recentScans: _recentScans,
                      isLoading: _isLoading,
                      onComplaintTap: _showComplaintDetail,
                      onReportScan: (scan) => _openReportDialog(prefilledScan: scan),
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
            recentScans: _recentScans,
            isLoading: _isLoading,
            onComplaintTap: _showComplaintDetail,
            onReportScan: (scan) => _openReportDialog(prefilledScan: scan),
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
          children: [
            Expanded(
              child: Text(
                'My Scan History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: _openScanLauncher,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          children: [
            Expanded(
              child: Text(
                'My Complaints',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => _openReportDialog(),
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text('File Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_recentScans.isNotEmpty) ...[
          _buildRecentlyScannedForComplaints(),
          const SizedBox(height: AppSpacing.lg),
        ],
        MyComplaintsSection(
          complaints: _myComplaints,
          recentScans: _recentScans,
          isLoading: _isLoading,
          onComplaintTap: _showComplaintDetail,
          onReportScan: (scan) => _openReportDialog(prefilledScan: scan),
          onViewAllTap: () {},
          onReportNewTap: () => _openReportDialog(),
        ),
      ],
    );
  }

  Widget _buildRecentlyScannedForComplaints() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Recently Scanned Products',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recentScans.length} available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select any scanned product to file a Legal Metrology complaint or report non-compliance:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentScans.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final scan = _recentScans[index];
                return InkWell(
                  onTap: () => _openReportDialog(prefilledScan: scan),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      scan.imageUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 36,
                                        height: 36,
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(Icons.inventory_2_outlined, size: 20),
                                      ),
                                    )
                                  : Container(
                                      width: 36,
                                      height: 36,
                                      color: AppColors.surfaceVariant,
                                      child: const Icon(Icons.inventory_2_outlined, size: 20),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scan.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    scan.brand,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openReportDialog(prefilledScan: scan),
                            icon: const Icon(Icons.campaign_outlined, size: 14),
                            label: const Text('Report Issue', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorContainer.withValues(alpha: 0.7),
                              foregroundColor: AppColors.error,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const LabelLensBrand(
              logoSize: 28,
              fontSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.onSurfaceVariant),
              tooltip: 'Notifications',
              onPressed: _openNotificationsSheet,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
