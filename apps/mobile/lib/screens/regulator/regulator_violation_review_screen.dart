import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_violation.dart';
import '../../core/services/regulator_data_service.dart';
import '../../core/services/summary_gen_client.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../core/widgets/markdown_content_view.dart';
import 'regulator_notice_generator_screen.dart';
import 'regulator_company_tracking_screen.dart';

class RegulatorViolationReviewScreen extends StatefulWidget {
  final String violationId;

  const RegulatorViolationReviewScreen({
    super.key,
    required this.violationId,
  });

  @override
  State<RegulatorViolationReviewScreen> createState() =>
      _RegulatorViolationReviewScreenState();
}

class _RegulatorViolationReviewScreenState
    extends State<RegulatorViolationReviewScreen> {
  RegulatorViolation? _violation;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  bool _isGeneratingPdf = false;
  RegulatorSummaryResult? _regulatorSummary;

  // Carousel state
  final PageController _carouselController = PageController();
  int _carouselPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchViolation();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _fetchViolation() async {
    setState(() => _isLoading = true);
    final data = await RegulatorDataService.getViolationById(widget.violationId);
    if (mounted) {
      setState(() {
        _violation = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirmViolation() async {
    if (_violation == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    await RegulatorDataService.confirmViolation(_violation!.id);
    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Violation confirmed. Generating Show-Cause notice draft...'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RegulatorNoticeGeneratorScreen(violationId: _violation!.id),
      ),
    );
  }

  Future<void> _handleMarkFalsePositive() async {
    if (_violation == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    await RegulatorDataService.markFalsePositive(_violation!.id);
    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item marked as False Positive. Case resolved.'),
        backgroundColor: AppColors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _handleEscalate() async {
    if (_violation == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    await RegulatorDataService.escalateViolation(_violation!.id);
    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Violation escalated to Senior Metrology Controller.'),
        backgroundColor: AppColors.tertiary,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RegulatorCompanyTrackingScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );
  }

  void _showZoomDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: RegulatorTopAppBar(
          customTitle: 'Review Violation',
          showBackButton: true,
          showNotifications: false,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final violation = _violation!;
    final formattedDate =
        DateFormat('MMM dd, yyyy \'at\' HH:mm').format(violation.capturedAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RegulatorTopAppBar(
        customTitle: 'Review Violation',
        showBackButton: true,
        showNotifications: false,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ClipRect(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Evidence Image Carousel
                _buildImageCarousel(violation),

                // Product Context
                _buildProductContext(violation, formattedDate),

                // Formal Audit Report Card (PDF + Groq Summary)
                _buildFormalReportCard(violation),

                // Extracted Declarations Section Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: Text(
                    'Extracted Declarations',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),

                // Extracted Declarations Groups (Compliant vs Non-Compliant)
                _buildDeclarationGroups(violation),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyActions(),
    );
  }

  /// Smooth horizontal carousel showing all captured evidence images
  /// with role labels, page indicators, and zoom support.
  Widget _buildImageCarousel(RegulatorViolation violation) {
    final images = violation.allLabeledImages;
    final imageCount = images.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = imageWidth * 0.85; // Slightly shorter than square

        return Container(
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              // ── PageView Carousel ──
              SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _carouselController,
                      itemCount: imageCount,
                      onPageChanged: (index) {
                        setState(() => _carouselPage = index);
                      },
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final entry = images[index];
                        final url = entry.value;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryFixed,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_not_supported_rounded,
                                        size: 48, color: Colors.white38),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image unavailable',
                                      style: AppTypography.bodySm.copyWith(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Subtle bottom gradient for readability
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.55, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.55),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Overlay bounding boxes (only on the first image / front label)
                            if (index == 0)
                              for (final box in violation.overlayBoxes)
                                Positioned(
                                  top: imageHeight * box.topPercent,
                                  left: imageWidth * box.leftPercent,
                                  width: imageWidth * box.widthPercent,
                                  height: imageHeight * box.heightPercent,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: box.isViolation
                                                ? AppColors.error
                                                : AppColors.primary,
                                            width: 2,
                                          ),
                                          color: (box.isViolation
                                                  ? AppColors.error
                                                  : AppColors.primary)
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      Positioned(
                                        top: -24,
                                        left: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: box.isViolation
                                                ? AppColors.error
                                                : AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            box.label,
                                            style: AppTypography.labelSm.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        );
                      },
                    ),

                    // ── Role Label Pill (top-left) ──
                    Positioned(
                      top: 14,
                      left: 14,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(_carouselPage),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _carouselPage == 0
                                    ? Icons.label_rounded
                                    : (_carouselPage == 1
                                        ? Icons.panorama_horizontal_rounded
                                        : Icons.straighten_rounded),
                                size: 14,
                                color: AppColors.primaryFixed,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                images[_carouselPage].key,
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Image Counter Pill (top-right) ──
                    if (imageCount > 1)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${_carouselPage + 1} / $imageCount',
                            style: AppTypography.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    // ── Zoom Button (bottom-right) ──
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: InkWell(
                        onTap: () => _showZoomDialog(images[_carouselPage].value),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppSpacing.cardShadow,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: AppColors.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // ── Swipe hint on first image ──
                    if (imageCount > 1 && _carouselPage == 0)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swipe_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text(
                                  'Swipe for more evidence',
                                  style: AppTypography.labelSm.copyWith(
                                    color: Colors.white70,
                                    fontSize: 11,
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
              ),

              // ── Smooth Page Dots ──
              if (imageCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imageCount, (i) {
                      final isActive = i == _carouselPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryFixed
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductContext(
      RegulatorViolation violation, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      violation.productName,
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (violation.companyName.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.business_rounded,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Company: ${violation.companyName}',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Scan ID: ${violation.scanId}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      violation.riskLevel,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Captured on $formattedDate',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.secondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confirm Violation Primary Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isActionInProgress ? null : _handleConfirmViolation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: _isActionInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm Violation',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Secondary Action Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed:
                            _isActionInProgress ? null : _handleMarkFalsePositive,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLow,
                          side: const BorderSide(color: AppColors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                        child: Text(
                          'Mark False Positive',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _isActionInProgress ? null : _handleEscalate,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLowest,
                          side: const BorderSide(color: AppColors.tertiary),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                        child: Text(
                          'Escalate',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeclarationGroups(RegulatorViolation violation) {
    final nonCompliant = violation.declarations.where((d) =>
        d.isViolation ||
        d.isWarning ||
        d.status.toLowerCase().contains('violation') ||
        d.status.toLowerCase().contains('fail') ||
        d.status.toLowerCase().contains('missing') ||
        d.status.toLowerCase().contains('unable') ||
        d.status.toLowerCase().contains('inconclusive')).toList();

    final compliant = violation.declarations.where((d) =>
        d.isCompliant ||
        d.status.toLowerCase() == 'pass' ||
        d.status.toLowerCase() == 'compliant').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group 1: Non-Compliant / Missing Declarations ──
          _buildGroupHeader(
            title: 'Non-Compliant & Missing Declarations',
            count: nonCompliant.length,
            isError: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (nonCompliant.isEmpty)
            _buildEmptyGroupPlaceholder('No violations or missing declarations found.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nonCompliant.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _buildDeclarationRow(
                declaration: nonCompliant[index],
                isNonCompliant: true,
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // ── Group 2: Compliant Declarations ──
          _buildGroupHeader(
            title: 'Compliant Declarations',
            count: compliant.length,
            isError: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (compliant.isEmpty)
            _buildEmptyGroupPlaceholder('No declarations verified as compliant.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: compliant.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _buildDeclarationRow(
                declaration: compliant[index],
                isNonCompliant: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader({
    required String title,
    required int count,
    required bool isError,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isError
                ? AppColors.errorContainer
                : AppColors.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '$count',
            style: AppTypography.labelSm.copyWith(
              color: isError
                  ? AppColors.onErrorContainer
                  : AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGroupPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        message,
        style: AppTypography.bodySm.copyWith(
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildDeclarationRow({
    required RegulatorDeclaration declaration,
    required bool isNonCompliant,
  }) {
    final statusColor = isNonCompliant ? AppColors.error : AppColors.primary;
    final statusBg = isNonCompliant
        ? AppColors.errorContainer
        : AppColors.primaryContainer.withValues(alpha: 0.25);
    final statusText = isNonCompliant
        ? AppColors.onErrorContainer
        : AppColors.onPrimaryContainer;

    final extractedValue = declaration.extractedValue.trim();
    final displayText = extractedValue.isNotEmpty
        ? extractedValue
        : (isNonCompliant ? 'Not detected' : 'Verified');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isNonCompliant
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color status indicator bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            // Row content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Name and Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            declaration.fieldName,
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            declaration.status,
                            style: AppTypography.labelSm.copyWith(
                              color: statusText,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Extracted Value
                    Text(
                      displayText,
                      style: AppTypography.bodyMd.copyWith(
                        color: extractedValue.isEmpty && isNonCompliant
                            ? AppColors.error
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                    // Secondary info: Rule citation & Confidence
                    if (declaration.ruleCitation.isNotEmpty || declaration.confidencePercent > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (declaration.ruleCitation.isNotEmpty)
                            Expanded(
                              child: Text(
                                declaration.ruleCitation,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (declaration.confidencePercent > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${declaration.confidencePercent}% conf',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormalReportCard(RegulatorViolation violation) {
    final hasReport = _regulatorSummary != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasReport ? const Color(0xFFF8FAFC) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasReport ? const Color(0xFF0284C7) : AppColors.borderSubtle,
          width: hasReport ? 1.5 : 1,
        ),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hasReport ? const Color(0xFF0284C7) : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 20,
                  color: hasReport ? const Color(0xFF0284C7) : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Formal Audit Report',
                          style: AppTypography.headlineSm.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (hasReport) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'READY',
                              style: AppTypography.labelSm.copyWith(
                                color: const Color(0xFF047857),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Statutory PCR 2011 compliance matrix & comparison PDF',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasReport) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                _regulatorSummary!.summaryText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  color: AppColors.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportDialog(_regulatorSummary!),
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text('View Summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdfUrl(_regulatorSummary!.pdfUrl),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Open PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed:
                    _isGeneratingPdf ? null : () => _handleGenerateFormalReport(),
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(
                  _isGeneratingPdf
                      ? 'Compiling Audit & PDF...'
                      : 'Generate Formal Report (PDF)',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleGenerateFormalReport() async {
    if (_violation == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final checks = _violation!.declarations.map((d) {
        return {
          'field_name': d.fieldName,
          'extracted_value': d.extractedValue,
          'status': d.status.toUpperCase(),
          'rule_citation': d.ruleCitation,
          'rule_description': d.ruleDescription,
          'confidence_percent': d.confidencePercent,
        };
      }).toList();

      final imageUrls = <String, String?>{
        'front': _violation!.frontLabelUrl ?? _violation!.imageUrl,
        'curved': _violation!.curvedSurfaceUrl,
        'scale': _violation!.scaleReferenceUrl,
      };

      final result = await SummaryGenClient.summarizeRegulator(
        scanId: widget.violationId,
        productName: _violation!.productName,
        companyName: _violation!.companyName,
        category: _violation!.category,
        declarationChecks: checks,
        imageUrls: imageUrls,
        forceRegenerate: false,
      );

      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _regulatorSummary = result;
        });

        if (result != null) {
          _showReportDialog(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Failed to generate audit report. Please check summary-gen service.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error generating report: $e'),
          ),
        );
      }
    }
  }

  Future<void> _openPdfUrl(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF URL available.')),
      );
      return;
    }
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch browser for URL');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF: $e\nURL: $url'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showReportDialog(RegulatorSummaryResult result) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Formal Audit Report',
                style: AppTypography.headlineSm.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Case Scan ID: ${result.scanId}',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Executive Audit Summary (Groq LLM):',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                MarkdownContentView(
                  text: result.summaryText,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The PDF report includes a complete statutory PCR 2011 comparison table and captured evidence photos.',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11.5,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
            ),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _openPdfUrl(result.pdfUrl);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Formal PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
