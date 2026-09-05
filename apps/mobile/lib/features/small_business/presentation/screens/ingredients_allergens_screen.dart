import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/file_upload_service.dart';
import '../../data/services/notification_service.dart';
import '../widgets/allergen_declaration_section.dart';
import '../widgets/ingredient_search_card.dart';
import '../widgets/ingredient_source_segmented_control.dart';
import '../widgets/ingredients_bottom_bar.dart';
import '../widgets/ingredients_header_card.dart';
import '../widgets/ingredients_list_section.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'my_label_studio_screen.dart';
import 'nutritional_values_screen.dart';

class IngredientsAllergensScreen extends StatefulWidget {
  const IngredientsAllergensScreen({super.key, this.labelModel});

  final SmallBusinessLabelModel? labelModel;

  @override
  State<IngredientsAllergensScreen> createState() =>
      _IngredientsAllergensScreenState();
}

class _IngredientsAllergensScreenState
    extends State<IngredientsAllergensScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();
  final TextEditingController _searchController = TextEditingController();

  IngredientSourceType _selectedSource = IngredientSourceType.noLabReport;
  final List<IngredientItem> _ingredients = [];
  final List<String> _selectedAllergens = [];
  late SmallBusinessLabelModel _currentModel;
  bool _isSaving = false;

  String? _uploadedReportName;
  bool _isAnalyzingReport = false;

  final List<String> _availableAllergens = [
    'Peanuts',
    'Milk & Dairy Solids',
    'Tree Nuts (Almonds, Cashews, Walnuts)',
    'Soy / Soybeans',
    'Wheat / Gluten',
    'Eggs & Egg Products',
    'Fish',
    'Crustaceans / Shellfish',
    'Mustard & Mustard Seeds',
    'Sesame Seeds (Til)',
    'Sulphites (in concentrations of 10mg/kg or more)',
    'Celery',
  ];

  @override
  void initState() {
    super.initState();
    _currentModel = widget.labelModel ?? const SmallBusinessLabelModel();

    if (_currentModel.ingredients.isNotEmpty) {
      for (final ing in _currentModel.ingredients) {
        _ingredients.add(
          IngredientItem(
            id: ing.id ?? UniqueKey().toString(),
            name: ing.name,
            percentage: ing.percentage,
          ),
        );
      }
    }

    if (_currentModel.allergens.isNotEmpty) {
      _selectedAllergens.addAll(_currentModel.allergens);
    }

    if (_currentModel.ingredientSource == 'labReport') {
      _selectedSource = IngredientSourceType.labReport;
      _uploadedReportName = 'lab_report_certificate.pdf';
    } else {
      _selectedSource = IngredientSourceType.noLabReport;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  SmallBusinessLabelModel _buildCurrentState() {
    final ingModels =
        _ingredients.map((i) {
          return SmallBusinessIngredientModel(
            id: i.id,
            name: i.name,
            percentage: i.percentage,
          );
        }).toList();

    return _currentModel.copyWith(
      ingredientSource: _selectedSource.name,
      ingredients: ingModels,
      allergens: _selectedAllergens,
      currentStep: 2,
      completionPercentage: 33,
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
          title: 'Draft Saved',
          message:
              'Saved ${_ingredients.length} ingredients and ${_selectedAllergens.length} declared allergens.',
          type: NotificationType.success,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved. You can continue anytime from drafts.'),
            backgroundColor: AppColors.brandDeepGreen,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyLabelStudioScreen()),
          (route) => false,
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
          'Are you sure you want to discard this draft? All entered fields will be deleted.',
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
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Opens system file manager to upload Lab Report and triggers AI auto-detection
  Future<void> _uploadLabReport() async {
    final pickedFile = await FileUploadService.pickLabReportChooser(context);
    if (pickedFile == null) return;

    setState(() {
      _isAnalyzingReport = true;
      _uploadedReportName = pickedFile.name;
    });

    try {
      final detected = await FileUploadService.parseLabReport(pickedFile);

      if (!mounted) return;

      setState(() {
        _isAnalyzingReport = false;
        // Auto-fill ingredients
        _ingredients.clear();
        for (final ing in detected.ingredients) {
          _ingredients.add(
            IngredientItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + ing.name,
              name: ing.name,
              percentage: ing.percentage,
            ),
          );
        }

        // Auto-fill allergens
        _selectedAllergens.clear();
        _selectedAllergens.addAll(detected.allergens);

        // Pre-fill nutrient CoA model
        final nutrientList = detected.nutrients.entries.map((e) {
          return SmallBusinessNutrientModel(
            label: e.key,
            value: e.value,
            unit: e.key == 'Calories' ? 'kcal' : (e.key.contains('Sodium') || e.key.contains('Iron') || e.key.contains('Vitamin') ? 'mg' : 'g'),
            isRequired: true,
          );
        }).toList();

        _currentModel = _currentModel.copyWith(
          nutrients: nutrientList,
          ingredientSource: 'labReport',
        );
      });

      _notificationService.notify(
        title: 'Lab Report Auto-Detected',
        message:
            'Extracted ${detected.ingredients.length} ingredients, ${detected.allergens.length} allergens, and ${detected.nutrients.length} nutrition metrics from ${pickedFile.name}.',
        type: NotificationType.compliance,
      );

      _showAutoDetectionDialog(detected);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing lab report: $e')),
      );
    }
  }

  void _showAutoDetectionDialog(DetectedLabReportData data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 24),
            SizedBox(width: 8),
            Text(
              'Lab Report Auto-Detected!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We extracted the verified parameters from "${data.fileName}" (${data.laboratoryName}):',
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ ${data.ingredients.length} Formulation Ingredients auto-filled',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✓ ${data.allergens.length} Allergen statement(s) tagged',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✓ ${data.nutrients.length} Nutritional values loaded for Step 3',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue with Auto-Filled Data'),
          ),
        ],
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
                      'Add Formulation Ingredient',
                      style: TextStyle(
                        fontSize: 17,
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
                  'Ingredient Name *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: initialName.isEmpty,
                  decoration: InputDecoration(
                    hintText: 'e.g. Raw Mango Pieces, Mustard Oil, Salt',
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
                  'Percentage Weight (% w/w) - Optional',
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
                    hintText: 'e.g. 60.0',
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
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            name: name,
                            percentage: percentage,
                          ),
                        );
                        _searchController.clear();
                      });

                      _notificationService.notify(
                        title: 'Ingredient Added',
                        message:
                            'Added "$name"${percentage != null ? " ($percentage%)" : ""} to ingredient declaration list.',
                        type: NotificationType.info,
                      );

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FSSAI Mandatory Allergen Declaration',
                    style: TextStyle(
                      fontSize: 17,
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
              const SizedBox(height: 8),
              const Text(
                'Select any allergens present in this formulation or handled on the same production line:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableAllergens.map((allergen) {
                      final isSelected = _selectedAllergens.contains(allergen);
                      return FilterChip(
                        label: Text(allergen),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergens.add(allergen);
                              _notificationService.notify(
                                title: 'Allergen Declared',
                                message:
                                    'Added "$allergen" to mandatory allergen warning statement.',
                                type: NotificationType.warning,
                              );
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
                          color:
                              isSelected
                                  ? const Color(0xFF80253D)
                                  : AppColors.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
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
    if (_ingredients.isEmpty) {
      _showValidationError(
        'Please add at least 1 ingredient in your formulation list.',
      );
      return;
    }

    final updatedModel = _buildCurrentState();

    _notificationService.notify(
      title: 'Step 2 Complete',
      message:
          'Ingredients list validated with ${_ingredients.length} items. Proceeding to Nutritional Values.',
      type: NotificationType.compliance,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NutritionalValuesScreen(labelModel: updatedModel),
      ),
    );
  }

  void _showValidationError(String msg) {
    _notificationService.notify(
      title: 'Validation Required',
      message: msg,
      type: NotificationType.warning,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
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
        preferredSize: const Size.fromHeight(70),
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
                              'Formulation & Allergens',
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
                              'Step 2 of 6 • Ingredients list',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Notification Bell Button
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
                      // Save action button
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
                      // More PopupMenu for Delete action
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
            // Standardized Progress Marker (Step 2 of 6, 33%)
            const WizardStepProgressCard(
              currentStep: 2,
              totalSteps: 6,
              stepTitle: 'Ingredients & Allergens',
              percentage: 33,
            ),
            const SizedBox(height: 18),

            // Header Card ("STEP 02 - Formulation & Ingredients")
            const IngredientsHeaderCard(),
            const SizedBox(height: 18),

            // Nutrition/Ingredient Source Segmented Control with Lab Report Upload
            IngredientSourceSegmentedControl(
              selectedSource: _selectedSource,
              uploadedReportName: _uploadedReportName,
              isAnalyzingReport: _isAnalyzingReport,
              onSourceChanged: (source) {
                setState(() {
                  _selectedSource = source;
                });
              },
              onUploadLabReportTap: _uploadLabReport,
            ),
            const SizedBox(height: 18),

            // Search Card with Instant Suggestions
            IngredientSearchCard(
              controller: _searchController,
              onIngredientSelected: (name) => _showAddIngredientDialog(name),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _showAddIngredientDialog(value.trim());
                }
              },
              onAddManually: () => _showAddIngredientDialog(),
            ),
            const SizedBox(height: 18),

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
            const SizedBox(height: 18),

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
            const SizedBox(height: 120), // Bottom bar padding to guarantee zero bottom overflow
          ],
        ),
      ),
      bottomNavigationBar: IngredientsBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onContinue: _onContinue,
      ),
    );
  }
}
