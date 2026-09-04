import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_company.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../../widgets/regulator/regulator_timeline_tile.dart';

class RegulatorCompanyTrackingScreen extends StatefulWidget {
  const RegulatorCompanyTrackingScreen({super.key});

  @override
  State<RegulatorCompanyTrackingScreen> createState() =>
      _RegulatorCompanyTrackingScreenState();
}

class _RegulatorCompanyTrackingScreenState
    extends State<RegulatorCompanyTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RegulatorCompany> _companies = [];
  bool _isLoading = true;
  final Set<String> _expandedCompanyIds = {};

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies([String? query]) async {
    setState(() => _isLoading = true);
    final data = await RegulatorDataService.getCompanies(search: query);
    if (mounted) {
      setState(() {
        _companies = data;
        _isLoading = false;
        // Expand the first company by default to match Stitch reference
        if (_expandedCompanyIds.isEmpty && data.isNotEmpty) {
          _expandedCompanyIds.add(data.first.id);
        }
      });
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
      appBar: const RegulatorTopAppBar(),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ClipRect(
          child: RefreshIndicator(
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
                if (_isLoading)
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
                      final isExpanded =
                          _expandedCompanyIds.contains(company.id);
                      return _buildCompanyCard(company, isExpanded);
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
        currentTab: RegulatorNavTab.violations,
        onTabSelected: (tab) =>
            RegulatorBottomNavBar.navigateToTab(context, RegulatorNavTab.violations, tab),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 1,
                    color: AppColors.surfaceVariant,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Compliance: ${company.complianceScore}%',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Timeline section
          if (isExpanded && company.timeline.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < company.timeline.length && i < 3; i++) ...[
                    RegulatorTimelineTile(
                      event: company.timeline[i],
                      isFirst: i == 0,
                      isLast: i == (company.timeline.length < 3 ? company.timeline.length - 1 : 2),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _showFullHistoryModal(company),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLow,
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
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
