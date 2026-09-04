import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ClaimsProgressBar extends StatelessWidget {
  const ClaimsProgressBar({
    super.key,
    this.currentStep = 5,
    this.totalSteps = 6,
    this.stepTitle = 'Product Claims',
    this.percentage = 83,
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
          // Step & percentage row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
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
                  Text(
                    stepTitle,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: AppColors.brandDeepGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 6-Segment progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isFilled = index < currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 5 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isFilled
                      ? AppColors.brandDeepGreen
                      : AppColors.surfaceVariant.withValues(alpha: 0.8),
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
