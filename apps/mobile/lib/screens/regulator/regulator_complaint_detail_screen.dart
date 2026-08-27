import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_complaint.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../widgets/regulator/regulator_status_badge.dart';

class RegulatorComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const RegulatorComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<RegulatorComplaintDetailScreen> createState() =>
      _RegulatorComplaintDetailScreenState();
}

class _RegulatorComplaintDetailScreenState
    extends State<RegulatorComplaintDetailScreen> {
  RegulatorComplaint? _complaint;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  final int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchComplaint();
  }

  Future<void> _fetchComplaint() async {
    setState(() => _isLoading = true);
    final data = await RegulatorDataService.getComplaintById(widget.complaintId);
    if (mounted) {
      setState(() {
        _complaint = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyAndForward() async {
    if (_complaint == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    await RegulatorDataService.verifyAndForwardComplaint(_complaint!.id);
    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complaint ${_complaint!.complaintCode} verified & forwarded for field inspection.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _handleReject() async {
    if (_complaint == null || _isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    await RegulatorDataService.rejectComplaint(_complaint!.id);
    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complaint ${_complaint!.complaintCode} marked as rejected.'),
        backgroundColor: AppColors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: RegulatorTopAppBar(
          customTitle: 'Complaint Details',
          showBackButton: true,
          showNotifications: false,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final complaint = _complaint!;
    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(complaint.submittedAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RegulatorTopAppBar(
        customTitle: 'Complaint Details',
        showBackButton: true,
        showNotifications: false,
      ),
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
                // Badges row
                Row(
                  children: [
                    RegulatorStatusBadge.fromStatus(complaint.priority),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                      child: Text(
                        'ID: ${complaint.complaintCode}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Title
                Text(
                  complaint.title,
                  style: AppTypography.headlineMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted $formattedDate',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Evidence Photos Gallery
                _buildEvidenceGallery(complaint),
                const SizedBox(height: AppSpacing.lg),

                // Consumer Report Box
                _buildConsumerReportCard(complaint),
                const SizedBox(height: AppSpacing.md),

                // Location Data Box
                _buildLocationDataCard(complaint),
                const SizedBox(height: AppSpacing.md),

                // Consumer Profile
                _buildConsumerProfileCard(complaint),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyActions(),
    );
  }

  Widget _buildEvidenceGallery(RegulatorComplaint complaint) {
    final photos = complaint.evidencePhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence Photos',
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Stack(
            children: [
              if (photos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.network(
                    photos[_currentPhotoIndex],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 48, color: AppColors.outline),
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(Icons.photo_outlined,
                      size: 48, color: AppColors.outline),
                ),

              // Pagination pill
              if (photos.length > 1)
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'Photo ${_currentPhotoIndex + 1} of ${photos.length}',
                      style: AppTypography.labelSm.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsumerReportCard(RegulatorComplaint complaint) {
    return Container(
      width: double.infinity,
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
            'Consumer Report',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"${complaint.description}"',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDataCard(RegulatorComplaint complaint) {
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
          Row(
            children: [
              const Icon(
                Icons.pin_drop_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Location Data',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: const Center(
                  child: Icon(
                    Icons.map_rounded,
                    size: 32,
                    color: AppColors.outline,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.locationName,
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      complaint.address,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (complaint.coordinates.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Coords: ${complaint.coordinates}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.tertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerProfileCard(RegulatorComplaint complaint) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.consumerName,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  complaint.consumerContact,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
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
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isActionInProgress ? null : _handleReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _isActionInProgress ? null : _handleVerifyAndForward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
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
                            'Verify & Forward',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
