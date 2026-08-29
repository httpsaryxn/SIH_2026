import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TrustCalloutCard extends StatelessWidget {
  const TrustCalloutCard({
    super.key,
    this.message =
        "Your information stays organized as you build your label. We'll guide you through compliance requirements.",
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandFreshGreen.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.brandFreshGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.brandDeepGreen,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
