import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_action_item.dart';
import '../../core/models/regulator_company.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../../widgets/regulator/regulator_timeline_tile.dart';
import 'regulator_complaint_detail_screen.dart';
import 'regulator_label_review_screen.dart';
import 'regulator_violation_review_screen.dart';

class RegulatorCompanyTrackingScreen extends StatefulWidget {
  final int initialTabIndex;
  const RegulatorCompanyTrackingScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<RegulatorCompanyTrackingScreen> createState() =>
      _RegulatorCompanyTrackingScreenState();
}

class _RegulatorCompanyTrackingScreenState
    extends State<RegulatorCompanyTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Section A: My Actions state
  List<RegulatorActionItem> _myActions = [];
  bool _isLoadingActions = true;

  // Section B: Company Compliance state
  List<RegulatorCompany> _companies = [];
  bool _isLoadingCompanies = true;
  final Set<String> _expandedCompanyIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadMyActions();
    _loadCompanies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyActions() async {
    setState(() => _isLoadingActions = true);
    try {
      final actions = await RegulatorDataService.getMyActionedItems();
      if (mounted) {
        setState(() {
          _myActions = actions;
          _isLoadingActions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingActions = false);
    }
  }

  Future<void> _loadCompanies([String? query]) async {
    setState(() => _isLoadingCompanies = true);
    try {
      final data = await RegulatorDataService.getCompanies(search: query);
      if (mounted) {
        setState(() {
          _companies = data;
          _isLoadingCompanies = false;
          if (_expandedCompanyIds.isEmpty && data.isNotEmpty) {
            _expandedCompanyIds.add(data.first.id);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCompanies = false);
    }
  }

  void _toggleExpanded(String companyId) {
    setState(() {
      if (_expandedCompanyIds.contains(companyId)) {
        _expandedCompanyIds.remove(companyId);
      } else {
        _expandedCompanyIds.add(companyId);
      }
    });
  }

  void _showFullHistoryModal(RegulatorCompany company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      company.name,
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'Score: ${company.complianceScore}%',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                company.address,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Full Audit & Enforcement History',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: company.timeline.length,
                  itemBuilder: (context, index) {
                    final event = company.timeline[index];
                    return RegulatorTimelineTile(
                      event: event,
                      isFirst: index == 0,
                      isLast: index == company.timeline.length - 1,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Screen Header & Segmented Section Toggle
            Container(
              color: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Violations & Enforcement History',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Review personal action records and company compliance timelines.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2-Section Segmented Tab Bar
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.onSurfaceVariant,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'My Actions'),
                        Tab(text: 'Company Compliance'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views for Section A and Section B
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // SECTION A: My Actions (Personal Case History)
                  _buildMyActionsSection(),

                  // SECTION B: Company Compliance Overview
                  _buildCompanyComplianceSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RegulatorBottomNavBar(
        currentTab: RegulatorNavTab.violations,
        onTabSelected: (tab) => RegulatorBottomNavBar.navigateToTab(
          context,
          RegulatorNavTab.violations,
          tab,
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION A: My Actions (Personal Case History with Inline Photo Thumbnails)
  // =========================================================================
  Widget _buildMyActionsSection() {
    return RefreshIndicator(
      onRefresh: _loadMyActions,
      color: AppColors.primary,
      child: _isLoadingActions
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _myActions.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 44, color: AppColors.secondary),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No actioned cases yet.',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enforcement decisions, complaint verifications, and label approvals by this officer will appear here with evidence photos.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: _myActions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = _myActions[index];
                    return _buildActionItemCard(item);
                  },
                ),
    );
  }

  Widget _buildActionItemCard(RegulatorActionItem item) {
    Color badgeBg;
    Color badgeFg;

    if (item.actionTaken.contains('Violation') || item.severityOrStatus.toLowerCase().contains('critical')) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeFg = const Color(0xFF991B1B);
    } else if (item.actionTaken.contains('Approved') || item.severityOrStatus.toLowerCase().contains('verified')) {
      badgeBg = const Color(0xFFD1FAE5);
      badgeFg = const Color(0xFF065F46);
    } else if (item.actionTaken.contains('Notice')) {
      badgeBg = const Color(0xFFEDE9FE);
      badgeFg = const Color(0xFF5B21B6);
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFF92400E);
    }

    return InkWell(
      onTap: () {
        if (item.isViolation) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegulatorViolationReviewScreen(violationId: item.id),
            ),
          );
        } else if (item.isComplaint) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegulatorComplaintDetailScreen(complaintId: item.id),
            ),
          );
        } else if (item.isLabelReview) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegulatorLabelReviewScreen(requestId: item.id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Evidence Photo Thumbnail (Always rendered!)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFF0F172A),
                child: _buildActionItemThumbnail(item.imageUrl),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Status Badge & Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            item.actionTaken.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.referenceCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Company / Entity
                  Text(
                    item.entityName,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Formatted Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${item.actionDate.day}/${item.actionDate.month}/${item.actionDate.year}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
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

  Widget _buildActionItemThumbnail(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.photo_camera_rounded, color: Colors.white54, size: 24),
      );
    }
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 24),
        ),
      );
    }
    try {
      final path = trimmed.startsWith('file://') ? Uri.parse(trimmed).toFilePath() : trimmed;
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 24),
          ),
        );
      }
    } catch (_) {}
    return const Center(
      child: Icon(Icons.image_rounded, color: Colors.white54, size: 24),
    );
  }

  // =========================================================================
  // SECTION B: Company Compliance Overview (Search, Scores, Timeline)
  // =========================================================================
  Widget _buildCompanyComplianceSection() {
    return RefreshIndicator(
      onRefresh: () => _loadCompanies(_searchController.text),
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
            // Search Input Bar
            _buildSearchBar(),
            const SizedBox(height: AppSpacing.md),

            // Company List
            if (_isLoadingCompanies)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_companies.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Text(
                  'No company found matching "${_searchController.text}".',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _companies.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final company = _companies[index];
                  final isExpanded = _expandedCompanyIds.contains(company.id);
                  return _buildCompanyCard(company, isExpanded);
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _loadCompanies(val),
        decoration: InputDecoration(
          hintText: 'Search companies, cases...',
          hintStyle: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.onSurfaceVariant,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadCompanies();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(RegulatorCompany company, bool isExpanded) {
    final hasViolations = company.openViolationsCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          // Main Tappable Card Header
          InkWell(
            onTap: () => _toggleExpanded(company.id),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
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
                              company.name,
                              style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    company.address,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasViolations
                              ? AppColors.errorContainer
                              : AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusDefault),
                        ),
                        child: Text(
                          hasViolations
                              ? '${company.openViolationsCount} Open Violations'
                              : 'No Active Violations',
                          style: AppTypography.labelSm.copyWith(
                            color: hasViolations
                                ? AppColors.onErrorContainer
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Progress Bar & Compliance Score
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Compliance Rating',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${company.complianceScore}%',
                                  style: AppTypography.labelMd.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                              child: LinearProgressIndicator(
                                value: company.complianceScore / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  company.complianceScore > 75
                                      ? AppColors.primary
                                      : (company.complianceScore > 50
                                          ? AppColors.tertiary
                                          : AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Timeline Body
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit & Enforcement Timeline',
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (company.timeline.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No recorded timeline events for this company.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: company.timeline.length > 3
                          ? 3
                          : company.timeline.length,
                      itemBuilder: (context, index) {
                        final event = company.timeline[index];
                        return RegulatorTimelineTile(
                          event: event,
                          isFirst: index == 0,
                          isLast: index ==
                              (company.timeline.length > 3
                                      ? 3
                                      : company.timeline.length) -
                                  1,
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showFullHistoryModal(company),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusDefault),
                        ),
                      ),
                      child: Text(
                        'View Full History (${company.timeline.length} Events)',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
