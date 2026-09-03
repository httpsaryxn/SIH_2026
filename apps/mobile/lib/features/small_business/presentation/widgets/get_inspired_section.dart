import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'product_image_widget.dart';

class SampleLabelData {
  final String title;
  final String category;
  final String imageUrl;

  const SampleLabelData({
    required this.title,
    required this.category,
    required this.imageUrl,
  });
}

class GetInspiredSection extends StatelessWidget {
  const GetInspiredSection({
    super.key,
    this.onSampleTap,
    this.samples = const [
      SampleLabelData(
        title: 'Mango Pickle',
        category: 'Pickles & Condiments',
        imageUrl:
            'https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?auto=format&fit=crop&w=400&q=80',
      ),
      SampleLabelData(
        title: 'Garam Masala',
        category: 'Spices & Masalas',
        imageUrl:
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',
      ),
      SampleLabelData(
        title: 'Pure Wild Honey',
        category: 'Honey & Natural Foods',
        imageUrl:
            'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=400&q=80',
      ),
      SampleLabelData(
        title: 'Banana Chips',
        category: 'Snacks & Namkeen',
        imageUrl:
            'https://images.unsplash.com/photo-1621996346565-e3d5d6281033?auto=format&fit=crop&w=400&q=80',
      ),
    ],
  });

  final ValueChanged<SampleLabelData>? onSampleTap;
  final List<SampleLabelData> samples;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get inspired',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Explore sample labels for popular products.',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: samples.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = samples[index];
              return _buildSampleCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSampleCard(BuildContext context, SampleLabelData item) {
    return Container(
      width: 136,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Container
          ProductImageWidget(
            imageUrl: item.imageUrl,
            category: item.category,
            width: double.infinity,
            height: 90,
            fit: BoxFit.contain,
            borderRadius: 10,
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Category
          Text(
            item.category,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Action circle button
          Material(
            color: AppColors.surfaceContainerLow,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => onSampleTap?.call(item),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
