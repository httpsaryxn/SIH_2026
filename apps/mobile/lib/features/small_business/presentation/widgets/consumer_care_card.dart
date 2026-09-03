import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ConsumerCareCard extends StatelessWidget {
  const ConsumerCareCard({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController websiteController;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Support Icon
          Row(
            children: const [
              Icon(
                Icons.support_agent_rounded,
                color: AppColors.brandDeepGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consumer Care Details',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Consumer Care Number Input Field
          const Text(
            'Consumer Care Number *',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: AppColors.outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                        color: AppColors.outline,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Consumer Care Email Input Field
          const Text(
            'Consumer Care Email *',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: AppColors.outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      hintStyle: TextStyle(
                        color: AppColors.outline,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Website Input Field
          const Text(
            'Website (Optional)',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.language_outlined,
                  color: AppColors.outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: websiteController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'www.example.com',
                      hintStyle: TextStyle(
                        color: AppColors.outline,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
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
