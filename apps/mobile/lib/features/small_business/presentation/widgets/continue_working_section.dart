import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import 'product_image_widget.dart';

class ContinueWorkingSection extends StatelessWidget {
  const ContinueWorkingSection({
    super.key,
    this.draft,
    this.onViewDrafts,
    this.onDraftCardTap,
    this.onDeleteDraft,
  });

  final SmallBusinessLabelModel? draft;
  final VoidCallback? onViewDrafts;
  final VoidCallback? onDraftCardTap;
  final VoidCallback? onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    if (draft == null) {
      return const SizedBox.shrink();
    }

    final currentDraft = draft!;
    final title = currentDraft.productName.isNotEmpty
        ? '${currentDraft.brandName} ${currentDraft.productName}'
        : (currentDraft.brandName.isNotEmpty ? currentDraft.brandName : 'Untitled Draft');
    final percentage = currentDraft.completionPercentage.clamp(0, 100);
    final imageUrl = currentDraft.logoUrl ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Continue working',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDeleteDraft != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Draft',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDeleteDraft,
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onViewDrafts,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View drafts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Draft Card
        Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onDraftCardTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
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
              child: Row(
                children: [
                  // Draft Thumbnail Image
                  ProductImageWidget(
                    imageUrl: imageUrl,
                    category: draft?.productCategory,
                    width: 64,
                    height: 64,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 12),
                  // Draft Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DRAFT',
                                style: TextStyle(
                                  color: AppColors.onErrorContainer,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Progress Bar & Percentage
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 6,
                                  color: AppColors.surfaceContainerHighest,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (percentage / 100.0).clamp(0.05, 1.0),
                                      child: Container(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage% complete',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron Icon
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
