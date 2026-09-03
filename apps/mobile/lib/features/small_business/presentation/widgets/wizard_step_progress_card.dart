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
          // Top row: Step pill & Completion badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDeepGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'STEP $currentStep OF $totalSteps',
                    style: const TextStyle(
                      color: AppColors.brandDeepGreen,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Percentage / Ready badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      Flexible(
                        child: Text(
                          isComplete ? 'READY' : '$percentage% COMPLETE',
                          style: TextStyle(
                            color: isComplete ? Colors.white : AppColors.brandDeepGreen,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Step Title
          Text(
            stepTitle,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
