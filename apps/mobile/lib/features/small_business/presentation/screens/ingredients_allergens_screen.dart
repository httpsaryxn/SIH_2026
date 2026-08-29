import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/allergen_declaration_section.dart';
import '../widgets/ingredient_search_card.dart';
import '../widgets/ingredient_source_segmented_control.dart';
import '../widgets/ingredients_bottom_bar.dart';
import '../widgets/ingredients_header_card.dart';
import '../widgets/ingredients_list_section.dart';
import '../widgets/ingredients_progress_card.dart';
import 'nutritional_values_screen.dart';

class IngredientsAllergensScreen extends StatefulWidget {
  const IngredientsAllergensScreen({super.key});

  @override
  State<IngredientsAllergensScreen> createState() =>
      _IngredientsAllergensScreenState();
}

class _IngredientsAllergensScreenState
    extends State<IngredientsAllergensScreen> {
  final TextEditingController _searchController = TextEditingController();

  IngredientSourceType _selectedSource = IngredientSourceType.noLabReport;
  final List<IngredientItem> _ingredients = [];
  final List<String> _selectedAllergens = ['Peanuts', 'Milk'];

  final List<String> _availableAllergens = [
    'Peanuts',
    'Milk',
    'Tree Nuts',
    'Soy / Soybeans',
    'Wheat / Gluten',
    'Eggs',
    'Fish',
    'Crustaceans / Shellfish',
    'Mustard',
    'Sesame Seeds',
    'Sulphites',
    'Celery',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingredients & allergens draft saved'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddIngredientDialog([String initialName = '']) {
    final nameController = TextEditingController(text: initialName);
    final percentageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Ingredient',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ingredient Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Raw Mango, Mustard Oil, Salt',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Percentage (%) - Optional',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: percentageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 65.0',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final percentage = double.tryParse(
                        percentageController.text.trim(),
                      );

                      setState(() {
                        _ingredients.add(
                          IngredientItem(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: name,
                            percentage: percentage,
                          ),
                        );
                        _searchController.clear();
                      });
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandDeepGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Ingredient',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAllergenPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Allergens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAllergens.map((allergen) {
                  final isSelected = _selectedAllergens.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAllergens.add(allergen);
                        } else {
                          _selectedAllergens.remove(allergen);
                        }
                      });
                      Navigator.of(ctx).pop();
                    },
                    selectedColor: const Color(
                      0xFF80253D,
                    ).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF80253D),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF80253D)
                          : AppColors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF80253D)
                            : AppColors.outlineVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _onContinue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NutritionalValuesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.brandDeepGreen,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      // Title
                      const Text(
                        'Label Studio',
                        style: TextStyle(
                          color: AppColors.brandDeepGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      // Save action
                      TextButton(
                        onPressed: _saveDraft,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandDeepGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient blurred blobs
          Positioned(
            top: 40,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 280,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandBlue.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF80253D).withValues(alpha: 0.05),
              ),
            ),
          ),
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Card (Step 2 of 6, 33%)
                const IngredientsProgressCard(
                  currentStep: 2,
                  totalSteps: 6,
                  percentage: 33,
                ),
                const SizedBox(height: 20),

                // Header Card ("STEP 02 - Ingredients")
                const IngredientsHeaderCard(),
                const SizedBox(height: 20),

                // Nutrition/Ingredient Source Segmented Control
                IngredientSourceSegmentedControl(
                  selectedSource: _selectedSource,
                  onSourceChanged: (source) {
                    setState(() {
                      _selectedSource = source;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Search Card
                IngredientSearchCard(
                  controller: _searchController,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _showAddIngredientDialog(value.trim());
                    }
                  },
                  onAddManually: () => _showAddIngredientDialog(),
                  onChanged: (text) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Ingredients List Section
                IngredientsListSection(
                  ingredients: _ingredients,
                  onAddIngredient: () => _showAddIngredientDialog(),
                  onRemoveIngredient: (item) {
                    setState(() {
                      _ingredients.removeWhere((i) => i.id == item.id);
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Food Safety: Allergen Declaration
                AllergenDeclarationSection(
                  selectedAllergens: _selectedAllergens,
                  onRemoveAllergen: (allergen) {
                    setState(() {
                      _selectedAllergens.remove(allergen);
                    });
                  },
                  onAddAllergenTap: _showAddAllergenPicker,
                ),
                const SizedBox(height: 100), // Bottom bar padding
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: IngredientsBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onContinue: _onContinue,
      ),
    );
  }
}
