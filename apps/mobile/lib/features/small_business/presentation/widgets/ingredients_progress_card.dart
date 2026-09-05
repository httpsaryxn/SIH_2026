import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class IngredientsProgressCard extends StatelessWidget {
  const IngredientsProgressCard({
    super.key,
    this.currentStep = 2,
    this.totalSteps = 6,
    this.percentage = 33,
  });

  final int currentStep;
  final int totalSteps;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with step info and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  color: AppColors.brandDeepGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage% complete',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Continuous Gradient Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandDeepGreen,
                          AppColors.brandFreshGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Numbered Stepper Nodes
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              // Even indices are nodes, odd indices are connecting lines
              if (index.isOdd) {
                final stepIndex = (index ~/ 2) + 1;
                final isPassed = stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: isPassed
                        ? AppColors.brandDeepGreen.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant.withValues(alpha: 0.6),
                  ),
                );
              } else {
                final stepNumber = (index ~/ 2) + 1;
                final isCompleted = stepNumber < currentStep;
                final isCurrent = stepNumber == currentStep;

                if (isCompleted) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandDeepGreen,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  );
                } else if (isCurrent) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandDeepGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandDeepGreen.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: AppColors.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
              }
            }),
          ),
        ],
      ),
    );
  }
}
