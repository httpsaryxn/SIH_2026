import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ReviewProgressHeader extends StatelessWidget {
  const ReviewProgressHeader({
    super.key,
    this.currentStep = 6,
    this.totalSteps = 6,
    this.stepTitle = 'Review & Export',
    this.percentage = 100,
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandDeepGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STEP 0$currentStep OF 0$totalSteps',
                        style: const TextStyle(
                          color: AppColors.brandDeepGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stepTitle,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandDeepGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '100% READY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // All 6 segments filled
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 5 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDeepGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
