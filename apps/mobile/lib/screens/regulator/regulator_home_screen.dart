import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_violation.dart';
import '../../core/models/regulator_complaint.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../../widgets/regulator/regulator_metric_card.dart';
import '../../widgets/regulator/regulator_status_badge.dart';
import 'regulator_violation_review_screen.dart';
import 'regulator_complaint_inbox_screen.dart';

class RegulatorHomeScreen extends StatefulWidget {
  const RegulatorHomeScreen({super.key});

  @override
  State<RegulatorHomeScreen> createState() => _RegulatorHomeScreenState();
}

class _RegulatorHomeScreenState extends State<RegulatorHomeScreen> {
  final RegulatorNavTab _currentTab = RegulatorNavTab.home;
  String _selectedFilter = 'All Active';
  bool _isLoading = true;

  List<RegulatorViolation> _violations = [];
  RegulatorDashboardMetrics _metrics = const RegulatorDashboardMetrics(
    itemsScanned: 0,
    activeViolations: 0,
    priorityComplaints: 0,
    scanTrendPercent: 0,
  );
  StreamSubscription<List<RegulatorViolation>>? _priorityQueueSubscription;
  StreamSubscription<List<RegulatorComplaint>>? _complaintSubscription;

  final List<String> _filters = [
    'All Active',
    'High Confidence',
    'Requires Audit',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToRealtimeUpdates();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final violations = await RegulatorDataService.getFlaggedViolations();
      final metrics = await RegulatorDataService.getDashboardMetrics();

      if (mounted) {
        setState(() {
          _violations = violations;
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToRealtimeUpdates() {
    try {
      _priorityQueueSubscription = RegulatorDataService.watchPriorityQueue()
          .listen((violations) async {
            if (!mounted) return;
            try {
              final metrics = await RegulatorDataService.getDashboardMetrics();
              if (mounted) {
                setState(() {
                  _violations = violations;
                  _metrics = metrics;
                });
              }
            } catch (_) {}
          });
      _complaintSubscription = RegulatorDataService.watchComplaints().listen((
        _,
      ) async {
        if (!mounted) return;
        try {
          final metrics = await RegulatorDataService.getDashboardMetrics();
          if (mounted) {
            setState(() {
              _metrics = metrics;
            });
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _priorityQueueSubscription?.cancel();
    _complaintSubscription?.cancel();
    super.dispose();
  }

  List<RegulatorViolation> get _filteredViolations {
    switch (_selectedFilter) {
      case 'High Confidence':
        return _violations.where((v) => v.confidenceScore >= 92).toList();
      case 'Requires Audit':
        return _violations.where((v) => v.severity == 'High').toList();
      case 'Completed':
        return _violations
            .where(
              (v) => v.status == 'confirmed' || v.status == 'false_positive',
            )
            .toList();
      case 'All Active':
      default:
        return _violations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ClipRect(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
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
                        // Welcome Section
                        _buildWelcomeSection(),
                        const SizedBox(height: AppSpacing.lg),

                        // Quick Filter Chips
                        _buildFilterChips(),
                        const SizedBox(height: AppSpacing.lg),

                        // Dynamic Metric Cards Grid
                        _buildMetricGrid(),
                        const SizedBox(height: AppSpacing.xl),

                        // Priority Queue Header & List
                        _buildPriorityQueue(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
      bottomNavigationBar: RegulatorBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) =>
            RegulatorBottomNavBar.navigateToTab(context, _currentTab, tab),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Morning, Officer.',
          style: AppTypography.headlineLgMobile.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Here is your operational overview for today.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return InkWell(
            onTap: () => setState(() => _selectedFilter = filter),
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
                  filter,
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

  Widget _buildMetricGrid() {
    final trend = _metrics.scanTrendPercent;
    final trendText = '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RegulatorMetricCard(
                title: 'Items Scanned',
                value: _metrics.itemsScanned.toString(),
                icon: Icons.qr_code_scanner_rounded,
                iconColor: AppColors.tertiary,
                deltaText: trendText,
                deltaColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RegulatorMetricCard(
                title: 'Active Violations',
                value: _metrics.activeViolations.toString(),
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        RegulatorMetricCard(
          title: 'New Complaints',
          value: _metrics.priorityComplaints.toString(),
          icon: Icons.feedback_outlined,
          isFullWidth: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RegulatorComplaintInboxScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityQueue() {
    final list = _filteredViolations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Priority Queue',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 'All Active'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All (${_violations.length})',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Text(
              'No flagged violations matching selected filter.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildQueueItem(item);
            },
          ),
      ],
    );
  }

  Widget _buildQueueItem(RegulatorViolation item) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    RegulatorViolationReviewScreen(violationId: item.id),
              ),
            )
            .then((_) => _loadDashboardData());
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: AppSpacing.cardShadow,
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
                        item.productName,
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (item.companyName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 13,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.companyName,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        item.storeLocation.isNotEmpty
                            ? 'Store: ${item.storeLocation}'
                            : 'Category: ${item.category}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RegulatorStatusBadge.gavelConfidence(item.confidenceScore),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 1,
              color: AppColors.surfaceContainerHigh,
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                RegulatorStatusBadge.fromStatus(item.violationType),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.violationSummary,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
