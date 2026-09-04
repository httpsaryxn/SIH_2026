import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NutritionProgressStepper extends StatelessWidget {
  const NutritionProgressStepper({
    super.key,
    this.currentStep = 3,
    this.totalSteps = 6,
    this.stepTitle = 'Nutritional Values',
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Step Nodes and Connecting Lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepNode(stepNumber: 1, isCompleted: true, isActive: false),
              _buildConnector(isPassed: true),
              _buildStepNode(stepNumber: 2, isCompleted: true, isActive: false),
              _buildConnector(isPassed: true),
              _buildStepNode(stepNumber: 3, isCompleted: false, isActive: true),
              _buildConnector(isPassed: false),
              _buildStepNode(
                stepNumber: 4,
                isCompleted: false,
                isActive: false,
              ),
              _buildConnector(isPassed: false),
              _buildStepNode(
                stepNumber: 5,
                isCompleted: false,
                isActive: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Subtitle and Step count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepTitle,
                style: const TextStyle(
                  color: AppColors.brandDeepGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  color: AppColors.secondarySlate,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int stepNumber,
    required bool isCompleted,
    required bool isActive,
  }) {
    if (isCompleted) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.brandDeepGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 15),
      );
    } else if (isActive) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.brandDeepGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandDeepGreen.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNumber',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNumber',
          style: const TextStyle(
            color: AppColors.outline,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildConnector({required bool isPassed}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isPassed
            ? AppColors.brandDeepGreen
            : AppColors.surfaceVariant.withValues(alpha: 0.8),
      ),
    );
  }
}
