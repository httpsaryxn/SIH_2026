import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LabelItemData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String status;
  final bool isReady;

  const LabelItemData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.status,
    this.isReady = true,
  });
}

class YourLabelsSection extends StatelessWidget {
  const YourLabelsSection({
    super.key,
    this.onSeeAll,
    this.onLabelTap,
    this.labels = const [
      LabelItemData(
        title: 'Village Gold Turmeric',
        subtitle: 'Desi Harvest • Updated 2 days ago',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDnCr3KXRKxzPyTldCE9V128qLCdnYDaOARm0rd1SbRCE29NYegL9cVPCOyKz2NlBIqLE4Z36GoXiskgUmkAQUEzJf9QBXbPHNsMvRSRW6kLbQ4u240gBrPnoeRANs2b6AG4D1vaEE7z7bvZGkQtf2yIRjHLqb80QQ8Si2rhFYNf0wCZ1_XZLP0xwqXXhzFcQLfv_pI6hmjt8cETOA4OO2PRliBJQvTqIMTf_uU_6sF4AOV4WPdQHpvUQ',
        status: 'Ready',
        isReady: true,
      ),
      LabelItemData(
        title: 'Raw Forest Honey',
        subtitle: 'Himalayan Roots • Updated last week',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDqtSKTW1FTWnpu1-XzsyHeRUSeDBUZj1yFDitC1bK9Ai6Sosr9FD7iUGZRn9KQFiEXURqlMAUNT7_NlCoe7n0xBYS88zA3fdtRjib-NYJic_4HlRfm1Q84dzzmtRCWuBTPip6jORsKcuR6EsfVT1swKiqBuRZS5d2eust8CENfZ9Ee0wrsCU8Vam-nFI2Ex6rH7BRLoCacvmHWn45GyUjHtSOkFqVUBnAgLJk0coyiganzwmml1biRRA',
        status: 'Ready',
        isReady: true,
      ),
      LabelItemData(
        title: 'Spicy Chana Mix',
        subtitle: 'Ghar Ka Taste • Updated 5 days ago',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBW7_8F7y65HhUZPZMi_Dx7Zj-m3P4nFV_9y2IPRXZfGAn44o-vymFC9Jz0Fp17VAa5gD-N272dujLVsA0GkLh4nPX6Ofru4qsCCBSBmj4ld129S1NRrbA2MxVHJREyvlG7zJkBwzyLE62zwQSRDmWsIOaer6QmpQjmW5hN-knQWNk43IrC6bkbQZeWz9nWY-Q-rd2FmleCWZSi5iv3ScCPZ8WJTyLXuOiiRSPqmJZGmpKv31rPw07ZCg',
        status: 'Needs review',
        isReady: false,
      ),
    ],
  });

  final VoidCallback? onSeeAll;
  final ValueChanged<LabelItemData>? onLabelTap;
  final List<LabelItemData> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your labels (${labels.length > 3 ? 12 : labels.length})',
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
