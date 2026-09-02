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
                              'Manufacturer & Business Profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'STEP 4 OF 6 • NUTRITION PROFILE',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
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
            // Glassmorphism Step Progress Card (Step 4 of 6, 67%)
            const WizardStepProgressCard(
              currentStep: 4,
              totalSteps: 6,
              stepTitle: 'Manufacturer & Business Profile',
              percentage: 67,
            ),
            const SizedBox(height: 18),

            // Hero Card: Business & Manufacturing Facility Summary
            const BusinessHeroCard(),
            const SizedBox(height: 18),

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
            const SizedBox(height: 18),

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
            const SizedBox(height: 18),

            // Card 3: Consumer Care Details
            ConsumerCareCard(
              phoneController: _phoneController,
              emailController: _emailController,
              websiteController: _websiteController,
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
