import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/regulator_complaint.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/regulator/regulator_status_badge.dart';
import '../onboarding/role_selection_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  bool _isLoading = true;
  List<RegulatorComplaint> _myComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final complaints = await RegulatorDataService.getComplaints();
      if (mounted) {
        setState(() {
          _myComplaints = complaints;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReportDialog() {
    final formKey = GlobalKey<FormState>();
    final productCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final issueCtrl = TextEditingController(text: 'Potential MRP Discrepancy');
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String selectedCategory = 'Potential MRP Discrepancy';
    bool isSubmitting = false;

    final categories = [
      'Potential MRP Discrepancy',
      'Missing Allergen Warning',
      'Unclear Net Weight / Quantity',
      'Missing Manufacturer Address',
      'Misleading Packaging / Claims',
      'Other Non-Compliance',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Report Packaging Issue',
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Submit potential packaging and Legal Metrology rule violations to regulatory authorities.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Product Name
                  Text(
                    'Product Name *',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: productCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Choco Crisp Cereal 300g',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Brand / Company
                  Text(
                    'Brand / Manufacturer *',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. MegaFoods International',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter brand name' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Category Dropdown
                  Text(
                    'Issue Category *',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTypography.bodySm)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCategory = val;
                          issueCtrl.text = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Store Location
                  Text(
                    'Store / Market Location *',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. FreshMart Supermarket, Sector 14',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Description
                  Text(
                    'Issue Description *',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe what declaration is missing, incorrect, or misleading...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit Button
                  CustomButton(
                    text: 'Submit to Authorities',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setModalState(() => isSubmitting = true);
                      try {
                        await RegulatorDataService.submitConsumerComplaint(
                          productName: productCtrl.text,
                          brand: brandCtrl.text,
                          issueCategory: selectedCategory,
                          description: descCtrl.text,
                          storeLocation: locationCtrl.text,
                        );
                        nav.pop();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Complaint submitted successfully to Regulatory Authority!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        _loadData();
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Submission failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'FreshLabel Pro',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.outline),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Quick Scan Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF004B1E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppSpacing.primaryButtonShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan & Verify Packaging',
                                style: AppTypography.headlineSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Scan barcodes or OCR product declarations',
                                style: AppTypography.bodySm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Scan Product', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('On-device Barcode scanner & OCR ready for camera input.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.report_problem_outlined, size: 18),
                            label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: _showReportDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Consumer Complaints Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consumer Complaints Feed',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showReportDialog,
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'New Report',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Complaints List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_myComplaints.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 40, color: AppColors.outline),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No complaints submitted yet.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myComplaints.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final complaint = _myComplaints[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        border: Border.all(color: AppColors.surfaceVariant),
                        boxShadow: AppSpacing.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  complaint.complaintCode,
                                  style: AppTypography.labelSm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              RegulatorStatusBadge.fromStatus(complaint.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            complaint.productName.isNotEmpty ? complaint.productName : complaint.title,
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (complaint.companyName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Brand: ${complaint.companyName} • ${complaint.category}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.tertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '"${complaint.description}"',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.outline),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  complaint.locationName.isNotEmpty ? complaint.locationName : complaint.address,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.outline,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
