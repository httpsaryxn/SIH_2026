import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WizardStepProgressCard extends StatelessWidget {
  const WizardStepProgressCard({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
    required this.stepTitle,
    required this.percentage,
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    final isComplete = percentage >= 100 || currentStep >= totalSteps;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step pill & title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
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
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    stepTitle,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Percentage / Ready badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.brandDeepGreen
                      : AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isComplete) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isComplete ? '100% READY' : '$percentage% COMPLETE',
                      style: TextStyle(
                        color: isComplete ? Colors.white : AppColors.brandDeepGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-segment progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final stepIndex = index + 1;
              final isStepActive = stepIndex <= currentStep;

              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 5 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isStepActive
                        ? AppColors.brandDeepGreen
                        : AppColors.outlineVariant.withValues(alpha: 0.45),
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
