import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PackagingEnvironmentalCard extends StatelessWidget {
  const PackagingEnvironmentalCard({
    super.key,
    required this.selectedPackagingType,
    required this.onPackagingTypeChanged,
    required this.isVegetarian,
    required this.onVegetarianChanged,
    required this.selectedRecyclingMark,
    required this.onRecyclingMarkChanged,
  });

  final String selectedPackagingType;
  final ValueChanged<String> onPackagingTypeChanged;
  final bool isVegetarian;
  final ValueChanged<bool> onVegetarianChanged;
  final String selectedRecyclingMark;
  final ValueChanged<String> onRecyclingMarkChanged;

  static const List<String> packagingTypes = [
    'Food Grade Glass Jar',
    'Multi-layer Barrier Pouch',
    'HDPE Plastic Jar / Container',
    'Tin Can / Metallic Container',
    'Paperboard Carton Box',
    'Eco-friendly Biodegradable Pack',
  ];

  static const List<String> recyclingMarks = [
    'Keep Clean (MoEFCC Disposal Logo)',
    'Recyclable Glass - Code 70 GL',
    'Recyclable Plastic - Code 5 PP',
    'Recyclable Plastic - Code 7 OTHER',
    'Plastic Waste Rules EPR Compliant',
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
                  Icons.eco_rounded,
                  color: AppColors.brandDeepGreen,
                  size: 20,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Packaging Material & Symbols',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dietary category & environmental packaging marks',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Packaging Type Dropdown
          const Text(
            'CONTAINER / PACKAGING TYPE *',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPackagingType,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                items: packagingTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onPackagingTypeChanged(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Vegetarian / Non-Vegetarian Indicator Selection
          const Text(
            'DIETARY LOGO DECLARATION (FSSAI MANDATORY) *',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Vegetarian (Green Dot)
              Expanded(
                child: InkWell(
                  onTap: () => onVegetarianChanged(true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isVegetarian
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isVegetarian
                            ? const Color(0xFF16A34A)
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: isVegetarian ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF16A34A),
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Vegetarian',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Non-Vegetarian (Brown Triangle/Dot)
              Expanded(
                child: InkWell(
                  onTap: () => onVegetarianChanged(false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: !isVegetarian
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isVegetarian
                            ? const Color(0xFFB45309)
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: !isVegetarian ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF80253D),
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF80253D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Non-Veg',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF80253D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recycling / Environmental Disposal mark
          const Text(
            'DISPOSAL & RECYCLING MARK (EPR / MOEFCC)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRecyclingMark,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                items: recyclingMarks.map((mark) {
                  return DropdownMenuItem(
                    value: mark,
                    child: Text(
                      mark,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onRecyclingMarkChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
