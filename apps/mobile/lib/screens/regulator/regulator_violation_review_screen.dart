import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_violation.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../widgets/regulator/regulator_declaration_card.dart';
import 'regulator_notice_generator_screen.dart';

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

                // Extracted Declarations List
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Declarations',
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: violation.declarations.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final declaration = violation.declarations[index];
                          return RegulatorDeclarationCard(declaration: declaration);
                        },
                      ),
                    ],
                  ),
                ),
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
}
