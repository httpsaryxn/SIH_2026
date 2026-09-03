import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/notification_service.dart';
import '../widgets/dates_batch_pricing_card.dart';
import '../widgets/final_details_bottom_bar.dart';
import '../widgets/final_details_hero_card.dart';
import '../widgets/packaging_environmental_card.dart';
import '../widgets/storage_usage_card.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'my_label_studio_screen.dart';
import 'product_claims_screen.dart';

class FinalDetailsScreen extends StatefulWidget {
  const FinalDetailsScreen({
    super.key,
    this.brandName = '',
    this.productName = '',
    this.productCategory = '',
    this.netQuantity = '',
    this.mrp = '',
    this.labelModel,
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;
  final SmallBusinessLabelModel? labelModel;

  @override
  State<FinalDetailsScreen> createState() => _FinalDetailsScreenState();
}

class _FinalDetailsScreenState extends State<FinalDetailsScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();

  late final TextEditingController _mrpController;
  late final TextEditingController _uspController;
  late final TextEditingController _batchController;
  late final TextEditingController _mfgDateController;
  late String _selectedBestBefore;

  late final TextEditingController _storageController;
  late final TextEditingController _usageController;
  final List<String> _selectedStorageChips = [];

  late String _selectedPackagingType;
  late bool _isVegetarian;
  late String _selectedRecyclingMark;

  late SmallBusinessLabelModel _currentModel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.labelModel ?? const SmallBusinessLabelModel();

    final initialMrp = _currentModel.mrp.isNotEmpty
        ? _currentModel.mrp.replaceAll('₹', '').trim()
        : widget.mrp.replaceAll('₹', '').trim();

    _mrpController = TextEditingController(text: initialMrp);
    _uspController = TextEditingController(text: _currentModel.usp);
    _batchController = TextEditingController(text: _currentModel.batchNumber);
    _mfgDateController = TextEditingController(
      text: _currentModel.mfgDate.isNotEmpty
          ? _currentModel.mfgDate
          : 'AUG 2026',
    );
    _selectedBestBefore = _currentModel.bestBefore.isNotEmpty
        ? _currentModel.bestBefore
        : '12 Months from Packaging';

    _storageController = TextEditingController(
      text: _currentModel.storageInstructions,
    );
    _usageController = TextEditingController(
      text: _currentModel.usageInstructions ?? '',
    );

    _selectedPackagingType =
        _currentModel.packagingType.isNotEmpty
            ? _currentModel.packagingType
            : 'Food Grade Glass Jar';
    _isVegetarian = _currentModel.isVegetarian;
    _selectedRecyclingMark =
        _currentModel.recyclingMark.isNotEmpty
            ? _currentModel.recyclingMark
            : 'Keep Clean (MoEFCC Disposal Logo)';
  }

  @override
  void dispose() {
    _mrpController.dispose();
    _uspController.dispose();
    _batchController.dispose();
    _mfgDateController.dispose();
    _storageController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  SmallBusinessLabelModel _buildCurrentState() {
    return _currentModel.copyWith(
      mrp: _mrpController.text.trim(),
      usp: _uspController.text.trim(),
      batchNumber: _batchController.text.trim(),
      mfgDate: _mfgDateController.text.trim(),
      bestBefore: _selectedBestBefore,
      storageInstructions: _storageController.text.trim(),
      usageInstructions: _usageController.text.trim(),
      packagingType: _selectedPackagingType,
      isVegetarian: _isVegetarian,
      recyclingMark: _selectedRecyclingMark,
      currentStep: 5,
      completionPercentage: 83,
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
          title: 'Finishing Details Saved',
          message:
              'Saved pricing (MRP ₹${modelToSave.mrp}), batch ${modelToSave.batchNumber}, and packaging rules.',
          type: NotificationType.success,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Finishing details saved to draft'),
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

  void _autoCalculateUSP() {
    final mrpVal = double.tryParse(_mrpController.text.trim());
    if (mrpVal != null && mrpVal > 0) {
      final qty = double.tryParse(_currentModel.netQuantity) ?? 100.0;
      final unit = _currentModel.netQuantityUnit.isNotEmpty ? _currentModel.netQuantityUnit : 'g';
      final usp = mrpVal / qty;
      final calculated = '₹ ${usp.toStringAsFixed(2)} / $unit';

      setState(() {
        _uspController.text = calculated;
      });

      _notificationService.notify(
        title: 'USP Calculated',
        message: 'Auto-calculated Unit Sale Price: $calculated.',
        type: NotificationType.info,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calculated Unit Sale Price: $calculated'),
          backgroundColor: AppColors.brandDeepGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _showValidationError('Please enter a valid MRP before calculating USP.');
    }
  }

  void _generateBatchCode() {
    final now = DateTime.now();
    final year = now.year.toString();
    final monthChar = String.fromCharCode(65 + (now.month - 1));
    final randomNum = (now.millisecondsSinceEpoch % 90 + 10).toString();
    final prefix = _currentModel.brandName.isNotEmpty
        ? _currentModel.brandName.split(' ').first.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '')
        : 'BATCH';
    final newBatch = '$prefix-$year-$monthChar$randomNum';

    setState(() {
      _batchController.text = newBatch;
    });

    _notificationService.notify(
      title: 'Batch Code Generated',
      message: 'Created production lot identifier: $newBatch.',
      type: NotificationType.info,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated Batch Code: $newBatch'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleStorageChip(String chip) {
    setState(() {
      if (_selectedStorageChips.contains(chip)) {
        _selectedStorageChips.remove(chip);
      } else {
        _selectedStorageChips.add(chip);
      }
      _storageController.text = '${_selectedStorageChips.join('. ')}.';
    });
  }

  void _onContinue() {
    final mrpText = _mrpController.text.trim();
    final batch = _batchController.text.trim();
    final mfg = _mfgDateController.text.trim();
    final storage = _storageController.text.trim();

    if (mrpText.isEmpty || double.tryParse(mrpText) == null) {
      _showValidationError('Please enter Maximum Retail Price (MRP).');
      return;
    }
    if (batch.isEmpty) {
      _showValidationError('Please enter or generate a Batch / Lot Code.');
      return;
    }
    if (mfg.isEmpty) {
      _showValidationError('Please enter Manufacturing Date.');
      return;
    }
    if (storage.isEmpty) {
      _showValidationError('Please specify Storage Instructions.');
      return;
    }

    final updatedModel = _buildCurrentState();

    _notificationService.notify(
      title: 'Step 5 Complete',
      message:
          'Pricing, batch ($batch) & packaging rules verified. Moving to Product Claims.',
      type: NotificationType.compliance,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductClaimsScreen(
          brandName: updatedModel.brandName,
          productName: updatedModel.productName,
          productCategory: updatedModel.productCategory,
          netQuantity: '${updatedModel.netQuantity} ${updatedModel.netQuantityUnit}',
          mrp: mrpText.startsWith('₹') ? mrpText : '₹ $mrpText',
          labelModel: updatedModel,
        ),
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
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
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
                    vertical: 4.0,
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
                              Icons.arrow_back,
                              color: AppColors.brandDeepGreen,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Finishing Details',
                              style: TextStyle(
                                color: AppColors.brandDeepGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Step 5 of 6: Pricing, dates & packaging',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Delete Draft Icon Button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                        tooltip: 'Delete Draft',
                        onPressed: _confirmDeleteDraft,
                      ),
                      // Save Draft Button
                      OutlinedButton(
                        onPressed: _isSaving ? null : _saveDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
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
                            : const Text(
                                'Save draft',
                                style: TextStyle(
                                  fontSize: 12,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Step Marker (Step 5 of 6, 83%)
            const WizardStepProgressCard(
              currentStep: 5,
              totalSteps: 6,
              stepTitle: 'Finishing Details',
              percentage: 83,
            ),
            const SizedBox(height: 16),

            // Hero Card
            const FinalDetailsHeroCard(),
            const SizedBox(height: 16),

            // Card 1: Pricing, Batch Code & Dates
            DatesBatchPricingCard(
              mrpController: _mrpController,
              uspController: _uspController,
              batchController: _batchController,
              mfgDateController: _mfgDateController,
              selectedBestBefore: _selectedBestBefore,
              onBestBeforeChanged: (val) =>
                  setState(() => _selectedBestBefore = val),
              onAutoCalculateUSP: _autoCalculateUSP,
              onGenerateBatchCode: _generateBatchCode,
            ),
            const SizedBox(height: 16),

            // Card 2: Storage & Usage Instructions
            StorageUsageCard(
              storageController: _storageController,
              usageController: _usageController,
              selectedStorageChips: _selectedStorageChips,
              onToggleStorageChip: _toggleStorageChip,
            ),
            const SizedBox(height: 16),

            // Card 3: Packaging Material & Environmental Symbols
            PackagingEnvironmentalCard(
              selectedPackagingType: _selectedPackagingType,
              onPackagingTypeChanged: (val) =>
                  setState(() => _selectedPackagingType = val),
              isVegetarian: _isVegetarian,
              onVegetarianChanged: (val) =>
                  setState(() => _isVegetarian = val),
              selectedRecyclingMark: _selectedRecyclingMark,
              onRecyclingMarkChanged: (val) =>
                  setState(() => _selectedRecyclingMark = val),
            ),
            const SizedBox(height: 100), // Spacing for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: FinalDetailsBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSkip: _onContinue,
        onContinue: _onContinue,
      ),
    );
  }
}
