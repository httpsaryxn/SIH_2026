import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
        category: 'Food & Beverages',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCcXmKu-wXmgXHUL5_LZniBRP74NBCPIhTAAvsKJfxmo3mihAzv043V2RhzLgyEnkCVJYnbd27YnQ1vrHJ7muyko9HwbphR0koy3KC7QlTPZMsItrhGG8_cDXy_ZAvUuHn4ZPtAOYMZFxqGU4oLw9ESPumLi-1XLuuBfxVvLLu0DqwvxmY_a8j8TCcNbtSE1fDPcZ7Hp9E8mK9o47xRpxLcFGNQ7TeFZBCrVc_s5Bg_D-nPjru3FQdZ_Q',
      ),
      SampleLabelData(
        title: 'Garam Masala',
        category: 'Spices',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCB-2bXyhoIjf6kUT7_-X_q_3vNf_k3tNcVPHgl07HuwsaNAlgiXH5BLHlwY7ZnWMvhin6tiTUeKxZVU_owLVGN-1tCG8rRpGF9kd2_s9_KBjV4IoJcTwlOgi1UzjRRDdtSMzEPhWbgqwKbl0KrBS7mn0IGzmDhY6guTn23bCIpKJm0oiQJUjdA5qmuzpQp6y5slyCZ0X6GePGgyBNIGdHFHIiYpiy2XYnzy7wHP0v9dzE5VH9IYKo8nw',
      ),
      SampleLabelData(
        title: 'Pure Wild Honey',
        category: 'Natural Foods',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAbJgISdT2NBAhmhQ9EBcbZNYKVh1s9VDUo47GQvOiYDcEaVuIM4Be4qVa0j-3ZNLEmiAlKlVGt55Xi05LYIKtbQ3R7OPE0cKL7eWE1HjbQ_pqjN-Xk8hzsMe4-LAC0RbE6kMMy1xw3j8Cy24yoQ5fFNimXAtTnSR8kzCFS0DXXhENpkupHAUFV8ovidTMAkov3cj8NxXyDt3jrPaOf98m67dZMQO6wi4kHncM2ZcHP0il2VKHHKUKUPw',
      ),
      SampleLabelData(
        title: 'Banana Chips',
        category: 'Snacks',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB5zeZS_n_7Ej-iwqd8_k_bH-5-qmT68lv5CIYuwivIcG38WNi_aHQGyxA2YXHXWKUxf2lL_3CStX2rGP94h4flwZZ_vrI5mjbWhUdnf-nROeufic9ycjBsgGCZ1MAqjMk9EIfDoUpgivTpCi7qOfOvg1J85wyDoc25XG8DbDIBu5GwrSa7CKwH9Pm2Z88shtGh3MDf0iyP1kLCJTe4ZFHo68u0nc9dwa7TCKEz_qcA_dMLgFrCj0Vh_Q',
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
          height: 190,
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
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 26,
                ),
              ),
            ),
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
