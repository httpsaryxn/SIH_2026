import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/notification_service.dart';
import '../widgets/nutrition_bottom_bar.dart';
import '../widgets/nutrition_format_settings_card.dart';
import '../widgets/nutrition_values_table_card.dart';
import '../widgets/weight_serving_card.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'manufacturer_details_screen.dart';
import 'my_label_studio_screen.dart';

class NutritionalValuesScreen extends StatefulWidget {
  const NutritionalValuesScreen({super.key, this.labelModel});

  final SmallBusinessLabelModel? labelModel;

  @override
  State<NutritionalValuesScreen> createState() =>
      _NutritionalValuesScreenState();
}

class _NutritionalValuesScreenState extends State<NutritionalValuesScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();

  late final TextEditingController _netQuantityController;
  late final TextEditingController _servingSizeController;
  late String _netQuantityUnit;
  late String _servingSizeUnit;

  late NutritionValuesDisplayMode _displayMode;
  late NutritionLabelFormat _labelFormat;
  late String _targetAudience;
  late String _ageGroup;

  late final List<NutrientRowData> _nutrients;
  String? _selectedAdditionalNutrient;

  final List<String> _availableAdditionalNutrients = [
    'Vitamin A (Retinol)',
    'Vitamin B1 (Thiamine)',
    'Vitamin B2 (Riboflavin)',
    'Vitamin B3 (Niacin)',
    'Vitamin B6 (Pyridoxine)',
    'Vitamin B9 (Folic Acid)',
    'Vitamin B12 (Cobalamin)',
    'Vitamin C (Ascorbic Acid)',
    'Vitamin D (D2/D3)',
    'Vitamin E (Tocopherol)',
    'Vitamin K (Phylloquinone)',
    'Calcium (Ca)',
    'Iron (Fe)',
    'Zinc (Zn)',
    'Magnesium (Mg)',
    'Potassium (K)',
    'Phosphorus (P)',
    'Iodine (I)',
    'Selenium (Se)',
    'Copper (Cu)',
    'Cholesterol',
    'Monounsaturated Fatty Acids (MUFA)',
    'Polyunsaturated Fatty Acids (PUFA)',
    'Omega-3 Fatty Acids',
    'Omega-6 Fatty Acids',
  ];

  late SmallBusinessLabelModel _currentModel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.labelModel ?? const SmallBusinessLabelModel();

    _netQuantityController = TextEditingController(
      text: _currentModel.netQuantity,
    );
    _servingSizeController = TextEditingController(
      text: _currentModel.servingSize,
    );
    _netQuantityUnit = _currentModel.netQuantityUnit.isNotEmpty ? _currentModel.netQuantityUnit : 'g';
    _servingSizeUnit = _currentModel.servingSizeUnit.isNotEmpty ? _currentModel.servingSizeUnit : 'g';

    _displayMode =
        _currentModel.displayMode == 'per100g'
            ? NutritionValuesDisplayMode.per100g
            : (_currentModel.displayMode == 'both'
                ? NutritionValuesDisplayMode.both
                : NutritionValuesDisplayMode.perServing);

    _labelFormat =
        _currentModel.labelFormat == 'text'
            ? NutritionLabelFormat.text
            : NutritionLabelFormat.table;

    _targetAudience =
        _currentModel.targetAudience.isNotEmpty
            ? _currentModel.targetAudience
            : 'General Population (All Consumers)';
    _ageGroup =
        _currentModel.ageGroup.isNotEmpty
            ? _currentModel.ageGroup
            : 'All Age Groups (General)';

    if (_currentModel.nutrients.isNotEmpty) {
      _nutrients =
          _currentModel.nutrients.map((n) {
            return NutrientRowData(
              label: n.label,
              unit: n.unit,
              isRequired: n.isRequired,
              isSubNutrient: n.isSubNutrient,
              controller: TextEditingController(text: n.value),
            );
          }).toList();
    } else {
      // Standard baseline mandatory nutrients
      _nutrients = [
        NutrientRowData(
          label: 'Calories',
          icon: Icons.local_fire_department_rounded,
          isRequired: true,
          unit: 'kcal',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Total Fat',
          icon: Icons.water_drop_outlined,
          isRequired: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Saturated Fat',
          isSubNutrient: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Trans Fat',
          isSubNutrient: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Sodium',
          icon: Icons.grain_rounded,
          isRequired: true,
          unit: 'mg',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Carbohydrates',
          icon: Icons.grass_rounded,
          isRequired: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Dietary Fiber',
          isSubNutrient: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Total Sugars',
          isSubNutrient: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Added Sugars',
          isSubNutrient: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
        NutrientRowData(
          label: 'Protein',
          icon: Icons.egg_outlined,
          isRequired: true,
          unit: 'g',
          controller: TextEditingController(text: ''),
        ),
      ];
    }
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

  SmallBusinessLabelModel _buildCurrentState() {
    final nutrientModels =
        _nutrients.asMap().entries.map((entry) {
          final idx = entry.key;
          final n = entry.value;
          return SmallBusinessNutrientModel(
            label: n.label,
            value: n.controller.text.trim(),
            unit: n.unit,
            isRequired: n.isRequired,
            isSubNutrient: n.isSubNutrient,
            orderIndex: idx + 1,
          );
        }).toList();

    return _currentModel.copyWith(
      netQuantity: _netQuantityController.text.trim(),
      netQuantityUnit: _netQuantityUnit,
      servingSize: _servingSizeController.text.trim(),
      servingSizeUnit: _servingSizeUnit,
      displayMode: _displayMode.name,
      labelFormat: _labelFormat.name,
      targetAudience: _targetAudience,
      ageGroup: _ageGroup,
      nutrients: nutrientModels,
      currentStep: 3,
      completionPercentage: 50,
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final modelToSave = _buildCurrentState();

    try {
      final saved = await _repository.saveDraft(modelToSave);
      if (mounted) {
        setState(() {
          _currentModel = saved;
          _isSaving = false;
        });

        _notificationService.notify(
          title: 'Nutritional Values Saved',
          message:
              'Saved nutrition table (${_nutrients.length} parameters) and serving dimensions.',
          type: NotificationType.success,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutritional values saved to draft'),
            backgroundColor: AppColors.brandDeepGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally: $e'),
            backgroundColor: AppColors.brandDeepGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _confirmDeleteDraft() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Draft?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to discard this draft label? All entered fields will be deleted.',
          style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (_currentModel.id != null) {
                await _repository.deleteLabel(_currentModel.id!);
              }

              _notificationService.notify(
                title: 'Draft Discarded',
                message: 'Deleted draft for "${_currentModel.productName.isNotEmpty ? _currentModel.productName : "New Label"}".',
                type: NotificationType.warning,
              );

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MyLabelStudioScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Draft'),
          ),
        ],
      ),
    );
  }

  void _addAdditionalNutrient() {
    if (_selectedAdditionalNutrient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a nutrient from the list to add.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final nutrientName = _selectedAdditionalNutrient!;
    String unit = 'g';
    if (nutrientName.contains('Vitamin') ||
        nutrientName.contains('Iron') ||
        nutrientName.contains('Zinc') ||
        nutrientName.contains('Calcium') ||
        nutrientName.contains('Magnesium') ||
        nutrientName.contains('Potassium') ||
        nutrientName.contains('Phosphorus') ||
        nutrientName.contains('Cholesterol')) {
      unit = 'mg';
    }
    if (nutrientName.contains('Iodine') ||
        nutrientName.contains('Selenium') ||
        nutrientName.contains('Vitamin B12') ||
        nutrientName.contains('Vitamin D')) {
      unit = 'mcg';
    }

    setState(() {
      _nutrients.add(
        NutrientRowData(
          label: nutrientName,
          unit: unit,
          controller: TextEditingController(text: ''),
        ),
      );
      _availableAdditionalNutrients.remove(nutrientName);
      _selectedAdditionalNutrient = null;
    });

    _notificationService.notify(
      title: 'Added Micronutrient',
      message: 'Added $nutrientName ($unit) to nutrition declaration table.',
      type: NotificationType.info,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $nutrientName to nutritional table.'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onNext() {
    final netQty = _netQuantityController.text.trim();
    final serving = _servingSizeController.text.trim();

    if (netQty.isEmpty) {
      _showValidationError('Please enter Net Quantity (Weight/Volume).');
      return;
    }
    if (serving.isEmpty) {
      _showValidationError('Please enter Serving Size.');
      return;
    }

    // Check mandatory baseline nutrients
    final calories = _getNutrientValue('Calories');
    final fat = _getNutrientValue('Total Fat');
    final carbs = _getNutrientValue('Carbohydrates');
    final protein = _getNutrientValue('Protein');
    final sodium = _getNutrientValue('Sodium');

    if (calories.isEmpty || fat.isEmpty || carbs.isEmpty || protein.isEmpty || sodium.isEmpty) {
      _showValidationError(
        'Please enter values for mandatory nutrients: Calories, Fat, Carbs, Protein, and Sodium.',
      );
      return;
    }

    final updatedModel = _buildCurrentState();

    _notificationService.notify(
      title: 'Step 3 Complete',
      message:
          'Nutrition facts verified for ${updatedModel.netQuantity}${updatedModel.netQuantityUnit}. Proceeding to Manufacturer Details.',
      type: NotificationType.compliance,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ManufacturerDetailsScreen(labelModel: updatedModel),
      ),
    );
  }

  String _getNutrientValue(String label) {
    final item = _nutrients.firstWhere(
      (n) => n.label.toLowerCase() == label.toLowerCase(),
      orElse: () => NutrientRowData(label: '', unit: '', controller: TextEditingController()),
    );
    return item.controller.text.trim();
  }

  void _showValidationError(String msg) {
    _notificationService.notify(
      title: 'Validation Incomplete',
      message: msg,
      type: NotificationType.warning,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
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
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.onSurface,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Nutritional Values',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Step 3 of 6 • Nutrition Profile',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification Bell
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(6),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.brandDeepGreen,
                          size: 22,
                        ),
                        onPressed:
                            () => SmallBusinessNotificationService
                                .showNotificationCenter(context),
                      ),
                      // Save Action Button
                      OutlinedButton(
                        onPressed: _isSaving ? null : _saveDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: AppColors.onSurface,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandDeepGreen,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.save_outlined,
                                    size: 14,
                                    color: AppColors.onSurface,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(width: 4),
                      // More PopupMenu for Delete Action
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeleteDraft();
                          } else if (value == 'save') {
                            _saveDraft();
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'save',
                            child: Row(
                              children: const [
                                Icon(Icons.save_outlined, size: 18, color: AppColors.onSurface),
                                SizedBox(width: 10),
                                Text('Save Draft', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: const [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                SizedBox(width: 10),
                                Text(
                                  'Delete Draft',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
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
            // Standardized Glassmorphic Progress Marker (Step 3 of 6, 50%)
            const WizardStepProgressCard(
              currentStep: 3,
              totalSteps: 6,
              stepTitle: 'Nutritional Values',
              percentage: 50,
            ),
            const SizedBox(height: 18),

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
            const SizedBox(height: 18),

            // Card 2: Show Nutrition Values Format Settings
            NutritionFormatSettingsCard(
              displayMode: _displayMode,
              labelFormat: _labelFormat,
              targetAudience: _targetAudience,
              ageGroup: _ageGroup,
              onDisplayModeChanged:
                  (mode) => setState(() => _displayMode = mode),
              onLabelFormatChanged:
                  (format) => setState(() => _labelFormat = format),
              onTargetAudienceChanged: (aud) {
                if (aud != null) setState(() => _targetAudience = aud);
              },
              onAgeGroupChanged: (grp) {
                if (grp != null) setState(() => _ageGroup = grp);
              },
            ),
            const SizedBox(height: 18),

            // Card 3: Nutrition Values Table Card with expanded nutrients
            NutritionValuesTableCard(
              nutrients: _nutrients,
              selectedAdditionalNutrient: _selectedAdditionalNutrient,
              availableAdditionalNutrients: _availableAdditionalNutrients,
              onAdditionalNutrientChanged:
                  (nutr) => setState(() => _selectedAdditionalNutrient = nutr),
              onAddNutrientTap: _addAdditionalNutrient,
            ),
            const SizedBox(height: 120), // Bottom bar padding to guarantee zero overflow
          ],
        ),
      ),
      bottomNavigationBar: NutritionBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSkip: _onNext,
        onNext: _onNext,
      ),
    );
  }
}
