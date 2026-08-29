import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class IngredientsHeaderCard extends StatelessWidget {
  const IngredientsHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandDeepGreen.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative leaf illustration/icon
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              Icons.eco_rounded,
              size: 110,
              color: AppColors.brandDeepGreen.withValues(alpha: 0.12),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'STEP 02',
                  style: TextStyle(
                    color: AppColors.brandDeepGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ingredients',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 280,
                  child: Text(
                    "Build your product's ingredient statement accurately for compliance.",
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
