import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_scan_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/consumer_data_service.dart';

class ScannerModalSheet extends StatefulWidget {
  final Function(ConsumerScanModel scanResult) onScanCompleted;

  const ScannerModalSheet({super.key, required this.onScanCompleted});

  @override
  State<ScannerModalSheet> createState() => _ScannerModalSheetState();
}

class _ScannerModalSheetState extends State<ScannerModalSheet> {
  List<ProductModel> _productsCatalog = [];
  bool _isLoadingCatalog = true;
  bool _isProcessing = false;
  String _processingStep = 'Aligning camera...';
  ProductModel? _selectedProduct;

  bool _isFailureState = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final products = await ConsumerDataService.fetchProductsCatalog();
    if (mounted) {
      setState(() {
        _productsCatalog = products;
        if (products.isNotEmpty) {
          _selectedProduct = products.first;
        }
        _isLoadingCatalog = false;
      });
    }
  }

  Future<void> _triggerScanSimulation(ProductModel product, {bool simulateError = false}) async {
    setState(() {
      _isProcessing = true;
      _isFailureState = false;
      _processingStep = 'Capturing packaging image...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _processingStep = 'Extracting Legal Metrology declarations (OCR)...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (simulateError) {
      setState(() {
        _isProcessing = false;
        _isFailureState = true;
      });
      return;
    }

    setState(() => _processingStep = 'Verifying font sizes, MRP, and net quantity rules...');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Record scan in Supabase
    final newScan = await ConsumerDataService.recordScan(product: product);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      if (newScan != null) {
        widget.onScanCompleted(newScan);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Scan Product Label',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (_isProcessing) ...[
                // Processing view
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _processingStep,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'AI is scanning ingredients, net weight, MRP, and FSSAI declarations',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_isFailureState) ...[
                // Scan Failure Empty State
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: AppColors.onErrorContainer, size: 28),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "We couldn't read this label clearly",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ensure adequate lighting and align the mandatory declaration panel within the camera frame.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isFailureState = false);
                              },
                              child: const Text('Try Again'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_selectedProduct != null) {
                                  _triggerScanSimulation(_selectedProduct!);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              child: const Text('Upload Another Image'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Select a food product package or upload a photograph to analyze compliance:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_isLoadingCatalog)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_productsCatalog.isEmpty)
                  const Center(child: Text('No sample products available in database.'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _productsCatalog.length,
                    itemBuilder: (context, index) {
                      final p = _productsCatalog[index];
                      final isSelected = _selectedProduct?.id == p.id;
                      final isWarning = p.complianceStatus != 'compliant';

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedDefault,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: p.imageUrl != null
                                ? Image.network(
                                    p.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.fastfood),
                                  )
                                : const Icon(Icons.fastfood),
                          ),
                          title: Text(
                            p.productName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${p.brand} • ${p.netQuantity ?? ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isWarning
                                  ? AppColors.errorContainer
                                  : AppColors.primaryFixed.withValues(alpha: 0.3),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text(
                              isWarning ? 'Issues' : 'Safe',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isWarning
                                    ? AppColors.onErrorContainer
                                    : AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          onTap: () => setState(() => _selectedProduct = p),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: AppSpacing.md),

                // Primary Scan CTA Button
                ElevatedButton.icon(
                  onPressed: _selectedProduct != null
                      ? () => _triggerScanSimulation(_selectedProduct!)
                      : null,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: Text(
                    'Scan & Analyze Selected Product',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedDefault,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
