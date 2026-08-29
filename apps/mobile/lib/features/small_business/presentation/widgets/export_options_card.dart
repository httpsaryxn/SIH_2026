import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ExportFormat {
  pdf('Print PDF', '300 DPI Vector with Bleed & Crop Marks', Icons.picture_as_pdf_rounded),
  png('High-Res PNG', 'Clean raster image with white or transparent bg', Icons.image_rounded),
  svg('Vector SVG', 'Scalable vector for commercial packaging printers', Icons.polyline_rounded),
  json('Compliance JSON', 'Machine-readable regulatory metadata schema', Icons.code_rounded);

  const ExportFormat(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

class ExportOptionsCard extends StatefulWidget {
  const ExportOptionsCard({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.selectedDimension,
    required this.onDimensionChanged,
  });

  final ExportFormat selectedFormat;
  final ValueChanged<ExportFormat> onFormatChanged;
  final String selectedDimension;
  final ValueChanged<String> onDimensionChanged;

  @override
  State<ExportOptionsCard> createState() => _ExportOptionsCardState();
}

class _ExportOptionsCardState extends State<ExportOptionsCard> {
  final List<String> _dimensions = [
    'Standard Pouch (100 × 150 mm)',
    'Glass Jar Sticker (80 × 60 mm)',
    'Carton Box Wrap (120 × 180 mm)',
    'Custom Label Size',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.file_download_rounded,
                  color: AppColors.brandDeepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Export & Production Formats',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Choose output format for packaging printer',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Format selector grid/list
          ...ExportFormat.values.map((fmt) {
            final isSelected = widget.selectedFormat == fmt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onFormatChanged(fmt),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandDeepGreen.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandDeepGreen
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          fmt.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.brandDeepGreen
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fmt.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.brandDeepGreen
                                      : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                fmt.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.brandDeepGreen,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          // Print Dimensions Dropdown
          const Text(
            'LABEL PRINT DIMENSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedDimension,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                items: _dimensions.map((dim) {
                  return DropdownMenuItem(
                    value: dim,
                    child: Text(
                      dim,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    widget.onDimensionChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
