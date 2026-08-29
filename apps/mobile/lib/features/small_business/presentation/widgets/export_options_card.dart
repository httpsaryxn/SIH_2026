import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ExportFormat {
  png('High-Res PNG', 'Clean 600 DPI raster image for e-commerce and mockups', Icons.image_rounded),
  pdf('Print Ready PDF', '300 DPI Vector with Bleed & Crop Marks for Offset / Digital Press', Icons.picture_as_pdf_rounded),
  svg('Vector SVG', 'Scalable master vector artwork for packaging flexo printers', Icons.polyline_rounded),
  json('Compliance JSON', 'Machine-readable Legal Metrology & FSSAI schema metadata', Icons.code_rounded);

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
    this.customWidthMm = 100,
    this.customHeightMm = 150,
    this.onCustomDimensionsChanged,
  });

  final ExportFormat selectedFormat;
  final ValueChanged<ExportFormat> onFormatChanged;
  final String selectedDimension;
  final ValueChanged<String> onDimensionChanged;
  final double customWidthMm;
  final double customHeightMm;
  final void Function(double width, double height)? onCustomDimensionsChanged;

  @override
  State<ExportOptionsCard> createState() => _ExportOptionsCardState();
}

class _ExportOptionsCardState extends State<ExportOptionsCard> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;

  static const List<String> dimensionsList = [
    'Standard Pouch (100 × 150 mm)',
    'Wide Pouch / Namkeen Bag (150 × 200 mm)',
    'Large Stand-Up Zipper Pouch (180 × 260 mm)',
    'Glass Jar / Bottle Wrap (70 × 180 mm)',
    'Hexagonal Honey Jar Label (60 × 120 mm)',
    'Cylindrical Tin Container (90 × 280 mm)',
    'Small Spice Jar / Dispenser (45 × 90 mm)',
    'Square Box / Mithai Box Front (120 × 120 mm)',
    'Large Carton / Bulk Pack (210 × 297 mm - A4)',
    'Round Container Lid Sticker (80 × 80 mm Circle)',
    'Custom Label Size (Specify Width × Height in mm)',
  ];

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(text: widget.customWidthMm.toInt().toString());
    _heightController = TextEditingController(text: widget.customHeightMm.toInt().toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onDimensionsInputChanged() {
    final w = double.tryParse(_widthController.text.trim()) ?? 100.0;
    final h = double.tryParse(_heightController.text.trim()) ?? 150.0;
    widget.onCustomDimensionsChanged?.call(w, h);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDimension = dimensionsList.contains(widget.selectedDimension)
        ? widget.selectedDimension
        : dimensionsList.first;

    final isCustom = effectiveDimension.startsWith('Custom');

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
                    'Choose output format & packaging print size',
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

          // Format selector list
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
          const SizedBox(height: 12),

          // Print Dimensions Dropdown Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'LABEL PRINT DIMENSIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '10+ Presets',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDeepGreen,
                ),
              ),
            ],
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
                value: effectiveDimension,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                items: dimensionsList.map((dim) {
                  return DropdownMenuItem(
                    value: dim,
                    child: Text(
                      dim,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    widget.onDimensionChanged(val);
                    if (!val.startsWith('Custom')) {
                      // Extract width and height numbers from string e.g. (100 × 150 mm)
                      final match = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(val);
                      if (match != null) {
                        final w = double.tryParse(match.group(1)!) ?? 100.0;
                        final h = double.tryParse(match.group(2)!) ?? 150.0;
                        _widthController.text = w.toInt().toString();
                        _heightController.text = h.toInt().toString();
                        widget.onCustomDimensionsChanged?.call(w, h);
                      }
                    }
                  }
                },
              ),
            ),
          ),

          // Custom Width × Height Input Fields
          if (isCustom) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Packaging Specifications',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Width (mm)', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              child: TextField(
                                controller: _widthController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _onDimensionsInputChanged(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: InputBorder.none,
                                  suffixText: 'mm',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('×', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Height (mm)', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              child: TextField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _onDimensionsInputChanged(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: InputBorder.none,
                                  suffixText: 'mm',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
