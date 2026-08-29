import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'claim_item_card.dart';

class AddCustomClaimCard extends StatefulWidget {
  const AddCustomClaimCard({
    super.key,
    required this.onAddCustomClaim,
  });

  final ValueChanged<ProductClaim> onAddCustomClaim;

  @override
  State<AddCustomClaimCard> createState() => _AddCustomClaimCardState();
}

class _AddCustomClaimCardState extends State<AddCustomClaimCard> {
  final TextEditingController _claimTextController = TextEditingController();
  final TextEditingController _subtextController = TextEditingController();
  ClaimCategory _selectedCategory = ClaimCategory.common;
  bool _isExpanded = false;

  @override
  void dispose() {
    _claimTextController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final title = _claimTextController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a claim statement'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final subtext = _subtextController.text.trim().isNotEmpty
        ? _subtextController.text.trim()
        : 'Custom business claim';

    final customClaim = ProductClaim(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: subtext,
      category: _selectedCategory,
      requiresLabReport: false,
    );

    widget.onAddCustomClaim(customClaim);
    _claimTextController.clear();
    _subtextController.clear();
    setState(() {
      _isExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom claim "$title" added and selected'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Toggle
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.brandDeepGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Add Custom Claim',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Declare unique artisan, heritage or process statements',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Form
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLAIM STATEMENT *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _claimTextController,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Cold Wood Pressed in Traditional Kolhapur Ghani',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.outline,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.brandDeepGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'SUPPORTING SUBTEXT / PROCESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _subtextController,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Extracted at low temperatures without chemical solvents',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.outline,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.brandDeepGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Selector
                  Row(
                    children: [
                      const Text(
                        'Category:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ClaimCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.onSurfaceVariant,
                              ),
                              items: ClaimCategory.values.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat.label,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _handleAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Add to Label Claims',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDeepGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
