import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/notification_service.dart';
import '../widgets/business_hero_card.dart';
import '../widgets/business_info_card.dart';
import '../widgets/consumer_care_card.dart';
import '../widgets/manufacturer_details_card.dart';
import '../widgets/nutrition_bottom_bar.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'final_details_screen.dart';
import 'my_label_studio_screen.dart';

class ManufacturerDetailsScreen extends StatefulWidget {
  const ManufacturerDetailsScreen({super.key, this.labelModel});

  final SmallBusinessLabelModel? labelModel;

  @override
  State<ManufacturerDetailsScreen> createState() =>
      _ManufacturerDetailsScreenState();
}

class _ManufacturerDetailsScreenState extends State<ManufacturerDetailsScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();

  late final TextEditingController _businessNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _fssaiController;
  late final TextEditingController _marketedByController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;

  late bool _packerAddressSameAsManufacturer;
  late String _countryOfOrigin;
  late SmallBusinessLabelModel _currentModel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.labelModel ?? const SmallBusinessLabelModel();

    _businessNameController = TextEditingController(
      text: _currentModel.manufacturerName.isNotEmpty
          ? _currentModel.manufacturerName
          : _currentModel.brandName,
    );
    _addressController = TextEditingController(
      text: _currentModel.manufacturerAddress,
    );
    _fssaiController = TextEditingController(
      text: _currentModel.fssaiLicenseNumber,
    );
    _marketedByController = TextEditingController(
      text: _currentModel.marketedBy ?? '',
    );
    _phoneController = TextEditingController(
      text: _currentModel.consumerCarePhone,
    );
    _emailController = TextEditingController(
      text: _currentModel.consumerCareEmail,
    );
    _websiteController = TextEditingController(
      text: _currentModel.consumerCareWebsite ?? '',
    );

    _packerAddressSameAsManufacturer =
        _currentModel.packerAddressSameAsManufacturer;
    _countryOfOrigin = _currentModel.countryOfOrigin.isNotEmpty ? _currentModel.countryOfOrigin : 'India';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _fssaiController.dispose();
    _marketedByController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  SmallBusinessLabelModel _buildCurrentState() {
    return _currentModel.copyWith(
      manufacturerName: _businessNameController.text.trim(),
      manufacturerAddress: _addressController.text.trim(),
      packerAddressSameAsManufacturer: _packerAddressSameAsManufacturer,
      fssaiLicenseNumber: _fssaiController.text.trim(),
      marketedBy: _marketedByController.text.trim(),
      countryOfOrigin: _countryOfOrigin,
      consumerCarePhone: _phoneController.text.trim(),
      consumerCareEmail: _emailController.text.trim(),
      consumerCareWebsite: _websiteController.text.trim(),
      currentStep: 4,
      completionPercentage: 67,
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
          title: 'Manufacturer Details Saved',
          message:
              'Saved facility information and FSSAI license (${modelToSave.fssaiLicenseNumber.isNotEmpty ? modelToSave.fssaiLicenseNumber : "Pending"}).',
          type: NotificationType.success,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manufacturer details saved to draft'),
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

  void _onNext() {
    final businessName = _businessNameController.text.trim();
    final address = _addressController.text.trim();
    final fssai = _fssaiController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (businessName.isEmpty) {
      _showValidationError('Please enter Business / Manufacturer Name.');
      return;
    }
    if (address.isEmpty) {
      _showValidationError('Please enter Manufacturing Facility Address.');
      return;
    }
    if (fssai.isEmpty) {
      _showValidationError('Please enter your 14-digit FSSAI License Number.');
      return;
    }
    if (fssai.length != 14 || int.tryParse(fssai) == null) {
      _showValidationError('FSSAI License Number must be exactly 14 digits.');
      return;
    }
    if (phone.isEmpty) {
      _showValidationError('Please enter Consumer Care Phone number.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showValidationError('Please enter a valid Consumer Care Email address.');
      return;
    }

    final updatedModel = _buildCurrentState();

    _notificationService.notify(
      title: 'Step 4 Complete',
      message:
          '14-digit FSSAI ($fssai) and manufacturer profile verified. Proceeding to Finishing Details.',
      type: NotificationType.compliance,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinalDetailsScreen(labelModel: updatedModel),
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
        preferredSize: const Size.fromHeight(64),
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
                    vertical: 8.0,
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
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Manufacturer & Business',
                              style: TextStyle(
                                color: AppColors.brandDeepGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Step 4 of 6: FSSAI license & contact',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification Bell
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.brandDeepGreen,
                        ),
                        onPressed:
                            () => SmallBusinessNotificationService
                                .showNotificationCenter(context),
                      ),
                      // Delete Draft Button
                      OutlinedButton(
                        onPressed: _confirmDeleteDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          minimumSize: const Size(0, 0),
                          side: const BorderSide(
                            color: Color(0xFFFCA5A5),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: AppColors.error,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                            SizedBox(width: 2),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Save Draft Button
                      OutlinedButton(
                        onPressed: _isSaving ? null : _saveDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          minimumSize: const Size(0, 0),
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isSaving
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
                                    color: AppColors.brandDeepGreen,
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
            // Standardized Step Progress Bar (Step 4 of 6, 67%)
            const WizardStepProgressCard(
              currentStep: 4,
              totalSteps: 6,
              stepTitle: 'Manufacturer & FSSAI Details',
              percentage: 67,
            ),
            const SizedBox(height: 16),

            // Hero Card: Business & Manufacturer (Vector Banner)
            const BusinessHeroCard(),
            const SizedBox(height: 16),

            // Card 1: Manufacturer Details
            ManufacturerDetailsCard(
              nameController: _businessNameController,
              addressController: _addressController,
              packerAddressSameAsManufacturer: _packerAddressSameAsManufacturer,
              onPackerSameChanged: (value) {
                if (value != null) {
                  setState(() => _packerAddressSameAsManufacturer = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Card 2: Business Information
            BusinessInfoCard(
              fssaiController: _fssaiController,
              marketedByController: _marketedByController,
              countryOfOrigin: _countryOfOrigin,
              onCountryChanged: (value) {
                if (value != null) {
                  setState(() => _countryOfOrigin = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Card 3: Consumer Care Details
            ConsumerCareCard(
              phoneController: _phoneController,
              emailController: _emailController,
              websiteController: _websiteController,
            ),
            const SizedBox(height: 100), // Bottom bar padding
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
