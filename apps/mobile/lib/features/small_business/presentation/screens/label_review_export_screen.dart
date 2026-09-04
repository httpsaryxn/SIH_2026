import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final GlobalKey _labelRepaintKey = GlobalKey();

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

    // Immediately persist finalized label to both Supabase and Local Cache
    _repository.publishLabel(_currentModel);
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
    );
  }

  Future<void> _onExport() async {
    setState(() => _isExporting = true);

    try {
      final modelToPublish = _currentModel.copyWith(
        status: 'ready',
        currentStep: 6,
        completionPercentage: 100,
        exportFormat: _selectedFormat.name,
        labelDimension: _selectedDimension,
      );

      // 1. Save and publish label to repository
      try {
        await _repository.publishLabel(modelToPublish);
      } catch (e) {
        debugPrint('Persist on export note: $e');
      }

      // 2. Direct Browser / OS File Download to Downloads folder
      String? savedFilePath;
      switch (_selectedFormat) {
        case ExportFormat.png:
          List<int>? pngBytes;
          try {
            await WidgetsBinding.instance.endOfFrame;
            final boundary = _labelRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
            if (boundary != null) {
              if (boundary.debugNeedsPaint) {
                await Future.delayed(const Duration(milliseconds: 50));
              }
              final image = await boundary.toImage(pixelRatio: 3.0);
              final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
              if (byteData != null) {
                pngBytes = byteData.buffer.asUint8List();
              }
            }
          } catch (e) {
            debugPrint('RepaintBoundary capture error: $e');
          }

          savedFilePath = await FileDownloadService.downloadPngLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
            preRenderedBytes: pngBytes,
          );
          break;
        case ExportFormat.svg:
          savedFilePath = await FileDownloadService.downloadSvgLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
          );
          break;
        case ExportFormat.pdf:
          savedFilePath = await FileDownloadService.downloadPdfLabel(
            model: modelToPublish,
            dimension: _selectedDimension,
            widthMm: _customWidthMm,
            heightMm: _customHeightMm,
          );
          break;
        case ExportFormat.json:
          savedFilePath = await FileDownloadService.downloadJsonMetadata(
            model: modelToPublish,
          );
          break;
      }

      _notificationService.notify(
        title: 'Label Downloaded to Device',
        message:
            'Downloaded "${modelToPublish.productName}" packaging artwork (${_selectedFormat.name.toUpperCase()}) directly to your device.',
        type: NotificationType.compliance,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      final displayFileName = savedFilePath != null
          ? savedFilePath.split(r'/').last.split(r'\').last
          : '${modelToPublish.productName}_artwork.${_selectedFormat.name}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $displayFileName'),
          backgroundColor: AppColors.brandDeepGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      _showExportSuccessDialog(savedFilePath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      
      _notificationService.notify(
        title: 'Download Error',
        message: 'Could not export file. Please try again.',
        type: NotificationType.warning,
      );
    }
  }

  void _confirmDeleteLabel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Label?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_currentModel.productName.isNotEmpty ? _currentModel.productName : "this label"}"? This action will permanently remove it from your studio.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Label deleted from studio'),
                    backgroundColor: AppColors.error,
                    duration: Duration(seconds: 2),
                  ),
                );
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
            child: const Text('Delete Label'),
          ),
        ],
      ),
    );
  }

  void _onShare() {
    final bName = _currentModel.brandName.isNotEmpty ? _currentModel.brandName : 'Brand';
    final pName = _currentModel.productName.isNotEmpty ? _currentModel.productName : 'Product';
    final mrpVal = _currentModel.mrp.isNotEmpty ? _currentModel.mrp : '0.00';
    final netQty = '${_currentModel.netQuantity} ${_currentModel.netQuantityUnit}';
    final fssai = _currentModel.fssaiLicenseNumber.isNotEmpty ? _currentModel.fssaiLicenseNumber : 'N/A';

    final shareText =
        'Packaged Commodity Label for "$bName $pName".\n'
        'MRP: ₹$mrpVal (Net Qty: $netQty)\n'
        'FSSAI License: $fssai\n'
        'Compliant with Legal Metrology (Packaged Commodities) Rules 2011 & FSSAI Packaging Regulations.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
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

                // Option 1: Native System Share Sheet to Apps (WhatsApp, Gmail, Messages, etc.)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.share_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Share to Apps (WhatsApp, Gmail, etc.)'),
                  subtitle: const Text('Open Android system share sheet with all apps', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    FileDownloadService.shareLabel(
                      title: '$bName $pName Packaging Specification',
                      text: shareText,
                    );
                  },
                ),

                // Option 2: Share Artwork Image / File
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.image_outlined, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Share Artwork File'),
                  subtitle: const Text('Export and share high-res artwork image', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    List<int>? pngBytes;
                    try {
                      final boundary = _labelRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                      if (boundary != null) {
                        final image = await boundary.toImage(pixelRatio: 3.0);
                        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                        if (byteData != null) {
                          pngBytes = byteData.buffer.asUint8List();
                        }
                      }
                    } catch (_) {}

                    final savedPath = await FileDownloadService.downloadPngLabel(
                      model: _currentModel,
                      dimension: _selectedDimension,
                      widthMm: _customWidthMm,
                      heightMm: _customHeightMm,
                      preRenderedBytes: pngBytes,
                      shareOnMobile: false,
                    );

                    FileDownloadService.shareLabel(
                      title: '$bName $pName Artwork',
                      text: shareText,
                      filePath: savedPath,
                    );
                  },
                ),

                // Option 3: Copy Declaration Summary
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.file_copy_outlined, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Copy Declaration Summary'),
                  subtitle: const Text('Copy full FSSAI declaration text to clipboard', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Declaration copied to clipboard!'),
                        backgroundColor: AppColors.brandDeepGreen,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExportSuccessDialog([String? savedFilePath]) {
    final fileName = savedFilePath != null
        ? savedFilePath.split(r'/').last.split(r'\').last
        : '${_currentModel.productName}_artwork.${_selectedFormat.name}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.brandDeepGreen, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Artwork Exported!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your print-ready ${_selectedFormat.name.toUpperCase()} file "$fileName" has been generated and saved to your device.',
              style: const TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.brandDeepGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Format: ${_selectedFormat.name.toUpperCase()} • Spec: $_selectedDimension',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
            if (savedFilePath != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  FileDownloadService.shareLabel(
                    title: 'Packaging Label: $fileName',
                    text: 'Exported packaging label artwork: $fileName',
                    filePath: savedFilePath,
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share / Open / Save to Device'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandDeepGreen,
                  side: const BorderSide(color: AppColors.brandDeepGreen),
                  minimumSize: const Size(double.infinity, 42),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Editing'),
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
              elevation: 0,
            ),
            child: const Text('Back to Studio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Export Print Artwork',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Label',
            onPressed: _confirmDeleteLabel,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _onShare,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Progress Marker (Step 6 of 6, 100%)
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

            // Live Label Preview (With Uploaded Logo, Complete Contents & GS1 Barcode wrapped in RepaintBoundary)
            RepaintBoundary(
              key: _labelRepaintKey,
              child: LiveLabelPreviewCard(
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

            // Delete Created Label Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _confirmDeleteLabel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Delete Created Label',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        onExport: _onExport,
        isExporting: _isExporting,
      ),
    );
  }
}
