import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManufacturerProgressBar extends StatelessWidget {
  const ManufacturerProgressBar({
    super.key,
    this.currentStep = 4,
    this.totalSteps = 6,
    this.stepTitle = 'Manufacturer Details',
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Text Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              stepTitle,
              style: const TextStyle(
                color: AppColors.brandDeepGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 6-Segment Progress Bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isFilled = index < currentStep;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 5 : 0),
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
    );
  }
}
