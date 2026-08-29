import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class IngredientSearchCard extends StatefulWidget {
  const IngredientSearchCard({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onAddManually,
    this.onChanged,
    this.onIngredientSelected,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onAddManually;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onIngredientSelected;

  @override
  State<IngredientSearchCard> createState() => _IngredientSearchCardState();
}

class _IngredientSearchCardState extends State<IngredientSearchCard> {
  static const List<String> _commonIngredientsDatabase = [
    // Spices & Seasonings
    'Turmeric Powder (Haldi)',
    'Red Chilli Powder (Lal Mirch)',
    'Coriander Powder (Dhania)',
    'Cumin Seeds (Jeera)',
    'Mustard Seeds (Rai)',
    'Black Pepper (Kali Mirch)',
    'Garam Masala',
    'Asafoetida (Hing)',
    'Fenugreek Seeds (Methi)',
    'Fennel Seeds (Saunf)',
    'Cardamom (Elaichi)',
    'Cloves (Laung)',
    'Cinnamon (Dalchini)',
    'Dry Ginger Powder (Sonth)',
    'Kasuri Methi',
    'Amchur (Dry Mango Powder)',

    // Oils & Fats
    'Mustard Oil (Sarson Tel)',
    'Refined Sunflower Oil',
    'Cold Pressed Groundnut Oil',
    'Coconut Oil',
    'Sesame / Gingelly Oil',
    'Desi Cow Ghee',
    'Olive Oil',

    // Flours & Grains
    'Whole Wheat Flour (Atta)',
    'Besan (Gram Flour)',
    'Rice Flour',
    'Semolina (Sooji / Rava)',
    'Maida (Refined Flour)',
    'Rolled Oats',
    'Poha (Flattened Rice)',

    // Salts & Sweeteners
    'Iodised Salt',
    'Rock Salt (Sendha Namak)',
    'Black Salt (Kala Namak)',
    'Jaggery (Gur)',
    'Refined Sugar',
    'Raw Forest Honey',
    'Brown Sugar',

    // Fresh Produce & Bases
    'Raw Mango Pieces',
    'Tamarind Pulp (Imli)',
    'Fresh Ginger',
    'Garlic Paste',
    'Green Chillies',
    'Curry Leaves (Kadi Patta)',
    'Tomato Puree',
    'Lemon Juice',

    // Nuts & Seeds
    'Peanuts (Moongphali)',
    'Cashew Nuts (Kaju)',
    'Almonds (Badam)',
    'Sesame Seeds (Til)',
    'Chia Seeds',
    'Flax Seeds (Alsi)',
  ];

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.text.trim().toLowerCase();
    final matchingSuggestions = _commonIngredientsDatabase.where((item) {
      if (query.isEmpty) return true;
      return item.toLowerCase().contains(query);
    }).take(query.isEmpty ? 8 : 12).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search & Quick-Add Ingredients',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: widget.onAddManually,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.brandDeepGreen),
                      SizedBox(width: 2),
                      Text(
                        'Custom Add',
                        style: TextStyle(
                          color: AppColors.brandDeepGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Input Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant,
                width: 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: (val) {
                setState(() {});
                widget.onChanged?.call(val);
              },
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Type ingredient name (e.g. Mango, Mustard, Salt, Ghee)...',
                hintStyle: const TextStyle(
                  color: AppColors.outline,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {});
                          widget.onChanged?.call('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Suggestion Chips Header
          Text(
            query.isEmpty ? 'Common Formulation Ingredients (Tap to Add):' : 'Matching Suggestions (${matchingSuggestions.length}):',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Suggestion Chips Wrap
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: matchingSuggestions.map((ing) {
              return ActionChip(
                label: Text(ing),
                avatar: const Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: AppColors.brandDeepGreen,
                ),
                backgroundColor: AppColors.brandDeepGreen.withValues(alpha: 0.06),
                labelStyle: const TextStyle(
                  color: AppColors.brandDeepGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.25),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: () {
                  final cleanName = ing.split('(').first.trim();
                  if (widget.onIngredientSelected != null) {
                    widget.onIngredientSelected!(cleanName);
                  } else {
                    widget.onSubmitted?.call(cleanName);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
