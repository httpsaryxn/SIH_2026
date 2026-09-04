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
  @override
  Widget build(BuildContext context) {
    final model = widget.labelModel;
    final ingredientsList = model?.ingredients ?? [];
    final ingredientsText = ingredientsList.isNotEmpty
        ? ingredientsList.map((i) {
            if (i.percentage != null && i.percentage! > 0) {
              return '${i.name} (${i.percentage}%)';
            }
            return i.name;
          }).join(', ')
        : 'No ingredients entered';

    final allergensList = model?.allergens ?? [];
    final allergensText = allergensList.isNotEmpty
        ? allergensList.join(', ')
        : 'No major allergens declared';

    final manufacturerName = (model != null && model.manufacturerName.isNotEmpty)
        ? model.manufacturerName
        : widget.brandName;
    final facilityAddress = (model != null && model.manufacturerAddress.isNotEmpty)
        ? model.manufacturerAddress
        : 'Not provided';
    final fssaiNumber = (model != null && model.fssaiLicenseNumber.isNotEmpty)
        ? model.fssaiLicenseNumber
        : 'Pending';
    final phone = (model != null && model.consumerCarePhone.isNotEmpty)
        ? model.consumerCarePhone
        : 'Not provided';
    final email = (model != null && model.consumerCareEmail.isNotEmpty)
        ? model.consumerCareEmail
        : 'Not provided';

    // Collect claims from model or widget.selectedClaims
    final claims = <Map<String, String>>[];
    if (model != null && model.claims.isNotEmpty) {
      for (final c in model.claims) {
        claims.add({'title': c.title, 'description': c.description});
      }
    } else if (widget.selectedClaims.isNotEmpty) {
      for (final c in widget.selectedClaims) {
        claims.add({'title': c.title, 'description': c.description});
      }
    }

    final nutrientsList = model?.nutrients ?? [];

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
              if (model != null && model.mfgDate.isNotEmpty)
                _InfoRow('Mfg Date', model.mfgDate),
              if (model != null && model.bestBefore.isNotEmpty)
                _InfoRow('Best Before', model.bestBefore),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 2: Ingredients & Allergens
        _AccordionCard(
          title: 'Ingredients & Allergens',
          subtitle: '${ingredientsList.length} declared ingredients • ${allergensList.length} allergen alert(s)',
          icon: Icons.eco_rounded,
          isExpanded: _expandedIndex == 1,
          onToggle: () => _toggle(1),
          onEdit: widget.onEditIngredients,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Major Ingredients', ingredientsText),
              _InfoRow('Declared Allergens', allergensText),
              if (model != null && model.storageInstructions.isNotEmpty)
                _InfoRow('Storage Instructions', model.storageInstructions),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 3: Nutritional Values
        _AccordionCard(
          title: 'Nutritional Values Table',
          subtitle: 'Per 100g & per ${model?.servingSize ?? "30"}${model?.servingSizeUnit ?? "g"} serving (${nutrientsList.length} parameters)',
          icon: Icons.analytics_rounded,
          isExpanded: _expandedIndex == 2,
          onToggle: () => _toggle(2),
          onEdit: widget.onEditNutrition,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Serving Size', '${model?.servingSize ?? "30"} ${model?.servingSizeUnit ?? "g"}'),
              if (nutrientsList.isEmpty)
                const _InfoRow('Nutrients', 'Standard mandatory baseline')
              else
                ...nutrientsList.map((n) {
                  final indent = n.isSubNutrient ? '  - ' : '';
                  return _InfoRow('$indent${n.label}', '${n.value} ${n.unit}');
                }),
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
          subtitle: '${claims.length} verified claim(s) attached',
          icon: Icons.verified_rounded,
          isExpanded: _expandedIndex == 4,
          onToggle: () => _toggle(4),
          onEdit: widget.onEditClaims,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (claims.isEmpty)
                const Text(
                  'No claims selected for front-of-pack display.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                )
              else
                ...claims.map((claim) {
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
                                claim['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if ((claim['description'] ?? '').isNotEmpty)
                                Text(
                                  claim['description'] ?? '',
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
