import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/user_role.dart';

class RoleCard extends StatefulWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onSelect;

  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    // Card background
    final Color backgroundColor = isSelected
        ? Color.alphaBlend(
            AppColors.primary.withValues(alpha: 0.04),
            AppColors.surfaceContainerLowest,
          )
        : (_isHovered
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.02),
                AppColors.surfaceContainerLowest,
              )
            : AppColors.surfaceContainerLowest);

    // Border
    final Border border = Border.all(
      color: isSelected
          ? AppColors.primary
          : (_isHovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.surfaceVariant),
      width: isSelected ? 2.0 : 1.0,
    );

    // Shadow
    final List<BoxShadow> boxShadow = isSelected || _isHovered
        ? AppSpacing.cardHoverShadow
        : AppSpacing.cardShadow;

    // Icon Container Colors
    final Color iconBgColor = isSelected || _isHovered
        ? AppColors.primaryContainer
        : AppColors.secondaryContainer;

    final Color iconColor = isSelected || _isHovered
        ? AppColors.onPrimaryContainer
        : AppColors.onSecondaryContainer;

    // Title Color
    final Color titleColor = isSelected || _isHovered
        ? AppColors.primary
        : AppColors.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppSpacing.roundedMd,
            border: border,
            boxShadow: boxShadow,
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.roundedMd,
            child: Stack(
              children: [
                // Highlight Overlay on Hover / Active
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : (_isHovered ? 0.6 : 0.0),
                    child: Container(
                      color: AppColors.primary.withValues(alpha: 0.03),
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            widget.role.icon,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Text Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                  height: 28 / 20,
                                ),
                                child: Text(widget.role.title),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.role.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark Selection Indicator
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
