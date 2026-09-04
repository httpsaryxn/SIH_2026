import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/capture_role.dart';
import '../../core/models/multi_capture_payload.dart';
import '../../core/services/camera_capture_service.dart';

/// A 3-step guided capture screen shared by both consumer and regulator flows.
///
/// Sequentially captures images for [CaptureRole.frontLabel],
/// [CaptureRole.curvedSurface], and [CaptureRole.scaleReference].
///
/// Returns a completed [MultiCapturePayload] via `Navigator.pop(payload)`.
class MultiCaptureScreen extends StatefulWidget {
  /// Tag used for CameraCaptureService source identification
  final String sourceTag;

  /// Optional title prefix (e.g., "Consumer" or "Regulator")
  final String flowLabel;

  /// Optional product name being audited
  final String? productName;

  /// Optional company name being audited
  final String? companyName;

  const MultiCaptureScreen({
    super.key,
    required this.sourceTag,
    this.flowLabel = 'Label',
    this.productName,
    this.companyName,
  });

  @override
  State<MultiCaptureScreen> createState() => _MultiCaptureScreenState();
}

class _MultiCaptureScreenState extends State<MultiCaptureScreen>
    with SingleTickerProviderStateMixin {
  final MultiCapturePayload _payload = MultiCapturePayload();
  final Map<CaptureRole, Uint8List?> _previewBytes = {};
  int _currentStepIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<CaptureRole> get _roles => CaptureRoleInfo.orderedRoles;
  CaptureRole get _currentRole => _roles[_currentStepIndex];
  CaptureRoleInfo get _currentRoleInfo => CaptureRoleInfo.forRole(_currentRole);
  bool get _isLastStep => _currentStepIndex == _roles.length - 1;
  bool get _currentHasCapture => _payload.getForRole(_currentRole) != null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureForCurrentRole(ImageSource source) async {
    final capture = await CameraCaptureService.captureImage(
      context: context,
      sourceTag: '${widget.sourceTag}_${_currentRole.name}',
      imageSource: source,
    );

    if (capture != null && mounted) {
      final bytes = await capture.file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _payload.setForRole(_currentRole, capture);
        _previewBytes[_currentRole] = bytes;
      });
    }
  }

  void _retakeCurrentRole() {
    setState(() {
      _payload.clearForRole(_currentRole);
      _previewBytes.remove(_currentRole);
    });
  }

  void _skipCurrentRole() {
    _goToNextStep();
  }

  void _goToNextStep() {
    if (_isLastStep) {
      _finishCapture();
    } else {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _finishCapture() {
    if (_payload.hasAnyCapture) {
      Navigator.of(context).pop(_payload);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please capture at least one image before proceeding.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () {
            if (_currentStepIndex > 0) {
              _goToPreviousStep();
            } else {
              Navigator.of(context).pop(null);
            }
          },
        ),
        title: Text(
          '${widget.flowLabel} Capture',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '${_payload.capturedCount}/${_roles.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product / Company Audit Banner
                    if (widget.productName?.isNotEmpty == true ||
                        widget.companyName?.isNotEmpty == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusDefault),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                [
                                  if (widget.productName?.isNotEmpty == true)
                                    widget.productName!,
                                  if (widget.companyName?.isNotEmpty == true)
                                    widget.companyName!,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Step Progress Indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),

                    // Role Guidance Card
                    _buildRoleGuidanceCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // Image Preview / Viewfinder
                    _buildImageViewport(),
                    const SizedBox(height: AppSpacing.lg),

                    // Capture Buttons
                    _buildCaptureButtons(),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_roles.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepBefore = i ~/ 2;
          final isDone = _payload.getForRole(_roles[stepBefore]) != null;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF10B981)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final role = _roles[stepIndex];
        final roleInfo = CaptureRoleInfo.forRole(role);
        final isCurrent = stepIndex == _currentStepIndex;
        final isDone = _payload.getForRole(role) != null;

        return GestureDetector(
          onTap: () {
            if (stepIndex <= _currentStepIndex || isDone) {
              setState(() => _currentStepIndex = stepIndex);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 48 : 40,
            height: isCurrent ? 48 : 40,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : (isCurrent
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerHigh),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: AppColors.primary, width: 2.5)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 20, color: Color(0xFF10B981))
                  : Icon(
                      roleInfo.icon,
                      size: isCurrent ? 22 : 18,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoleGuidanceCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentRole),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Icon(
                      _currentRoleInfo.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${_currentStepIndex + 1} of ${_roles.length}: ${_currentRoleInfo.label}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        _currentRoleInfo.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _currentRoleInfo.guidanceText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewport() {
    final hasPreview = _previewBytes[_currentRole] != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${_currentRole}_$hasPreview'),
        height: 260,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasPreview ? const Color(0xFF10B981) : AppColors.primary,
            width: 2,
          ),
          boxShadow: AppSpacing.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasPreview)
              Positioned.fill(
                child: Image.memory(
                  _previewBytes[_currentRole]!,
                  fit: BoxFit.cover,
                ),
              )
            else
              // Empty viewfinder state
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryFixed,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Center(
                            child: Icon(
                              _currentRoleInfo.icon,
                              size: 40,
                              color: AppColors.primaryFixed,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tap below to capture ${_currentRoleInfo.label}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),

            // Dark vignette overlay on captured image
            if (hasPreview)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),

            // Top-left role badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPreview
                          ? Icons.check_circle_rounded
                          : _currentRoleInfo.icon,
                      size: 14,
                      color: hasPreview
                          ? const Color(0xFF10B981)
                          : AppColors.primaryFixedDim,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasPreview
                          ? '${_currentRoleInfo.label} ✓'
                          : _currentRoleInfo.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right retake button (when captured)
            if (hasPreview)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _retakeCurrentRole,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Retake',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
    );
  }

  Widget _buildCaptureButtons() {
    if (_currentHasCapture) {
      // Already captured — show retake and gallery options
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _captureForCurrentRole(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Retake Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _captureForCurrentRole(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text('Replace from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Not yet captured — show camera and gallery capture buttons
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _captureForCurrentRole(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded, size: 20),
          label: Text(
            'Capture ${_currentRoleInfo.label}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _captureForCurrentRole(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded, size: 18),
          label: const Text('Upload from Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Skip button
          if (!_currentHasCapture)
            TextButton(
              onPressed: _skipCurrentRole,
              child: Text(
                'Skip',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),

          const Spacer(),

          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_roles.length, (i) {
              final isDone = _payload.getForRole(_roles[i]) != null;
              final isCurrent = i == _currentStepIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981)
                      : (isCurrent
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const Spacer(),

          // Next / Finish button
          ElevatedButton.icon(
            onPressed: _currentHasCapture || _isLastStep
                ? _goToNextStep
                : null,
            icon: Icon(
              _isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
              size: 18,
            ),
            label: Text(
              _isLastStep ? 'Done' : 'Next',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
