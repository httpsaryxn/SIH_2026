import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/label_verification_request.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_status_badge.dart';

class RegulatorLabelReviewScreen extends StatefulWidget {
  final String requestId;

  const RegulatorLabelReviewScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<RegulatorLabelReviewScreen> createState() =>
      _RegulatorLabelReviewScreenState();
}

class _RegulatorLabelReviewScreenState
    extends State<RegulatorLabelReviewScreen> {
  final TextEditingController _notesController = TextEditingController();
  LabelVerificationRequest? _request;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await RegulatorDataService.getLabelVerificationRequestById(
        widget.requestId,
      );
      if (mounted) {
        setState(() {
          _request = data;
          _isLoading = false;
          if (data.regulatorNotes != null && data.regulatorNotes!.isNotEmpty) {
            _notesController.text = data.regulatorNotes!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load label verification request: $e';
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_request == null) return;
    setState(() => _isSubmitting = true);

    try {
      final updated = await RegulatorDataService.updateLabelVerificationStatus(
        id: _request!.id,
        status: newStatus,
        regulatorNotes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _request = updated;
          _isSubmitting = false;
        });

        final isApproved = newStatus == 'approved';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isApproved ? AppColors.primary : AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: Text(
              isApproved
                  ? 'Label ${_request!.requestCode} approved for compliance!'
                  : 'Correction notice recorded for ${_request!.requestCode}.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to update status: $e'),
          ),
        );
      }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _request?.requestCode ?? 'Label Verification Review',
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_request != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.gutter),
              child: Center(
                child: RegulatorStatusBadge.fromStatus(_request!.status),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.sm),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _loadRequest,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final req = _request!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proactive Review Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Color(0xFF1D4ED8), size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proactive Pre-Market Label Verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submitted by business for Legal Metrology PCR 2011 pre-clearance prior to commercial retail distribution.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF1E3A8A),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Business & Commodity Card
          _buildInfoCard(req),
          const SizedBox(height: AppSpacing.lg),

          // High-Res Packaging Label Image
          Text(
            'Submitted Label Packaging Artwork',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildLabelImage(req.labelImageUrl),
          const SizedBox(height: AppSpacing.lg),

          // Extracted / Declared Compliance Fields
          Text(
            'Declared Legal Metrology Fields',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildDeclarationsList(req.declarations),
          const SizedBox(height: AppSpacing.lg),

          // Regulatory Notes Input
          Text(
            'Regulatory Feedback / Officer Notes',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Enter inspection findings, required font size modifications, or clearance notes...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Decision Actions
          _buildDecisionButtons(req),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoCard(LabelVerificationRequest req) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.productName,
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'LABEL REVIEW',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 15, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.businessName,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (req.category != null && req.category!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 15, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  req.category!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFF0F172A),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 40),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeclarationsList(List<Map<String, dynamic>> declarations) {
    if (declarations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: const Text('No declaration fields extracted yet.'),
      );
    }

    return Column(
      children: declarations.map((dec) {
        final status = dec['status'] as String? ?? 'Compliant';
        final isCompliant = status == 'Compliant';
        final isWarning = status == 'Warning';

        Color badgeBg = isCompliant
            ? const Color(0xFFD1FAE5)
            : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
        Color badgeFg = isCompliant
            ? const Color(0xFF065F46)
            : (isWarning ? const Color(0xFF92400E) : const Color(0xFF991B1B));

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dec['field_name'] as String? ?? 'Mandatory Field',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dec['extracted_value'] as String? ?? '-',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
              if (dec['rule_citation'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Rule: ${dec['rule_citation']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDecisionButtons(LabelVerificationRequest req) {
    if (_isSubmitting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _updateStatus('approved'),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(
            'Approve Label Compliance',
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
          onPressed: () => _updateStatus('rejected'),
          icon: const Icon(Icons.warning_amber_rounded, size: 18),
          label: Text(
            'Request Changes / Flag Non-Compliance',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
          ),
        ),
      ],
    );
  }
}
