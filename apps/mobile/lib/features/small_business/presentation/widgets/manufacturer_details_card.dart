import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManufacturerDetailsCard extends StatefulWidget {
  const ManufacturerDetailsCard({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.packerAddressSameAsManufacturer,
    required this.onPackerSameChanged,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final bool packerAddressSameAsManufacturer;
  final ValueChanged<bool?> onPackerSameChanged;

  @override
  State<ManufacturerDetailsCard> createState() =>
      _ManufacturerDetailsCardState();
}

class _ManufacturerDetailsCardState extends State<ManufacturerDetailsCard> {
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChange);
    _addressFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _addressFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Building Icon
                  Row(
                    children: const [
                      Icon(
                        Icons.domain_rounded,
                        color: AppColors.brandDeepGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manufacturer Details',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Brand Name Input Field
                  const Text(
                    'Manufacturer / Brand Name *',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    decoration: BoxDecoration(
                      color: _nameFocus.hasFocus
                          ? Colors.white
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _nameFocus.hasFocus
                            ? AppColors.brandDeepGreen
                            : AppColors.outlineVariant,
                        width: _nameFocus.hasFocus ? 1.5 : 1,
                      ),
                      boxShadow: _nameFocus.hasFocus
                          ? [
                              BoxShadow(
                                color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: _nameFocus.hasFocus
                              ? AppColors.brandDeepGreen
                              : AppColors.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.nameController,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter business name',
                              hintStyle: TextStyle(
                                color: AppColors.outline,
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Complete Address Multi-line Input Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Complete Address *',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.addressController,
                        builder: (context, value, child) {
                          return Text(
                            '${value.text.length}/500',
                            style: const TextStyle(
                              color: AppColors.outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 88,
                    decoration: BoxDecoration(
                      color: _addressFocus.hasFocus
                          ? Colors.white
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _addressFocus.hasFocus
                            ? AppColors.brandDeepGreen
                            : AppColors.outlineVariant,
                        width: _addressFocus.hasFocus ? 1.5 : 1,
                      ),
                      boxShadow: _addressFocus.hasFocus
                          ? [
                              BoxShadow(
                                color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: _addressFocus.hasFocus
                                ? AppColors.brandDeepGreen
                                : AppColors.outline,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.addressController,
                            focusNode: _addressFocus,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter full registered address',
                              hintStyle: TextStyle(
                                color: AppColors.outline,
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Packer Address Checkbox Banner Row
        InkWell(
          onTap: () =>
              widget.onPackerSameChanged(!widget.packerAddressSameAsManufacturer),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: widget.packerAddressSameAsManufacturer
                  ? const Color(0xFFF0FDF4)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.packerAddressSameAsManufacturer
                    ? const Color(0xFF86EFAC)
                    : AppColors.outlineVariant,
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: widget.packerAddressSameAsManufacturer,
                  onChanged: widget.onPackerSameChanged,
                  activeColor: AppColors.brandDeepGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Packer address same as manufacturer',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
