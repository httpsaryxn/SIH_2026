import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'claim_item_card.dart';

class ReviewAccordionSection extends StatefulWidget {
  const ReviewAccordionSection({
    super.key,
    required this.brandName,
    required this.productName,
    required this.productCategory,
    required this.netQuantity,
    required this.mrp,
    required this.selectedClaims,
    this.onEditDeclaration,
    this.onEditIngredients,
    this.onEditNutrition,
    this.onEditManufacturer,
    this.onEditClaims,
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;
  final List<ProductClaim> selectedClaims;
  final VoidCallback? onEditDeclaration;
  final VoidCallback? onEditIngredients;
  final VoidCallback? onEditNutrition;
  final VoidCallback? onEditManufacturer;
  final VoidCallback? onEditClaims;

  @override
  State<ReviewAccordionSection> createState() => _ReviewAccordionSectionState();
}

class _ReviewAccordionSectionState extends State<ReviewAccordionSection> {
  int? _expandedIndex;

  void _toggle(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Declaration Breakdown',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // Section 1: Product Information
        _AccordionCard(
          title: 'Product Information',
          subtitle: '${widget.brandName} • ${widget.productName}',
          icon: Icons.inventory_2_rounded,
          isExpanded: _expandedIndex == 0,
          onToggle: () => _toggle(0),
          onEdit: widget.onEditDeclaration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Brand Name', widget.brandName),
              _InfoRow('Product Name', widget.productName),
              _InfoRow('Category', widget.productCategory),
              _InfoRow('Net Quantity', widget.netQuantity),
              _InfoRow('MRP (Max Retail Price)', widget.mrp),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 2: Ingredients & Allergens
        _AccordionCard(
          title: 'Ingredients & Allergens',
          subtitle: '8 declared ingredients • 1 allergen alert',
          icon: Icons.eco_rounded,
          isExpanded: _expandedIndex == 1,
          onToggle: () => _toggle(1),
          onEdit: widget.onEditIngredients,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _InfoRow('Major Ingredients', 'Raw Mango (65%), Mustard Oil, Spices, Salt'),
              _InfoRow('Preservative Class', 'Natural (Spices & Edible Oil)'),
              _InfoRow('Declared Allergens', 'Mustard (Bold on label)'),
              _InfoRow('Cross-Contamination Alert', 'Sesame, Tree Nuts'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 3: Nutritional Values
        _AccordionCard(
          title: 'Nutritional Values Table',
          subtitle: 'Per 100g & per 30g serving • Table format',
          icon: Icons.analytics_rounded,
          isExpanded: _expandedIndex == 2,
          onToggle: () => _toggle(2),
          onEdit: widget.onEditNutrition,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _InfoRow('Serving Size', '30 g'),
              _InfoRow('Energy per serving', '75 kcal (3.7% RDA)'),
              _InfoRow('Total Fat', '5.4 g (Trans Fat: 0g)'),
              _InfoRow('Added Sugars', '0 g (Zero Added Sugar)'),
              _InfoRow('Sodium', '267 mg per serving'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 4: Manufacturer & Business Details
        _AccordionCard(
          title: 'Manufacturer & Business Information',
          subtitle: 'Lic: 12345678901234 • Pune facility',
          icon: Icons.storefront_rounded,
          isExpanded: _expandedIndex == 3,
          onToggle: () => _toggle(3),
          onEdit: widget.onEditManufacturer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _InfoRow('Business Name', 'Desi Harvest Foods Pvt. Ltd.'),
              _InfoRow('Facility Address', 'Plot 12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028'),
              _InfoRow('FSSAI License', '12345678901234'),
              _InfoRow('Consumer Care Phone', '+91 98765 43210'),
              _InfoRow('Consumer Care Email', 'care@desiharvest.in'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 5: Product Claims
        _AccordionCard(
          title: 'Product Claims',
          subtitle: '${widget.selectedClaims.length} verified claims attached',
          icon: Icons.verified_rounded,
          isExpanded: _expandedIndex == 4,
          onToggle: () => _toggle(4),
          onEdit: widget.onEditClaims,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedClaims.isEmpty)
                const Text(
                  'No claims selected',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                )
              else
                ...widget.selectedClaims.map((claim) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.brandDeepGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                claim.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.brandDeepGreen.withValues(alpha: 0.5)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
          width: isExpanded ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.brandDeepGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandDeepGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
