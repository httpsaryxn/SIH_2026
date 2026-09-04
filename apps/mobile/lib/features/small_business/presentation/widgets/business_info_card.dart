import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BusinessInfoCard extends StatelessWidget {
  const BusinessInfoCard({
    super.key,
    required this.fssaiController,
    required this.marketedByController,
    required this.countryOfOrigin,
    required this.onCountryChanged,
  });

  final TextEditingController fssaiController;
  final TextEditingController marketedByController;
  final String countryOfOrigin;
  final ValueChanged<String?> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Document Icon
              Row(
                children: const [
                  Icon(
                    Icons.assignment_outlined,
                    color: AppColors.brandDeepGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Business Information',
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

              // FSSAI License Number Input Field
              const Text(
                'FSSAI License Number *',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: fssaiController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: '14-digit license number',
                          hintStyle: TextStyle(
                            color: AppColors.outline,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Marketed By Input Field
              const Text(
                'Marketed By (Optional)',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: marketedByController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Name of marketing entity',
                          hintStyle: TextStyle(
                            color: AppColors.outline,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Country of Origin Dropdown Field
              const Text(
                'Country of Origin',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: countryOfOrigin,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'India', child: Text('India')),
                            DropdownMenuItem(
                              value: 'United States',
                              child: Text('United States'),
                            ),
                            DropdownMenuItem(
                              value: 'United Kingdom',
                              child: Text('United Kingdom'),
                            ),
                            DropdownMenuItem(
                              value: 'Australia',
                              child: Text('Australia'),
                            ),
                          ],
                          onChanged: onCountryChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
