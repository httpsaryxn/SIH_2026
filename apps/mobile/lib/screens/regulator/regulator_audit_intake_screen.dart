import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import 'regulator_violation_review_screen.dart';

class RegulatorAuditIntakeScreen extends StatefulWidget {
  const RegulatorAuditIntakeScreen({super.key});

  @override
  State<RegulatorAuditIntakeScreen> createState() =>
      _RegulatorAuditIntakeScreenState();
}

class _RegulatorAuditIntakeScreenState
    extends State<RegulatorAuditIntakeScreen> {
  int _selectedTabIndex = 0; // 0 = Photo Capture, 1 = URL / Batch Upload
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  // Processing state: 0 = Idle, 1 = Preprocessing, 2 = Text Detection, 3 = OCR, 4 = Validation, 5 = Done
  int _processingStep = 0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _urlController.dispose();
    _productNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image capture note: Using simulated sample.'),
          ),
        );
      }
    }
  }

  Future<void> _startAuditPipeline() async {
    setState(() {
      _isProcessing = true;
      _processingStep = 1;
    });

    // Step 1: Preprocessing
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _processingStep = 2);

    // Step 2: Text Detection
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _processingStep = 3);

    // Step 3: OCR Extraction
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _processingStep = 4);

    // Step 4: Rule Validation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _processingStep = 5);

    try {
      final newViolation = await RegulatorDataService.createAuditViolation(
        productName: _productNameController.text,
        companyName: _companyNameController.text,
        imagePath: _selectedImage?.path,
        imageUrl: _selectedTabIndex == 1 ? _urlController.text.trim() : null,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingStep = 0;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RegulatorViolationReviewScreen(violationId: newViolation.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingStep = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit could not be saved: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RegulatorTopAppBar(),
      body: ScrollConfiguration(
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

                const SizedBox(height: AppSpacing.lg),

                // Processing Pipeline Stepper
                _buildProcessingStepper(),
                const SizedBox(height: AppSpacing.xxl),
              ],
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
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Image / Feed
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: _selectedImage != null
                  ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                  : Container(
                      color: AppColors.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 56,
                        color: AppColors.outline,
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

          // Pick from gallery action chip
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: InkWell(
              onTap: () => _pickImage(ImageSource.gallery),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(
                    alpha: 0.85,
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
                      'Choose Photo',
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
              onTap: _isProcessing ? null : _startAuditPipeline,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? AppColors.outlineVariant
                      : AppColors.primary,
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
                  child: _isProcessing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditIdentityFields() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          TextField(
            controller: _productNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Product name',
              hintText: 'Enter the label product name',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _companyNameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Registered company name',
              hintText: 'Must match the company compliance record',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlUploadSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the product listing URL from Amazon India, Flipkart, Blinkit, or Zepto.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://www.blinkit.com/prn/organic-quinoa...',
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
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
              onPressed: _isProcessing ? null : _startAuditPipeline,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.travel_explore_rounded),
              label: Text(
                _isProcessing
                    ? 'Analyzing Listing...'
                    : 'Scrape & Verify Compliance',
              ),
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

  Widget _buildProcessingStepper() {
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
            'Processing Pipeline',
            style: AppTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPipelineStep(
            stepNumber: 1,
            title: 'Preprocessing',
            subtitle: 'Image enhanced & perspective cropped',
            state: _getStepState(1),
          ),
          _buildPipelineStep(
            stepNumber: 2,
            title: 'Text Detection',
            subtitle: 'Mandatory principal panel blocks identified',
            state: _getStepState(2),
          ),
          _buildPipelineStep(
            stepNumber: 3,
            title: 'OCR Extraction',
            subtitle: 'Reading MRP, Net Quantity & Mfg Date...',
            state: _getStepState(3),
          ),
          _buildPipelineStep(
            stepNumber: 4,
            title: 'Rule Validation',
            subtitle: 'Evaluating against PCR 2011 & LMPC statutes',
            isLast: true,
            state: _getStepState(4),
          ),
        ],
      ),
    );
  }

  // 0 = pending, 1 = active, 2 = done
  int _getStepState(int step) {
    if (_processingStep == 0) {
      // Default static illustration preview matching Stitch
      if (step <= 2) return 2;
      if (step == 3) return 1;
      return 0;
    }
    if (_processingStep > step) return 2;
    if (_processingStep == step) return 1;
    return 0;
  }

  Widget _buildPipelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required int state, // 0 = pending, 1 = active, 2 = done
    bool isLast = false,
  }) {
    Widget iconWidget;
    Color titleColor = AppColors.onSurface;

    if (state == 2) {
      // Done
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    } else if (state == 1) {
      // Active
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.tertiaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.tertiary, width: 2),
        ),
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.tertiary,
            ),
          ),
        ),
      );
      titleColor = AppColors.tertiary;
    } else {
      // Pending
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Icon(
          Icons.rule_rounded,
          size: 16,
          color: AppColors.outline,
        ),
      );
      titleColor = AppColors.onSurfaceVariant.withValues(alpha: 0.6);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                iconWidget,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == 2
                          ? AppColors.primary
                          : AppColors.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md,
                top: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: state == 1
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(
                        alpha: state == 0 ? 0.6 : 1.0,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
