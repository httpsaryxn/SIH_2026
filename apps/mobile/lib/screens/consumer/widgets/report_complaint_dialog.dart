import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_complaint_model.dart';
import '../../../core/services/consumer_data_service.dart';

class ReportComplaintDialog extends StatefulWidget {
  final String? prefilledProductName;
  final String? prefilledBrand;
  final Function(ConsumerComplaintModel complaint) onComplaintSubmitted;

  const ReportComplaintDialog({
    super.key,
    this.prefilledProductName,
    this.prefilledBrand,
    required this.onComplaintSubmitted,
  });

  @override
  State<ReportComplaintDialog> createState() => _ReportComplaintDialogState();
}

class _ReportComplaintDialogState extends State<ReportComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _brandController;
  final _descController = TextEditingController();

  String _selectedCategory = 'Missing Allergen Warning';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Missing Allergen Warning',
    'Incorrect Nutrition Fact',
    'Misleading Net Quantity Format',
    'Font Size Below 1.5mm Mandatory Rule',
    'Missing Manufacturer / Importer Address',
    'Non-compliant MRP / Expiry Date',
    'Dual Pricing / Overcharging',
    'Other Label Metrology Issue',
  ];

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.prefilledProductName ?? '');
    _brandController = TextEditingController(text: widget.prefilledBrand ?? '');
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final newComplaint = await ConsumerDataService.submitComplaint(
      productName: _productNameController.text.trim(),
      brand: _brandController.text.isNotEmpty ? _brandController.text.trim() : null,
      issueCategory: _selectedCategory,
      description: _descController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (newComplaint != null) {
        Navigator.of(context).pop();
        widget.onComplaintSubmitted(newComplaint);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit complaint. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.report_problem_rounded,
                            color: AppColors.onErrorContainer,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Report Product Label',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Submit an official compliance complaint to the Legal Metrology regulatory team.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Issue Category Dropdown
                  Text(
                    'Violation Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Product Name Field
                  Text(
                    'Product Name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _productNameController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Choco Crisp Cereal 300g',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Brand Name Field
                  Text(
                    'Brand / Manufacturer (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _brandController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. MegaFoods International',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    'Description of Issue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Explain the misleading information, missing declarations, or incorrect values observed on the packaging.',
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Please provide at least 10 characters'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedDefault,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Submit Complaint',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
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
    );
  }
}
