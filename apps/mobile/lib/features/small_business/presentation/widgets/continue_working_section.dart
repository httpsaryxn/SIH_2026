import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ContinueWorkingSection extends StatelessWidget {
  const ContinueWorkingSection({
    super.key,
    this.onViewDrafts,
    this.onDraftCardTap,
  });

  final VoidCallback? onViewDrafts;
  final VoidCallback? onDraftCardTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Continue working',
              style: TextStyle(
                color: AppColors.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCkULLvU1u_zh9bb1xjyt0ZBfPgrBKk92xykR2LHfI8VoTB_l6JDfIuTQ5X79CUZJhtwowCYuOC56sE4_vtTVbNw1riKWKmMfw5BE50_b5-XpX8EGwXJ6kDc11OT2wyDl5MZSIJ8S5IZIsnw_87MJVi9hf2H716UU3YtM4Ae2VoG3AizLPNoIMfuiXBp-FtqKNQ1dMUpHZFKd4enROv-82G9XroFpejyn8GRC9py7d9qm-nVqOQBA8-Zg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Draft Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag and time
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
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Last edited today',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Title
                        const Text(
                          'Annapurna Mango Pickle',
                          style: TextStyle(
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
                                      widthFactor: 0.8,
                                      child: Container(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Details 80% complete',
                              style: TextStyle(
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
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
