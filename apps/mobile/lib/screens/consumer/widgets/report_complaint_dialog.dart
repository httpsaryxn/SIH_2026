import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_complaint_model.dart';
import '../../../core/models/pending_capture.dart';
import '../../../core/services/camera_capture_service.dart';
import '../../../core/services/consumer_data_service.dart';

class ReportComplaintDialog extends StatefulWidget {
  final String? prefilledProductName;
  final String? prefilledBrand;
  final PendingCapture? prefilledCapture;
  final Function(ConsumerComplaintModel complaint) onComplaintSubmitted;

  const ReportComplaintDialog({
    super.key,
    this.prefilledProductName,
    this.prefilledBrand,
    this.prefilledCapture,
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
  final _storeLocationController = TextEditingController();

  String _selectedCategory = 'Incorrect/Missing MRP';
  bool _isSubmitting = false;
  PendingCapture? _attachedCapture;

  final List<String> _categories = [
    'Incorrect/Missing MRP',
    'Incorrect/Missing Net Quantity',
    'Missing Manufacturer Information',
    'Missing Date Information',
    'Missing Consumer Care Details',
    'Potentially Misleading Declaration',
    'Font Size Below 1.5mm Mandatory Rule',
    'Dual Pricing / Overcharging',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _productNameController =
        TextEditingController(text: widget.prefilledProductName ?? '');
    _brandController = TextEditingController(text: widget.prefilledBrand ?? '');
    _attachedCapture = widget.prefilledCapture;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _descController.dispose();
    _storeLocationController.dispose();
    super.dispose();
  }

  Future<void> _handleCaptureEvidence() async {
    final capture = await CameraCaptureService.captureImage(
      context: context,
      sourceTag: 'consumer_complaint',
      imageSource: ImageSource.camera,
    );

    if (capture != null && mounted) {
      setState(() {
        _attachedCapture = capture;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final newComplaint = await ConsumerDataService.submitComplaint(
      productName: _productNameController.text.trim(),
      brand: _brandController.text.isNotEmpty ? _brandController.text.trim() : null,
      issueCategory: _selectedCategory,
      description: _descController.text.trim(),
      storeLocation: _storeLocationController.text.isNotEmpty
          ? _storeLocationController.text.trim()
          : null,
      pendingCapture: _attachedCapture,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (newComplaint != null) {
        Navigator.of(context).pop();
        widget.onComplaintSubmitted(newComplaint);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit complaint. Please check connection.'),
          ),
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
        constraints: const BoxConstraints(maxWidth: 540),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.report_problem_rounded,
                            color: AppColors.onErrorContainer,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report a Label Issue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Help Legal Metrology authorities investigate anomalies.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Issue Category Dropdown
                  Text(
                    'Issue Category',
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
                      hintText: 'e.g. ABC Snacks / Choco Crisp 300g',
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
                      hintText: 'e.g. XYZ Foods Pvt Ltd',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Optional Store / Location
                  Text(
                    'Store / Location where purchased (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _storeLocationController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. FreshMart Supermarket, Sector 14, Pune',
                      prefixIcon: Icon(Icons.storefront_rounded, size: 18),
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
                      hintText:
                          'Describe the issue observed (e.g. missing manufacturing date, obscured price sticker, dual MRP, or illegible font size).',
                    ),
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Please provide at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Label Photo / Evidence attachment
                  Text(
                    'Label Photo / Evidence',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: _handleCaptureEvidence,
                    borderRadius: AppSpacing.roundedDefault,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _attachedCapture != null
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.roundedDefault,
                        border: Border.all(
                          color: _attachedCapture != null ? AppColors.primary : AppColors.surfaceVariant,
                          style: _attachedCapture != null ? BorderStyle.solid : BorderStyle.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _attachedCapture != null ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                            color: _attachedCapture != null ? AppColors.primary : AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _attachedCapture != null
                                  ? 'Label evidence attached (${_attachedCapture!.formattedSize} • ${_attachedCapture!.fileName})'
                                  : 'Tap to capture product label photo with camera',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: _attachedCapture != null ? FontWeight.w600 : FontWeight.w400,
                                color: _attachedCapture != null ? AppColors.primary : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedDefault,
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
