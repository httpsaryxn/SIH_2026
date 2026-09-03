import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'product_image_widget.dart';

class ProductBasicDetailsForm extends StatelessWidget {
  const ProductBasicDetailsForm({
    super.key,
    required this.brandNameController,
    required this.productNameController,
    required this.typeFlavourController,
    this.uploadedLogoName,
    this.uploadedLogoDataUrl,
    this.onUploadLogoTap,
  });

  final TextEditingController brandNameController;
  final TextEditingController productNameController;
  final TextEditingController typeFlavourController;
  final String? uploadedLogoName;
  final String? uploadedLogoDataUrl;
  final VoidCallback? onUploadLogoTap;

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
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandDeepGreen.withValues(alpha: 0.04),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: AppColors.brandDeepGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Basic Details',
                  style: TextStyle(
                    color: AppColors.brandDeepGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Form Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Name Field
                _buildFieldLabel('Brand Name', isRequired: true),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: brandNameController,
                  placeholder: 'e.g. Desi Harvest',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 16),

                // Brand Logo Upload Box
                _buildFieldLabel('Brand Logo'),
                const SizedBox(height: 6),
                _buildLogoUploadBox(),
                const SizedBox(height: 16),

                // Product Name Field
                _buildFieldLabel('Product Name', isRequired: true),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: productNameController,
                  placeholder: 'e.g. Turmeric Powder',
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: 16),

                // Type / Flavour / Class Field
                _buildFieldLabel('Type / Flavour / Class'),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: typeFlavourController,
                  placeholder: 'e.g. Heritage Special / Organic',
                  icon: Icons.tune_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          hintText: placeholder,
          hintStyle: TextStyle(
            color: AppColors.outline.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoUploadBox() {
    final hasLogo = uploadedLogoName != null && uploadedLogoName!.isNotEmpty;

    return Material(
      color: hasLogo
          ? AppColors.brandDeepGreen.withValues(alpha: 0.04)
          : AppColors.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onUploadLogoTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLogo
                  ? AppColors.brandDeepGreen.withValues(alpha: 0.3)
                  : AppColors.outlineVariant,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Logo image thumbnail or circle icon background
              if (uploadedLogoDataUrl != null && uploadedLogoDataUrl!.isNotEmpty)
                ProductImageWidget(
                  imageUrl: uploadedLogoDataUrl,
                  width: 42,
                  height: 42,
                  borderRadius: 8,
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasLogo
                        ? AppColors.brandDeepGreen
                        : AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    hasLogo ? Icons.check_rounded : Icons.image_outlined,
                    color: hasLogo ? Colors.white : AppColors.brandDeepGreen,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              // Text description or selected file
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLogo ? uploadedLogoName! : 'Upload Brand Logo',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasLogo
                          ? 'Logo attached • Tap to change'
                          : 'PNG, JPG up to 5MB',
                      style: TextStyle(
                        color: hasLogo
                            ? AppColors.brandDeepGreen
                            : AppColors.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight:
                            hasLogo ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Upload button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasLogo
                      ? AppColors.brandDeepGreen
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasLogo
                        ? AppColors.brandDeepGreen
                        : AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Text(
                  hasLogo ? 'Replace' : 'Upload',
                  style: TextStyle(
                    color: hasLogo ? Colors.white : AppColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
