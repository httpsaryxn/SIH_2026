import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/nutrition_bottom_bar.dart';
import '../widgets/nutrition_format_settings_card.dart';
import '../widgets/nutrition_progress_stepper.dart';
import '../widgets/nutrition_values_table_card.dart';
import '../widgets/weight_serving_card.dart';

import 'manufacturer_details_screen.dart';

class NutritionalValuesScreen extends StatefulWidget {
  const NutritionalValuesScreen({super.key});

  @override
  State<NutritionalValuesScreen> createState() =>
      _NutritionalValuesScreenState();
}

class _NutritionalValuesScreenState extends State<NutritionalValuesScreen> {
  // Weight & Serving controllers
  final TextEditingController _netQuantityController = TextEditingController(
    text: '100',
  );
  final TextEditingController _servingSizeController = TextEditingController(
    text: '30',
  );
  String _netQuantityUnit = 'g';
  String _servingSizeUnit = 'g';

  // Display and format settings
  NutritionValuesDisplayMode _displayMode =
      NutritionValuesDisplayMode.perServing;
  NutritionLabelFormat _labelFormat = NutritionLabelFormat.table;
  String _targetAudience = 'General';
  String _ageGroup = 'Adults (18+)';

  // Nutrient values controllers (prepopulated with compliant defaults)
  late final List<NutrientRowData> _nutrients;
  String? _selectedAdditionalNutrient;
  final List<String> _availableAdditionalNutrients = [
    'Cholesterol',
    'Vitamin A',
    'Vitamin C',
    'Vitamin D',
    'Calcium',
    'Iron',
    'Potassium',
    'Zinc',
    'Magnesium',
  ];

  @override
  void initState() {
    super.initState();
    _nutrients = [
      NutrientRowData(
        label: 'Calories',
        icon: Icons.local_fire_department_rounded,
        isRequired: true,
        unit: 'kcal',
        controller: TextEditingController(text: '250'),
      ),
      NutrientRowData(
        label: 'Total Fat',
        icon: Icons.water_drop_outlined,
        isRequired: true,
        unit: 'g',
        controller: TextEditingController(text: '12'),
      ),
      NutrientRowData(
        label: 'Saturated Fat',
        isSubNutrient: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Trans Fat',
        isSubNutrient: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Sodium',
        icon: Icons.grain_rounded,
        isRequired: true,
        unit: 'mg',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Carbohydrates',
        icon: Icons.grass_rounded,
        isRequired: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Dietary Fiber',
        isSubNutrient: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Total Sugars',
        isSubNutrient: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Added Sugars',
        isSubNutrient: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
      NutrientRowData(
        label: 'Protein',
        icon: Icons.egg_outlined,
        isRequired: true,
        unit: 'g',
        controller: TextEditingController(text: '0'),
      ),
    ];
  }

  @override
  void dispose() {
    _netQuantityController.dispose();
    _servingSizeController.dispose();
    for (final item in _nutrients) {
      item.controller.dispose();
    }
    super.dispose();
  }

  void _addAdditionalNutrient() {
    if (_selectedAdditionalNutrient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a nutrient to add.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final nutrientName = _selectedAdditionalNutrient!;
    final unit = nutrientName.contains('Vitamin') || nutrientName == 'Iron'
        ? 'mg'
        : 'g';

    setState(() {
      _nutrients.add(
        NutrientRowData(
          label: nutrientName,
          unit: unit,
          controller: TextEditingController(text: '0'),
        ),
      );
      _availableAdditionalNutrients.remove(nutrientName);
      _selectedAdditionalNutrient = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $nutrientName to nutritional table.'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ManufacturerDetailsScreen(),
      ),
    );
  }

  void _onSkip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skipped nutritional table setup.'),
        duration: Duration(seconds: 1),
      ),
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
                color: Colors.white.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Back Button / App Badge
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.brandDeepGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Create Product Label',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Build your compliant nutrition label',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification Bell
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Headline
            const Text(
              'Nutritional Values',
              style: TextStyle(
                color: AppColors.brandDeepGreen,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),

            // Stepper Card (Step 3 of 6)
            const NutritionProgressStepper(
              currentStep: 3,
              totalSteps: 6,
              stepTitle: 'Nutritional Values',
            ),
            const SizedBox(height: 16),

            // Card 1: Weight, Pricing & Serving
            WeightServingCard(
              netQuantityController: _netQuantityController,
              servingSizeController: _servingSizeController,
              netQuantityUnit: _netQuantityUnit,
              servingSizeUnit: _servingSizeUnit,
              onNetQuantityUnitChanged: (value) {
                if (value != null) {
                  setState(() => _netQuantityUnit = value);
                }
              },
              onServingSizeUnitChanged: (value) {
                if (value != null) {
                  setState(() => _servingSizeUnit = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Card 2: Show Nutrition Values Format Settings
            NutritionFormatSettingsCard(
              displayMode: _displayMode,
              labelFormat: _labelFormat,
              targetAudience: _targetAudience,
              ageGroup: _ageGroup,
              onDisplayModeChanged: (mode) =>
                  setState(() => _displayMode = mode),
              onLabelFormatChanged: (format) =>
                  setState(() => _labelFormat = format),
              onTargetAudienceChanged: (aud) {
                if (aud != null) setState(() => _targetAudience = aud);
              },
              onAgeGroupChanged: (grp) {
                if (grp != null) setState(() => _ageGroup = grp);
              },
            ),
            const SizedBox(height: 16),

            // Card 3: Nutrition Values Table Card
            NutritionValuesTableCard(
              nutrients: _nutrients,
              selectedAdditionalNutrient: _selectedAdditionalNutrient,
              availableAdditionalNutrients: _availableAdditionalNutrients,
              onAdditionalNutrientChanged: (nutr) =>
                  setState(() => _selectedAdditionalNutrient = nutr),
              onAddNutrientTap: _addAdditionalNutrient,
            ),
            const SizedBox(height: 100), // Bottom bar padding
          ],
        ),
      ),
      bottomNavigationBar: NutritionBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSkip: _onSkip,
        onNext: _onNext,
      ),
    );
  }
}
