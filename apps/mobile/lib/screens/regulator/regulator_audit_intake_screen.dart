import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/multi_capture_payload.dart';
import '../../core/models/pending_capture.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../shared/multi_capture_screen.dart';
import 'regulator_scan_analysis_screen.dart';

class RegulatorAuditIntakeScreen extends StatefulWidget {
  const RegulatorAuditIntakeScreen({super.key});

  @override
  State<RegulatorAuditIntakeScreen> createState() =>
      _RegulatorAuditIntakeScreenState();
}

class _RegulatorAuditIntakeScreenState
    extends State<RegulatorAuditIntakeScreen> {
  int _selectedTabIndex = 0; // 0 = Photo Capture, 1 = URL / Batch Upload
  PendingCapture? _pendingCapture;
  MultiCapturePayload? _multiCapture;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  String? _productNameError;
  String? _companyNameError;

  @override
  void initState() {
    super.initState();
    _productNameController.addListener(() {
      if (_productNameError != null &&
          _productNameController.text.trim().isNotEmpty) {
        setState(() => _productNameError = null);
      }
    });
    _companyNameController.addListener(() {
      if (_companyNameError != null &&
          _companyNameController.text.trim().isNotEmpty) {
        setState(() => _companyNameError = null);
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _productNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  /// Strictly validates that both Product Name and Registered Company Name
  /// are provided prior to initiating any photo capture or verification pipeline.
  bool _validateAuditIdentity() {
    final prod = _productNameController.text.trim();
    final comp = _companyNameController.text.trim();
    bool isValid = true;

    setState(() {
      _productNameError =
          prod.isEmpty ? 'Product name is mandatory to proceed' : null;
      _companyNameError =
          comp.isEmpty ? 'Registered company name is mandatory to proceed' : null;
    });

    if (prod.isEmpty || comp.isEmpty) {
      isValid = false;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Please enter both Product Name and Registered Company Name before proceeding.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return isValid;
  }

  Future<void> _handleCapture({ImageSource source = ImageSource.camera}) async {
    // 1. Mandatory requirement: Do not proceed without product name & registered company name
    if (!_validateAuditIdentity()) return;

    final productName = _productNameController.text.trim();
    final companyName = _companyNameController.text.trim();

    // Navigate to the 3-step guided multi-capture flow
    final result = await Navigator.of(context).push<MultiCapturePayload?>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          sourceTag: 'regulator_field',
          flowLabel: 'Audit Evidence',
          productName: productName,
          companyName: companyName,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result.hasAnyCapture) {
      final primary = result.primaryCapture;
      if (primary == null) return;

      setState(() {
        _multiCapture = result;
        _pendingCapture = primary;
      });

      // Immediately navigate to the analysis/audit pipeline screen
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegulatorScanAnalysisScreen(
            multiCapture: result,
            pendingCapture: primary,
            prefilledProductName: productName,
            prefilledCompanyName: companyName,
          ),
        ),
      );
    }
  }

  Future<void> _startAuditPipeline() async {
    // 1. Mandatory requirement: Do not proceed without product name & registered company name
    if (!_validateAuditIdentity()) return;

    if (_selectedTabIndex == 1 && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please enter a valid product URL.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    if (_multiCapture != null && _multiCapture!.hasAnyCapture && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegulatorScanAnalysisScreen(
            multiCapture: _multiCapture!,
            pendingCapture: _multiCapture!.primaryCapture!,
            prefilledProductName: _productNameController.text.trim(),
            prefilledCompanyName: _companyNameController.text.trim(),
          ),
        ),
      );
      return;
    }
    if (_pendingCapture != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegulatorScanAnalysisScreen(
            pendingCapture: _pendingCapture!,
            prefilledProductName: _productNameController.text.trim(),
            prefilledCompanyName: _companyNameController.text.trim(),
          ),
        ),
      );
      return;
    }

    // Trigger capture first if none selected
    await _handleCapture(source: ImageSource.camera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Audit Intake',
                    style: AppTypography.headlineLgMobile.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Capture or upload packaged food labels for automated PCR 2011 compliance checking.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Intake Tabs
                  _buildIntakeTabs(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildAuditIdentityFields(),
                  const SizedBox(height: AppSpacing.lg),

                  // Viewfinder / Upload Section
                  if (_selectedTabIndex == 0)
                    _buildCameraViewfinder()
                  else
                    _buildUrlUploadSection(),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: RegulatorBottomNavBar(
        currentTab: RegulatorNavTab.audit,
        onTabSelected: (tab) => RegulatorBottomNavBar.navigateToTab(
          context,
          RegulatorNavTab.audit,
          tab,
        ),
      ),
    );
  }

  Widget _buildIntakeTabs() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_rounded,
                      size: 18,
                      color: _selectedTabIndex == 0
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Field Photo Capture',
                      style: AppTypography.labelMd.copyWith(
                        color: _selectedTabIndex == 0
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 18,
                      color: _selectedTabIndex == 1
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'E-Commerce URL',
                      style: AppTypography.labelMd.copyWith(
                        color: _selectedTabIndex == 1
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    final hasCapture = _pendingCapture != null && _pendingCapture!.existsSync;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: hasCapture ? AppColors.primary : AppColors.outlineVariant,
              width: hasCapture ? 2 : 1,
            ),
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Image / Feed
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                  child: hasCapture
                      ? Image.file(_pendingCapture!.file, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF0F172A),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 36,
                                  color: AppColors.primaryFixedDim,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Scan Packaging Label',
                                style: AppTypography.labelMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                child: Text(
                                  'Position the product label inside the frame and tap the shutter button.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySm.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Camera Overlay Corner Guides
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Stack(
                    children: [
                      // Top Left
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                              left: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top Right
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                              right: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Left
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                              left: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Right
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                              right: BorderSide(
                                color: AppColors.primaryFixed,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Left Cache Status Badge
              if (hasCapture)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Cached (${_pendingCapture!.formattedSize})',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Pick from gallery action chip
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: InkWell(
                  onTap: () => _handleCapture(source: ImageSource.gallery),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_rounded,
                          size: 16,
                          color: AppColors.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gallery',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Shutter Button
              Positioned(
                bottom: AppSpacing.lg,
                child: GestureDetector(
                  onTap: () => _handleCapture(source: ImageSource.camera),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33006E2F),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            hasCapture ? Icons.refresh_rounded : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          hasCapture ? 'Tap to Retake' : 'Tap to Capture',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
        if (hasCapture) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                elevation: 0,
              ),
              onPressed: _startAuditPipeline,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                'Verify Packaging Label',
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuditIdentityFields() {
    final hasErrors = _productNameError != null || _companyNameError != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasErrors
              ? AppColors.error.withValues(alpha: 0.7)
              : AppColors.surfaceVariant,
          width: hasErrors ? 1.5 : 1,
        ),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: hasErrors
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  hasErrors
                      ? Icons.error_outline_rounded
                      : Icons.assignment_turned_in_rounded,
                  size: 15,
                  color: hasErrors ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'MANDATORY AUDIT IDENTIFIERS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: hasErrors ? AppColors.error : AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Both product name and registered company name are legally required before capturing label evidence.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _productNameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Product name *',
              hintText: 'e.g. Britannia Good Day Butter Cookies',
              errorText: _productNameError,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _companyNameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Registered company name *',
              hintText: 'e.g. Britannia Industries Ltd',
              errorText: _companyNameError,
              prefixIcon: const Icon(Icons.business_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlUploadSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'E-Commerce Product URL',
            style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Paste an Amazon, Flipkart, or Blinkit product page URL to audit declarations.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://www.amazon.in/dp/B08XYZ123',
              prefixIcon: const Icon(Icons.link_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startAuditPipeline,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Scrape & Verify Compliance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
