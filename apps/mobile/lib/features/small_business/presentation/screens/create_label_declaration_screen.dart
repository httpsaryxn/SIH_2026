import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/file_upload_service.dart';
import '../../data/services/notification_service.dart';
import '../widgets/create_label_bottom_bar.dart';
import '../widgets/declaration_hero_card.dart';
import '../widgets/product_basic_details_form.dart';
import '../widgets/product_category_selector.dart';
import '../widgets/trust_callout_card.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'ingredients_allergens_screen.dart';
import 'my_label_studio_screen.dart';

class CreateLabelDeclarationScreen extends StatefulWidget {
  const CreateLabelDeclarationScreen({super.key, this.initialLabel});

  final SmallBusinessLabelModel? initialLabel;

  @override
  State<CreateLabelDeclarationScreen> createState() =>
      _CreateLabelDeclarationScreenState();
}

class _CreateLabelDeclarationScreenState
    extends State<CreateLabelDeclarationScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();

  late final TextEditingController _brandNameController;
  late final TextEditingController _productNameController;
  late final TextEditingController _typeFlavourController;

  String? _selectedCategory;
  String? _uploadedLogoName;
  String? _uploadedLogoDataUrl;
  late SmallBusinessLabelModel _currentModel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.initialLabel ?? const SmallBusinessLabelModel();

    _brandNameController = TextEditingController(text: _currentModel.brandName);
    _productNameController = TextEditingController(
      text: _currentModel.productName,
    );
    _typeFlavourController = TextEditingController(
      text: _currentModel.typeFlavour,
    );

    _selectedCategory =
        _currentModel.productCategory.isNotEmpty
            ? _currentModel.productCategory
            : null;

    if (_currentModel.logoUrl != null && _currentModel.logoUrl!.isNotEmpty) {
      _uploadedLogoName = 'brand_logo.png';
      _uploadedLogoDataUrl = _currentModel.logoUrl;
    }
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _productNameController.dispose();
    _typeFlavourController.dispose();
    super.dispose();
  }

  SmallBusinessLabelModel _buildCurrentState() {
    return _currentModel.copyWith(
      brandName: _brandNameController.text.trim(),
      productName: _productNameController.text.trim(),
      productCategory: _selectedCategory ?? '',
      typeFlavour: _typeFlavourController.text.trim(),
      logoUrl: _uploadedLogoDataUrl ?? _currentModel.logoUrl,
      currentStep: 1,
      completionPercentage: 17,
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
              'Product declaration saved for "${modelToSave.productName.isNotEmpty ? modelToSave.productName : "New Product"}".',
          type: NotificationType.success,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved to Supabase cloud'),
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
            content: Text('Saved locally (Offline): $e'),
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

  Future<void> _uploadLogoFromSystem() async {
    final picked = await FileUploadService.pickImage();
    if (picked != null && mounted) {
      setState(() {
        _uploadedLogoName = picked.name;
        _uploadedLogoDataUrl = picked.dataUrl;
      });

      _notificationService.notify(
        title: 'Logo Uploaded',
        message: 'Selected "${picked.name}" (${picked.formattedSize}) from system file manager.',
        type: NotificationType.info,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached logo: ${picked.name} (${picked.formattedSize})'),
          backgroundColor: AppColors.brandDeepGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCategoryHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.gavel_rounded, color: AppColors.brandDeepGreen, size: 22),
                SizedBox(width: 8),
                Text('Legal Metrology Guidance'),
              ],
            ),
            content: const Text(
              'Under Legal Metrology (Packaged Commodities) Rules, 2011 and FSSAI Packaging Regulations, selecting your exact food category configures mandatory declaration rules, unit formats, and specific nutritional tolerance levels.',
              style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDeepGreen)),
              ),
            ],
          ),
    );
  }

  void _onContinue() {
    final brand = _brandNameController.text.trim();
    final product = _productNameController.text.trim();

    if (brand.isEmpty) {
      _showValidationError('Please enter your Brand Name.');
      return;
    }
    if (product.isEmpty) {
      _showValidationError('Please enter your Product Name.');
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showValidationError('Please select a Product Category.');
      return;
    }

    final updatedModel = _buildCurrentState();

    _notificationService.notify(
      title: 'Step 1 Complete',
      message:
          'Declaration validated for ${updatedModel.brandName} - ${updatedModel.productName}. Moving to Ingredients.',
      type: NotificationType.compliance,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => IngredientsAllergensScreen(labelModel: updatedModel),
      ),
    );
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
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Create Label',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Step 1 of 6 • Product Declaration',
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
                      // Notification Bell Icon Button
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
                      // Save Draft Button
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
                      // More Options Menu (Delete Draft)
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
            // Standardized Progress Marker (Step 1 of 6, 17%)
            const WizardStepProgressCard(
              currentStep: 1,
              totalSteps: 6,
              stepTitle: 'Product Declaration',
              percentage: 17,
            ),
            const SizedBox(height: 18),

            // Hero Section
            const DeclarationHeroCard(),
            const SizedBox(height: 18),

            // Product Category Selector
            ProductCategorySelector(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              onHelpTap: _onCategoryHelp,
            ),
            const SizedBox(height: 18),

            // Product Details Form with System File Manager Picker
            ProductBasicDetailsForm(
              brandNameController: _brandNameController,
              productNameController: _productNameController,
              typeFlavourController: _typeFlavourController,
              uploadedLogoName: _uploadedLogoName,
              uploadedLogoDataUrl: _uploadedLogoDataUrl,
              onUploadLogoTap: _uploadLogoFromSystem,
            ),
            const SizedBox(height: 18),

            // Trust Callout Card
            const TrustCalloutCard(),
            const SizedBox(height: 100), // Spacing for sticky bottom bar
          ],
        ),
      ),
      bottomNavigationBar: CreateLabelBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSaveDraft: _saveDraft,
        onContinue: _onContinue,
      ),
    );
  }
}
