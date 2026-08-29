import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductBasicDetailsForm extends StatelessWidget {
  const ProductBasicDetailsForm({
    super.key,
    required this.brandNameController,
    required this.productNameController,
    required this.typeFlavourController,
    this.uploadedLogoName,
    this.onUploadLogoTap,
  });

  final TextEditingController brandNameController;
  final TextEditingController productNameController;
  final TextEditingController typeFlavourController;
  final String? uploadedLogoName;
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
            color: Colors.black.withValues(alpha: 0.03),
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
              color: AppColors.brandDeepGreen.withValues(alpha: 0.05),
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
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.brandDeepGreen,
                ),
                SizedBox(width: 6),
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
                _buildFieldLabel('Brand Name'),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: brandNameController,
                  placeholder: 'e.g. My Label Studio',
                ),
                const SizedBox(height: 16),

                // Brand Logo Upload Box
                _buildFieldLabel('Brand Logo'),
                const SizedBox(height: 6),
                _buildLogoUploadBox(),
                const SizedBox(height: 16),

                // Product Name Field
                _buildFieldLabel('Product Name'),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: productNameController,
                  placeholder: 'e.g. Mango Pickle',
                ),
                const SizedBox(height: 16),

                // Type / Flavour / Class Field
                _buildFieldLabel('Type / Flavour / Class'),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: typeFlavourController,
                  placeholder: 'e.g. Spicy, Organic',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: AppColors.outline.withValues(alpha: 0.8),
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
    return Material(
      color: AppColors.surfaceBright,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onUploadLogoTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.outlineVariant,
              width: 1.2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            children: [
              // Circle icon background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.brandDeepGreen,
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
                      uploadedLogoName ?? 'Upload logo image',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      uploadedLogoName != null
                          ? 'Logo selected • Tap to change'
                          : 'PNG, JPG up to 5MB',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
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
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                ),
                child: Text(
                  uploadedLogoName != null ? 'Replace' : 'Upload',
                  style: const TextStyle(
                    color: AppColors.onSurface,
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
