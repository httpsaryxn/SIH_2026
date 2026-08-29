import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StudioHeader extends StatelessWidget {
  const StudioHeader({super.key, this.onNotificationTap, this.onProfileTap});

  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMALL BUSINESS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'My Label Studio',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create, review and manage your product labels.',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification button with badge
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onNotificationTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 26,
                        ),
                        Positioned(
                          top: 1,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // User Avatar
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHighest,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB5_uJUfx-UVWIzpnIDUaTnnWcls6dxLz2wsOvvS7k1P_gcI_Ac4MbMNR_43s5_k3Z1OCFVi33ohdYRH387IQs6iQkklA6JGem7MhHi8BkBaAjSx3wh1h9WtLohjBOp-Fpl9sXoCGLYBLikbUYAaq24OUzAj6s1yPJjU3fY-F4I1BMdDRXMFtBMDXDvYgGpUm3OEB_qWqIU1lWGlEevMJ5UjqKFGGIYCB1dWi3oC6ln8K9_Q9uP5BIwkA',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
