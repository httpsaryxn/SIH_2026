import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/inbox_item.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_bottom_nav_bar.dart';
import '../../widgets/regulator/regulator_status_badge.dart';
import 'regulator_complaint_detail_screen.dart';
import 'regulator_label_review_screen.dart';

class RegulatorComplaintInboxScreen extends StatefulWidget {
  const RegulatorComplaintInboxScreen({super.key});

  @override
  State<RegulatorComplaintInboxScreen> createState() =>
      _RegulatorComplaintInboxScreenState();
}

class _RegulatorComplaintInboxScreenState
    extends State<RegulatorComplaintInboxScreen> {
  String _selectedType = 'all'; // 'all', 'complaints', 'label_reviews'
  String _selectedStatus = 'All'; // 'All', 'Submitted', 'Under Review', 'Verified', 'Rejected'
  bool _isLoading = true;
  List<InboxItem> _items = [];

  final List<Map<String, String>> _typeFilters = [
    {'id': 'all', 'label': 'All Intake'},
    {'id': 'complaints', 'label': 'Citizen Complaints'},
    {'id': 'label_reviews', 'label': 'Business Label Reviews'},
  ];

  final List<String> _statusTabs = [
    'All',
    'Submitted',
    'Under Review',
    'Verified',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadInboxItems();
  }

  Future<void> _loadInboxItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await RegulatorDataService.getInboxItems(
        typeFilter: _selectedType,
        statusFilter: _selectedStatus == 'All' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: ClipRect(
            child: RefreshIndicator(
              onRefresh: _loadInboxItems,
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
                      'Unified Intake Queue',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review incoming citizen complaints and business label verification requests in a single compliance queue.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                  // 1. Source Type Filter Chips
                  _buildTypeFilterChips(),
                  const SizedBox(height: AppSpacing.sm),

                  // 2. Status Filter Tabs
                  _buildStatusFilterTabs(),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Unified Queue Item List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 40, color: AppColors.secondary),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No intake items matching the selected filters.',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildUnifiedInboxCard(item);
                      },
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
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

  Widget _buildTypeFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _typeFilters.map((tf) {
          final isSelected = tf['id'] == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(
                tf['label']!,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = tf['id']!);
                  _loadInboxItems();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilterTabs() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusTabs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final tab = _statusTabs[index];
          final isSelected = tab == _selectedStatus;

          return InkWell(
            onTap: () {
              setState(() => _selectedStatus = tab);
              _loadInboxItems();
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: AppTypography.labelSm.copyWith(
                    color: isSelected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedInboxCard(InboxItem item) {
    final isComplaint = item.isComplaint;
    final timeAgo = _formatRelativeTime(item.submittedAt);

    return InkWell(
      onTap: () async {
        if (isComplaint) {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RegulatorComplaintDetailScreen(complaintId: item.id),
            ),
          );
          if (changed == true) _loadInboxItems();
        } else {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RegulatorLabelReviewScreen(requestId: item.id),
            ),
          );
          if (changed == true) _loadInboxItems();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Source Type Tag & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSourceTypeBadge(isComplaint),
                Row(
                  children: [
                    Text(
                      timeAgo,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RegulatorStatusBadge.fromStatus(item.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Middle Row: Thumbnail Image & Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Thumbnail (photo evidence or label artwork)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.surfaceContainerLow,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              isComplaint
                                  ? Icons.report_problem_outlined
                                  : Icons.verified_outlined,
                              color: AppColors.secondary,
                              size: 26,
                            ),
                          )
                        : Icon(
                            isComplaint
                                ? Icons.report_problem_outlined
                                : Icons.verified_outlined,
                            color: AppColors.secondary,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Title & Subtitle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isComplaint
                                ? Icons.location_on_outlined
                                : Icons.category_outlined,
                            size: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.locationOrBusiness ?? (item.category ?? 'Unclassified'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Bottom Meta Row: Reference Code & Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isComplaint
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    item.priorityOrTag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isComplaint
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF7E22CE),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTypeBadge(bool isComplaint) {
    if (isComplaint) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_rounded, size: 12, color: Color(0xFFC2410C)),
            const SizedBox(width: 4),
            Text(
              'CITIZEN COMPLAINT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFC2410C),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF4338CA)),
          const SizedBox(width: 4),
          Text(
            'BUSINESS LABEL REVIEW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4338CA),
            ),
          ),
        ],
      ),
    );
  }
}
