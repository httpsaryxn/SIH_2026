import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../data/services/notification_service.dart';

/// Full-page Notifications & Activity screen for Small Business owners.
/// Connects dynamically to [SmallBusinessNotificationService].
class SmallBusinessNotificationsScreen extends StatefulWidget {
  const SmallBusinessNotificationsScreen({super.key});

  @override
  State<SmallBusinessNotificationsScreen> createState() =>
      _SmallBusinessNotificationsScreenState();
}

class _SmallBusinessNotificationsScreenState
    extends State<SmallBusinessNotificationsScreen> {
  final SmallBusinessNotificationService _service =
      SmallBusinessNotificationService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Automatically mark all as read when user visits the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.markAllAsRead();
    });
  }

  void _clearAllNotifications() {
    if (_service.notifications.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Clear Notifications?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all logged notifications and activity alerts?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _service.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            AnimatedBuilder(
              animation: _service,
              builder: (context, _) {
                return Text(
                  '${_service.notifications.length} logged events & compliance updates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _service,
            builder: (context, _) {
              if (_service.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: _clearAllNotifications,
                  icon: const Icon(
                    Icons.clear_all_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'Clear',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            height: 1.0,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          var filteredList = _service.notifications;
          if (_selectedFilter == 'Alerts') {
            filteredList = filteredList
                .where((n) => n.type == NotificationType.warning)
                .toList();
          } else if (_selectedFilter == 'Success') {
            filteredList = filteredList
                .where((n) => n.type == NotificationType.success)
                .toList();
          } else if (_selectedFilter == 'Legal') {
            filteredList = filteredList
                .where((n) => n.type == NotificationType.compliance)
                .toList();
          }

          final alertsCount = _service.notifications
              .where((n) => n.type == NotificationType.warning)
              .length;
          final successCount = _service.notifications
              .where((n) => n.type == NotificationType.success)
              .length;
          final legalCount = _service.notifications
              .where((n) => n.type == NotificationType.compliance)
              .length;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', _service.notifications.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Alerts', alertsCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Success', successCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Legal', legalCount),
                    ],
                  ),
                ),
              ),

              // Notification items list or Empty State
              if (filteredList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 30,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Notifications',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFilter == 'All'
                                ? 'You have no logged events or compliance alerts right now.'
                                : 'No notifications match the "$_selectedFilter" category.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: SlideFadeEntrance(
                            index: index.clamp(0, 5),
                            child: _buildNotificationCard(item),
                          ),
                        );
                      },
                      childCount: filteredList.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.surfaceVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? AppColors.outlineVariant.withValues(alpha: 0.4)
              : item.color.withValues(alpha: 0.45),
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      item.timeFormatted,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
