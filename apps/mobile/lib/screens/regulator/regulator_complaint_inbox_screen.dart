import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_complaint.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../../widgets/regulator/regulator_status_badge.dart';
import 'regulator_complaint_detail_screen.dart';

class RegulatorComplaintInboxScreen extends StatefulWidget {
  const RegulatorComplaintInboxScreen({super.key});

  @override
  State<RegulatorComplaintInboxScreen> createState() =>
      _RegulatorComplaintInboxScreenState();
}

class _RegulatorComplaintInboxScreenState
    extends State<RegulatorComplaintInboxScreen> {
  String _selectedStatus = 'All';
  bool _isLoading = true;
  List<RegulatorComplaint> _complaints = [];
  StreamSubscription<List<RegulatorComplaint>>? _complaintSubscription;

  final List<String> _statusTabs = [
    'All',
    'Submitted',
    'Under Review',
    'Verified',
    'Forwarded',
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _subscribeToComplaintUpdates();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await RegulatorDataService.getComplaints(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _complaints = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToComplaintUpdates() {
    try {
      _complaintSubscription?.cancel();
      _complaintSubscription =
          RegulatorDataService.watchComplaints(
            status: _selectedStatus == 'All' ? null : _selectedStatus,
          ).listen((complaints) {
            if (mounted) setState(() => _complaints = complaints);
          });
    } catch (_) {}
  }

  @override
  void dispose() {
    _complaintSubscription?.cancel();
    super.dispose();
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
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
          child: RefreshIndicator(
            onRefresh: _loadComplaints,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Inbox',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review pending consumer complaints and compliance flags.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filter Tabs
                  _buildFilterTabs(),
                  const SizedBox(height: AppSpacing.md),

                  // Complaints List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_complaints.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Text(
                        'No complaints matching "$_selectedStatus".',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _complaints.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final complaint = _complaints[index];
                        return _buildComplaintCard(complaint);
                      },
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: RegulatorBottomNavBar(
        currentTab: RegulatorNavTab.inbox,
        onTabSelected: (tab) => RegulatorBottomNavBar.navigateToTab(
          context,
          RegulatorNavTab.inbox,
          tab,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusTabs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = _statusTabs[index];
          final isSelected = tab == _selectedStatus;

          return InkWell(
            onTap: () {
              setState(() => _selectedStatus = tab);
              _loadComplaints();
              _subscribeToComplaintUpdates();
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: AppTypography.labelMd.copyWith(
                    color: isSelected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(RegulatorComplaint complaint) {
    final timeAgo = _formatRelativeTime(complaint.submittedAt);
    final displayTitle = complaint.productName.isNotEmpty
        ? complaint.productName
        : complaint.title;

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    RegulatorComplaintDetailScreen(complaintId: complaint.id),
              ),
            )
            .then((_) => _loadComplaints());
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Evidence Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                child: complaint.evidencePhotos.isNotEmpty
                    ? Image.network(
                        complaint.evidencePhotos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.report_problem_rounded,
                                size: 32,
                                color: AppColors.outline,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.report_problem_rounded,
                          size: 32,
                          color: AppColors.outline,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Complaint Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          RegulatorStatusBadge.fromStatus(complaint.priority),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              complaint.complaintCode,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTitle,
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (complaint.companyName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Brand: ${complaint.companyName} • ${complaint.category}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    complaint.description,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          complaint.locationName.isNotEmpty
                              ? complaint.locationName
                              : complaint.address,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RegulatorStatusBadge.fromStatus(complaint.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
