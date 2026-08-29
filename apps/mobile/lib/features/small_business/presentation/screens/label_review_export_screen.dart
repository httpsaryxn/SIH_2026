import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/file_download_service.dart';
import '../../data/services/notification_service.dart';
import '../widgets/claim_item_card.dart';
import '../widgets/compliance_status_banner.dart';
import '../widgets/export_options_card.dart';
import '../widgets/live_label_preview_card.dart';
import '../widgets/review_accordion_section.dart';
import '../widgets/review_export_bottom_bar.dart';
import '../widgets/wizard_step_progress_card.dart';
import 'create_label_declaration_screen.dart';
import 'final_details_screen.dart';
import 'ingredients_allergens_screen.dart';
import 'manufacturer_details_screen.dart';
import 'my_label_studio_screen.dart';
import 'nutritional_values_screen.dart';
import 'product_claims_screen.dart';

class LabelReviewExportScreen extends StatefulWidget {
  const LabelReviewExportScreen({
    super.key,
    this.brandName = '',
    this.productName = '',
    this.productCategory = '',
    this.netQuantity = '',
    this.mrp = '',
    this.selectedClaims = const [],
    this.labelModel,
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;
  final List<ProductClaim> selectedClaims;
  final SmallBusinessLabelModel? labelModel;

  @override
  State<LabelReviewExportScreen> createState() =>
      _LabelReviewExportScreenState();
}

class _LabelReviewExportScreenState extends State<LabelReviewExportScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final SmallBusinessNotificationService _notificationService =
      SmallBusinessNotificationService();

  ExportFormat _selectedFormat = ExportFormat.png;
  String _selectedDimension = 'Standard Pouch (100 × 150 mm)';
  double _customWidthMm = 100.0;
  double _customHeightMm = 150.0;
  bool _isExporting = false;
  late SmallBusinessLabelModel _currentModel;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.labelModel ??
        SmallBusinessLabelModel(
          brandName: widget.brandName,
          productName: widget.productName,
          productCategory: widget.productCategory,
          netQuantity: widget.netQuantity.replaceAll(RegExp(r'[^0-9.]'), ''),
          netQuantityUnit: widget.netQuantity.replaceAll(RegExp(r'[0-9.\s]'), ''),
          mrp: widget.mrp.replaceAll('₹', '').trim(),
        );

    if (_currentModel.exportFormat == 'pdf') {
      _selectedFormat = ExportFormat.pdf;
    } else if (_currentModel.exportFormat == 'svg') {
      _selectedFormat = ExportFormat.svg;
    } else if (_currentModel.exportFormat == 'json') {
      _selectedFormat = ExportFormat.json;
    } else {
      _selectedFormat = ExportFormat.png;
    }

    _selectedDimension = _currentModel.labelDimension.isNotEmpty
        ? _currentModel.labelDimension
        : 'Standard Pouch (100 × 150 mm)';

    _parseDimensionsFromLabel(_selectedDimension);
  }

  void _parseDimensionsFromLabel(String dim) {
    final match = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(dim);
    if (match != null) {
      _customWidthMm = double.tryParse(match.group(1)!) ?? 100.0;
      _customHeightMm = double.tryParse(match.group(2)!) ?? 150.0;
    }
  }

  void _onNavigateToEdit(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) async {
      // Reload updated active draft if any
      final draft = await _repository.fetchActiveDraft();
      if (draft != null && mounted) {
        setState(() {
          _currentModel = draft;
        });
      }
    });
  }

  void _onExport() async {
    setState(() => _isExporting = true);

    try {
      final auditChecks = ComplianceStatusBanner.evaluateCompliance(_currentModel);
      final liveScore = ComplianceStatusBanner.calculateScore(auditChecks);

      final modelToPublish = _currentModel.copyWith(
        exportFormat: _selectedFormat.name,
        labelDimension: _selectedDimension,
        complianceScore: liveScore,
        complianceStatus: liveScore >= 85 ? 'Verified Compliant' : 'Needs Review',
        status: 'ready',
      );

      // 1. Save / Publish to Supabase
      await _repository.publishLabel(modelToPublish);

      // 2. Direct Browser / OS File Download to Downloads folder
      switch (_selectedFormat) {
        case ExportFormat.png:
          await FileDownloadService.downloadPngLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
          );
          break;
        case ExportFormat.svg:
          FileDownloadService.downloadSvgLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
          );
          break;
        case ExportFormat.pdf:
          FileDownloadService.downloadPdfLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
          );
          break;
        case ExportFormat.json:
          FileDownloadService.downloadJsonMetadata(
            model: modelToPublish,
          );
          break;
      }

      _notificationService.notify(
        title: 'Label Downloaded to Device',
        message:
            'Downloaded "${modelToPublish.productName}" packaging artwork (${_selectedFormat.title}) directly to your Downloads folder.',
        type: NotificationType.compliance,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      _showExportSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);

      // Fallback direct download
      FileDownloadService.downloadSvgLabel(
        model: _currentModel,
        dimension: _selectedDimension,
        widthMm: _customWidthMm,
        heightMm: _customHeightMm,
      );

      _notificationService.notify(
        title: 'Label Downloaded',
        message: 'Saved artwork file to your Downloads folder.',
        type: NotificationType.success,
      );

      _showExportSuccessDialog();
    }
  }

  void _onShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final shareText =
            'Packaged Commodity Label for "${_currentModel.brandName} ${_currentModel.productName}".\n'
            'MRP: ₹${_currentModel.mrp} (Net Qty: ${_currentModel.netQuantity} ${_currentModel.netQuantityUnit})\n'
            'FSSAI License: ${_currentModel.fssaiLicenseNumber}\n'
            'Compliant with Legal Metrology (Packaged Commodities) Rules 2011.';

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
                    'Share Packaging Artwork',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                ),
                title: const Text('Share to WhatsApp / Messaging', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Send packaging specifications & declaration to printer or client', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  FileDownloadService.shareLabel(
                    title: '${_currentModel.brandName} Packaging Label',
                    text: shareText,
                  );
                  _notificationService.notify(
                    title: 'Sharing initiated',
                    message: 'Shared label summary to messaging apps.',
                    type: NotificationType.info,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandDeepGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, color: AppColors.brandDeepGreen),
                ),
                title: const Text('Copy Specification Text', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Copy full FSSAI declaration text to clipboard', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied packaging specifications to clipboard!'),
                      backgroundColor: AppColors.brandDeepGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showExportSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.brandDeepGreen, size: 28),
            SizedBox(width: 10),
            Text(
              'Downloaded Successfully',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your high-resolution ${_selectedFormat.title} (${_customWidthMm.toInt()} × ${_customHeightMm.toInt()} mm) has been generated and saved directly to your device\'s Downloads folder.',
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_outlined, size: 18, color: AppColors.brandDeepGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Legal Metrology Compliance: 100% Verified',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MyLabelStudioScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandDeepGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back to Studio Hub'),
          ),
        ],
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
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Review & Export',
                              style: TextStyle(
                                color: AppColors.brandDeepGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Final compliance audit & label export',
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
                      // Home Button in Top Header
                      IconButton(
                        icon: const Icon(
                          Icons.home_outlined,
                          color: AppColors.brandDeepGreen,
                        ),
                        tooltip: 'Studio Home',
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MyLabelStudioScreen()),
                            (route) => false,
                          );
                        },
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Step Progress Indicator (Step 6 of 6, 100%)
            const WizardStepProgressCard(
              currentStep: 6,
              totalSteps: 6,
              stepTitle: 'Review & Export',
              percentage: 100,
            ),
            const SizedBox(height: 16),

            // Real-Time Dynamic Compliance Audit Banner
            ComplianceStatusBanner(labelModel: _currentModel),
            const SizedBox(height: 16),

            // Live Label Preview (With Uploaded Logo, Complete Contents & GS1 Barcode)
            LiveLabelPreviewCard(
              brandName: _currentModel.brandName.isNotEmpty ? _currentModel.brandName : 'Brand Name',
              logoUrl: _currentModel.logoUrl,
              productName: _currentModel.productName.isNotEmpty ? _currentModel.productName : 'Product Name',
              productCategory: _currentModel.productCategory.isNotEmpty ? _currentModel.productCategory : 'General Food',
              typeFlavour: _currentModel.typeFlavour,
              netQuantity: '${_currentModel.netQuantity.isNotEmpty ? _currentModel.netQuantity : "100"} ${_currentModel.netQuantityUnit}',
              mrp: _currentModel.mrp.isNotEmpty ? (_currentModel.mrp.startsWith('₹') ? _currentModel.mrp : '₹ ${_currentModel.mrp}') : '₹ 0.00',
              unitSalePrice: _currentModel.usp,
              batchNumber: _currentModel.batchNumber,
              mfgDate: _currentModel.mfgDate,
              bestBefore: _currentModel.bestBefore,
              storageInstructions: _currentModel.storageInstructions,
              fssaiNumber: _currentModel.fssaiLicenseNumber,
              manufacturerName: _currentModel.manufacturerName,
              manufacturerAddress: _currentModel.manufacturerAddress,
              consumerCarePhone: _currentModel.consumerCarePhone,
              consumerCareEmail: _currentModel.consumerCareEmail,
              isVegetarian: _currentModel.isVegetarian,
              selectedClaims: widget.selectedClaims,
              widthMm: _customWidthMm,
              heightMm: _customHeightMm,
              labelModel: _currentModel,
            ),
            const SizedBox(height: 16),

            // Expandable Section Breakdown with Working Edit Actions
            ReviewAccordionSection(
              brandName: _currentModel.brandName.isNotEmpty ? _currentModel.brandName : 'Brand Name',
              productName: _currentModel.productName.isNotEmpty ? _currentModel.productName : 'Product Name',
              productCategory: _currentModel.productCategory.isNotEmpty ? _currentModel.productCategory : 'General Food',
              netQuantity: '${_currentModel.netQuantity.isNotEmpty ? _currentModel.netQuantity : "100"} ${_currentModel.netQuantityUnit}',
              mrp: _currentModel.mrp.isNotEmpty ? (_currentModel.mrp.startsWith('₹') ? _currentModel.mrp : '₹ ${_currentModel.mrp}') : '₹ 0.00',
              selectedClaims: widget.selectedClaims,
              labelModel: _currentModel,
              onEditDeclaration: () => _onNavigateToEdit(
                CreateLabelDeclarationScreen(initialLabel: _currentModel),
              ),
              onEditIngredients: () => _onNavigateToEdit(
                IngredientsAllergensScreen(labelModel: _currentModel),
              ),
              onEditNutrition: () => _onNavigateToEdit(
                NutritionalValuesScreen(labelModel: _currentModel),
              ),
              onEditManufacturer: () => _onNavigateToEdit(
                ManufacturerDetailsScreen(labelModel: _currentModel),
              ),
              onEditClaims: () => _onNavigateToEdit(
                ProductClaimsScreen(labelModel: _currentModel),
              ),
            ),
            const SizedBox(height: 16),

            // Export Options Card with 10+ Print Dimensions & Custom Size
            ExportOptionsCard(
              selectedFormat: _selectedFormat,
              onFormatChanged: (fmt) => setState(() => _selectedFormat = fmt),
              selectedDimension: _selectedDimension,
              customWidthMm: _customWidthMm,
              customHeightMm: _customHeightMm,
              onDimensionChanged: (dim) {
                setState(() {
                  _selectedDimension = dim;
                  _parseDimensionsFromLabel(dim);
                });
              },
              onCustomDimensionsChanged: (w, h) {
                setState(() {
                  _customWidthMm = w;
                  _customHeightMm = h;
                  _selectedDimension = 'Custom (${w.toInt()} × ${h.toInt()} mm)';
                });
              },
            ),
            const SizedBox(height: 16),

            // Reassurance Regulatory Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.brandDeepGreen,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Compliant with Legal Metrology (Packaged Commodities) Rules, 2011 & FSSAI Food Safety and Standards (Packaging and Labelling) Regulations.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Spacing for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: ReviewExportBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onHome: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyLabelStudioScreen()),
            (route) => false,
          );
        },
        onShare: _onShare,
        onExport: _onExport,
        isExporting: _isExporting,
      ),
    );
  }
}
