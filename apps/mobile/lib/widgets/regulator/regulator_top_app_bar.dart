import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// RegulatorTopAppBar provides a FIXED, non-scrolling, rock-solid top app bar
/// used across all Regulator screens. It never distorts, collapses, or stretches
/// on scroll / overscroll pull-down.
class RegulatorTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? customTitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showNotifications;
  final VoidCallback? onNotificationTap;
  final List<Widget>? actions;

  const RegulatorTopAppBar({
    super.key,
    this.customTitle,
    this.showBackButton = false,
    this.onBack,
    this.showNotifications = true,
    this.onNotificationTap,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: showBackButton,
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          height: 1.0,
        ),
      ),
      leadingWidth: showBackButton ? 56 : 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.gutter),
        child: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.outlineVariant, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      titleSpacing: showBackButton ? 0 : AppSpacing.sm,
      title: Text(
        customTitle ?? 'EnforceMetrology',
        style: customTitle != null
            ? AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                fontSize: 18,
              )
            : AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 20,
              ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (actions != null)
          ...actions!
        else if (showNotifications)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.gutter),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              color: AppColors.onSurfaceVariant,
              onPressed: onNotificationTap ?? () {},
            ),
          ),
      ],
    );
  }
}
