import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
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
    this.labelModel,
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
  final SmallBusinessLabelModel? labelModel;
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
    final model = widget.labelModel;
    final ingredientsText = (model != null && model.ingredients.isNotEmpty)
        ? model.ingredients.map((i) => '${i.name} (${i.percentage ?? 0}%)').join(', ')
        : 'Raw Mango Pieces (60%), Mustard Oil (20%), Salt (10%), Spices (10%)';
    final allergensText = (model != null && model.allergens.isNotEmpty)
        ? model.allergens.join(', ')
        : 'Mustard';
    final manufacturerName = (model != null && model.manufacturerName.isNotEmpty)
        ? model.manufacturerName
        : widget.brandName;
    final facilityAddress = (model != null && model.manufacturerAddress.isNotEmpty)
        ? model.manufacturerAddress
        : 'Plot 12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028';
    final fssaiNumber = (model != null && model.fssaiLicenseNumber.isNotEmpty)
        ? model.fssaiLicenseNumber
        : '12345678901234';
    final phone = (model != null && model.consumerCarePhone.isNotEmpty)
        ? model.consumerCarePhone
        : '+91 98765 43210';
    final email = (model != null && model.consumerCareEmail.isNotEmpty)
        ? model.consumerCareEmail
        : 'care@desiharvest.in';

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
              if (model != null && model.usp.isNotEmpty)
                _InfoRow('Unit Sale Price (USP)', model.usp),
              if (model != null && model.batchNumber.isNotEmpty)
                _InfoRow('Batch / Lot No.', model.batchNumber),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 2: Ingredients & Allergens
        _AccordionCard(
          title: 'Ingredients & Allergens',
          subtitle: '${model?.ingredients.length ?? 5} declared ingredients • ${model?.allergens.length ?? 1} allergen alert',
          icon: Icons.eco_rounded,
          isExpanded: _expandedIndex == 1,
          onToggle: () => _toggle(1),
          onEdit: widget.onEditIngredients,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Major Ingredients', ingredientsText),
              _InfoRow('Preservative Class', 'Natural (Spices & Edible Oil)'),
              _InfoRow('Declared Allergens', '$allergensText (Bold on label)'),
              _InfoRow('Cross-Contamination Alert', 'Sesame Seeds, Tree Nuts'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 3: Nutritional Values
        _AccordionCard(
          title: 'Nutritional Values Table',
          subtitle: 'Per 100g & per ${model?.servingSize ?? 30}${model?.servingSizeUnit ?? 'g'} serving • Table format',
          icon: Icons.analytics_rounded,
          isExpanded: _expandedIndex == 2,
          onToggle: () => _toggle(2),
          onEdit: widget.onEditNutrition,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Serving Size', '${model?.servingSize ?? 30} ${model?.servingSizeUnit ?? 'g'}'),
              _InfoRow('Energy per serving', '180 kcal (9.0% RDA)'),
              _InfoRow('Total Fat', '12 g (Trans Fat: 0g)'),
              _InfoRow('Added Sugars', '0 g (Zero Added Sugar)'),
              _InfoRow('Sodium', '980 mg per serving'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 4: Manufacturer & Business Details
        _AccordionCard(
          title: 'Manufacturer & Business Information',
          subtitle: 'Lic: $fssaiNumber • $manufacturerName',
          icon: Icons.storefront_rounded,
          isExpanded: _expandedIndex == 3,
          onToggle: () => _toggle(3),
          onEdit: widget.onEditManufacturer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Business Name', manufacturerName),
              _InfoRow('Facility Address', facilityAddress),
              _InfoRow('FSSAI License', fssaiNumber),
              _InfoRow('Consumer Care Phone', phone),
              _InfoRow('Consumer Care Email', email),
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
                      color: isExpanded
                          ? AppColors.brandDeepGreen.withValues(alpha: 0.1)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isExpanded
                          ? AppColors.brandDeepGreen
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
            const Divider(height: 1, color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,
                  if (onEdit != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text(
                          'Edit Section',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandDeepGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
