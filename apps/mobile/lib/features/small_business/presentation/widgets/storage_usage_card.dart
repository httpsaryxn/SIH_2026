import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StorageUsageCard extends StatelessWidget {
  const StorageUsageCard({
    super.key,
    required this.storageController,
    required this.usageController,
    required this.selectedStorageChips,
    required this.onToggleStorageChip,
  });

  final TextEditingController storageController;
  final TextEditingController usageController;
  final List<String> selectedStorageChips;
  final ValueChanged<String> onToggleStorageChip;

  static const List<String> storageSuggestions = [
    'Store in a cool & dry place',
    'Keep away from direct sunlight',
    'Refrigerate after opening',
    'Store in an airtight container',
    'Do not freeze',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.ac_unit_rounded,
                  color: AppColors.brandDeepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Storage & Usage Instructions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Shelf-life preservation & consumer safety guidelines',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick selection chips
          const Text(
            'COMMON STORAGE DECLARATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: storageSuggestions.map((suggestion) {
              final isSelected = selectedStorageChips.contains(suggestion);
              return FilterChip(
                label: Text(suggestion),
                selected: isSelected,
                onSelected: (_) => onToggleStorageChip(suggestion),
                selectedColor: AppColors.brandDeepGreen.withValues(alpha: 0.12),
                checkmarkColor: AppColors.brandDeepGreen,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.brandDeepGreen
                      : AppColors.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.brandDeepGreen
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Storage condition text
          const Text(
            'STORAGE INSTRUCTION TEXT *',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: storageController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Store in a cool, dry place away from direct sunlight. Refrigerate after opening.',
              hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.outline),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.brandDeepGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Usage instruction text
          const Text(
            'USAGE / PREPARATION INSTRUCTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: usageController,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Use a clean, dry spoon. Consume within 30 days after opening.',
              hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.outline),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.brandDeepGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
