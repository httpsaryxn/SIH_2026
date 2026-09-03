import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import 'product_image_widget.dart';

class LabelItemData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String status;
  final bool isReady;
  final SmallBusinessLabelModel? rawModel;

  const LabelItemData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.status,
    this.isReady = true,
    this.rawModel,
  });

  factory LabelItemData.fromModel(SmallBusinessLabelModel model) {
    final title = model.productName.trim().isNotEmpty
        ? model.productName.trim()
        : (model.brandName.trim().isNotEmpty
            ? model.brandName.trim()
            : 'Custom Product Label');
    final brandDisplay = model.brandName.trim().isNotEmpty
        ? model.brandName.trim()
        : 'Small Business';
    final catDisplay = model.productCategory.trim().isNotEmpty
        ? model.productCategory.trim()
        : 'General Food';
    final subtitle = '$brandDisplay • $catDisplay';
    final isReady = model.status == 'ready';
    final statusText = isReady
        ? 'Ready'
        : (model.status == 'needs_review' ? 'Needs review' : 'Draft');
    final imageUrl = model.logoUrl ?? '';

    return LabelItemData(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      status: statusText,
      isReady: isReady,
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
  });

  final VoidCallback? onSeeAll;
  final ValueChanged<LabelItemData>? onLabelTap;
  final List<LabelItemData> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(height: 8),
            Text(
              'No labels found for this filter',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap "Start creating your label" above to create one.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Your labels (${labels.length})',
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 10),
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
                        ProductImageWidget(
                          imageUrl: label.imageUrl,
                          category: label.rawModel?.productCategory,
                          width: 48,
                          height: 48,
                          borderRadius: 8,
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
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: label.isReady
                                ? const Color(0xFFD6F5DB)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: label.isReady
                                ? null
                                : Border.all(
                                    color: AppColors.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1,
                                  ),
                          ),
                          child: Text(
                            label.status,
                            style: TextStyle(
                              color: label.isReady
                                  ? const Color(0xFF005321)
                                  : AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
