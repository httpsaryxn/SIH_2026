import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';

class LabelItemData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String status;
  final bool isReady;
  final bool isNeedsReview;
  final SmallBusinessLabelModel? rawModel;

  const LabelItemData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.status,
    this.isReady = true,
    this.isNeedsReview = false,
    this.rawModel,
  });

  factory LabelItemData.fromModel(SmallBusinessLabelModel model) {
    final title = model.productName.isNotEmpty
        ? model.productName
        : model.brandName;
    final subtitle = '${model.brandName} • ${model.productCategory}';
    final isReady = model.status == 'ready';
    final isNeedsReview = model.status == 'needs_review';
    final statusText = isReady
        ? 'Ready'
        : (isNeedsReview ? 'Needs review' : 'Draft');
    final imageUrl = model.logoUrl ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDnCr3KXRKxzPyTldCE9V128qLCdnYDaOARm0rd1SbRCE29NYegL9cVPCOyKz2NlBIqLE4Z36GoXiskgUmkAQUEzJf9QBXbPHNsMvRSRW6kLbQ4u240gBrPnoeRANs2b6AG4D1vaEE7z7bvZGkQtf2yIRjHLqb80QQ8Si2rhFYNf0wCZ1_XZLP0xwqXXhzFcQLfv_pI6hmjt8cETOA4OO2PRliBJQvTqIMTf_uU_6sF4AOV4WPdQHpvUQ';

    return LabelItemData(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      status: statusText,
      isReady: isReady,
      isNeedsReview: isNeedsReview,
      rawModel: model,
    );
  }
}

class YourLabelsSection extends StatelessWidget {
  const YourLabelsSection({
    super.key,
    this.onSeeAll,
    this.onLabelTap,
    this.labels = const [],
    this.totalCount = 0,
    this.readyCount = 0,
    this.needsReviewCount = 0,
    this.selectedStatusFilter = 'All',
    this.selectedCategoryFilter,
    this.onStatusFilterChanged,
    this.onClearCategoryFilter,
  });

  final VoidCallback? onSeeAll;
  final ValueChanged<LabelItemData>? onLabelTap;
  final List<LabelItemData> labels;
  final int totalCount;
  final int readyCount;
  final int needsReviewCount;
  final String selectedStatusFilter;
  final String? selectedCategoryFilter;
  final ValueChanged<String>? onStatusFilterChanged;
  final VoidCallback? onClearCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: Title & See all
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your labels ($totalCount)',
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter Options Below "Your Labels" Header
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _StatusFilterChip(
                label: 'All ($totalCount)',
                isSelected: selectedStatusFilter == 'All',
                onTap: () => onStatusFilterChanged?.call('All'),
              ),
              const SizedBox(width: 8),
              _StatusFilterChip(
                label: 'Ready ($readyCount)',
                isSelected: selectedStatusFilter == 'Ready',
                onTap: () => onStatusFilterChanged?.call('Ready'),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              // Needs Review button with alert red styling
              _StatusFilterChip(
                label: 'Needs Review ($needsReviewCount)',
                isSelected: selectedStatusFilter == 'Needs Review',
                onTap: () => onStatusFilterChanged?.call('Needs Review'),
                isAlert: true,
                icon: Icons.warning_amber_rounded,
              ),
              if (selectedCategoryFilter != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(selectedCategoryFilter!),
                  onDeleted: onClearCategoryFilter,
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  backgroundColor: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDeepGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Empty state when filtered list is empty
        if (labels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  selectedStatusFilter == 'Needs Review'
                      ? Icons.task_alt_rounded
                      : Icons.inventory_2_outlined,
                  size: 36,
                  color: selectedStatusFilter == 'Needs Review'
                      ? const Color(0xFF22C55E)
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedStatusFilter == 'Needs Review'
                      ? 'No labels need review right now!'
                      : 'No labels found for "$selectedStatusFilter"',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => onStatusFilterChanged?.call('All'),
                  child: const Text(
                    'View All Labels',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDeepGreen,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Label List Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: labels.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, index) {
                final label = labels[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onLabelTap?.call(label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Label Image Preview
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              label.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: AppColors.onSurfaceVariant,
                                      size: 22,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Label Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label.title,
                                  style: const TextStyle(
                                    color: AppColors.onBackground,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label.subtitle,
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge with alert red color for Needs Review
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: label.isReady
                                  ? const Color(0xFFE8F5E9)
                                  : (label.isNeedsReview
                                      ? const Color(0xFFFFF1F2)
                                      : AppColors.surfaceContainerHighest),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: label.isReady
                                    ? const Color(0xFFC8E6C9)
                                    : (label.isNeedsReview
                                        ? const Color(0xFFFECDD3)
                                        : AppColors.outlineVariant.withValues(
                                            alpha: 0.5,
                                          )),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (label.isNeedsReview) ...[
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 3),
                                ] else if (label.isReady) ...[
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 11,
                                    color: Color(0xFF1B5E20),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  label.status,
                                  style: TextStyle(
                                    color: label.isReady
                                        ? const Color(0xFF1B5E20)
                                        : (label.isNeedsReview
                                            ? const Color(0xFFDC2626)
                                            : AppColors.onSurfaceVariant),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAlert = false,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAlert;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color activeBg =
        isAlert ? const Color(0xFFDC2626) : AppColors.brandDeepGreen;
    final Color activeBorder =
        isAlert ? const Color(0xFFB91C1C) : AppColors.brandDeepGreen;
    final Color unselectedBg =
        isAlert ? const Color(0xFFFFF1F2) : Colors.white;
    final Color unselectedBorder =
        isAlert ? const Color(0xFFFECDD3) : AppColors.outlineVariant;
    final Color unselectedText =
        isAlert ? const Color(0xFFDC2626) : AppColors.onSurfaceVariant;
    final Color unselectedIconColor =
        isAlert ? const Color(0xFFDC2626) : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBorder : unselectedBorder,
            width: isAlert ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: isAlert ? 0.35 : 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : unselectedIconColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : (isAlert ? FontWeight.w600 : FontWeight.w500),
                color: isSelected ? Colors.white : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
