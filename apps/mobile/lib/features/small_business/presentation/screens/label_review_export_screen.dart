import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/claim_item_card.dart';
import '../widgets/compliance_status_banner.dart';
import '../widgets/export_options_card.dart';
import '../widgets/live_label_preview_card.dart';
import '../widgets/review_accordion_section.dart';
import '../widgets/review_export_bottom_bar.dart';
import '../widgets/review_progress_header.dart';
import 'my_label_studio_screen.dart';

class LabelReviewExportScreen extends StatefulWidget {
  const LabelReviewExportScreen({
    super.key,
    this.brandName = 'Desi Harvest',
    this.productName = 'Authentic Mango Pickle',
    this.productCategory = 'Pickles & Condiments',
    this.netQuantity = '250 g',
    this.mrp = '₹ 149.00',
    this.selectedClaims = const [],
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;
  final List<ProductClaim> selectedClaims;

  @override
  State<LabelReviewExportScreen> createState() =>
      _LabelReviewExportScreenState();
}

class _LabelReviewExportScreenState extends State<LabelReviewExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  String _selectedDimension = 'Standard Pouch (100 × 150 mm)';
  bool _isExporting = false;

  void _onExport() async {
    setState(() => _isExporting = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isExporting = false);

    _showExportSuccessDialog();
  }

  void _onShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preparing ${_selectedFormat.title} label package for sharing...',
        ),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 2),
      ),
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
              'Label Ready to Print',
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
              'Your high-resolution ${_selectedFormat.title} for "${widget.productName}" has been generated successfully and saved to your downloads.',
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
                children: [
                  const Icon(Icons.verified_outlined, size: 18, color: AppColors.brandDeepGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Legal Metrology Compliance: 98% Verified',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                      const SizedBox(width: 6),

                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Review & Export',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Final compliance audit & label packaging export',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Done Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.brandDeepGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: AppColors.brandDeepGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandDeepGreen.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 400,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF005AC2).withValues(alpha: 0.05),
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
                // Step Progress Indicator (Step 6 of 6, 100%)
                const ReviewProgressHeader(
                  currentStep: 6,
                  totalSteps: 6,
                  stepTitle: 'Review & Export',
                  percentage: 100,
                ),
                const SizedBox(height: 16),

                // Compliance Audit Banner
                const ComplianceStatusBanner(score: 98),
                const SizedBox(height: 16),

                // Live Label Preview (Centerpiece)
                LiveLabelPreviewCard(
                  brandName: widget.brandName,
                  productName: widget.productName,
                  productCategory: widget.productCategory,
                  netQuantity: widget.netQuantity,
                  mrp: widget.mrp,
                  selectedClaims: widget.selectedClaims,
                ),
                const SizedBox(height: 16),

                // Expandable Section Breakdown with Edit Actions
                ReviewAccordionSection(
                  brandName: widget.brandName,
                  productName: widget.productName,
                  productCategory: widget.productCategory,
                  netQuantity: widget.netQuantity,
                  mrp: widget.mrp,
                  selectedClaims: widget.selectedClaims,
                  onEditDeclaration: () => Navigator.of(context).pop(),
                  onEditIngredients: () => Navigator.of(context).pop(),
                  onEditNutrition: () => Navigator.of(context).pop(),
                  onEditManufacturer: () => Navigator.of(context).pop(),
                  onEditClaims: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),

                // Export Options Card
                ExportOptionsCard(
                  selectedFormat: _selectedFormat,
                  onFormatChanged: (fmt) => setState(() => _selectedFormat = fmt),
                  selectedDimension: _selectedDimension,
                  onDimensionChanged: (dim) =>
                      setState(() => _selectedDimension = dim),
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
        ],
      ),
      bottomNavigationBar: ReviewExportBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onShare: _onShare,
        onExport: _onExport,
        isExporting: _isExporting,
      ),
    );
  }
}
