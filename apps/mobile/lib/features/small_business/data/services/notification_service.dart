import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NotificationType { success, warning, info, compliance }

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = NotificationType.info,
    this.isRead = false,
  });

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.compliance:
        return Icons.verified_user_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.success:
        return AppColors.brandDeepGreen;
      case NotificationType.warning:
        return const Color(0xFFD97706);
      case NotificationType.compliance:
        return const Color(0xFF0284C7);
      case NotificationType.info:
        return AppColors.brandDeepGreen;
    }
  }
}

class SmallBusinessNotificationService extends ChangeNotifier {
  static final SmallBusinessNotificationService _instance =
      SmallBusinessNotificationService._internal();

  factory SmallBusinessNotificationService() => _instance;

  SmallBusinessNotificationService._internal() {
    // Seed initial welcome notifications
    _notifications.addAll([
      AppNotificationItem(
        id: '1',
        title: 'Label Studio Ready',
        message: 'Connected to Supabase cloud and Legal Metrology rules.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: NotificationType.compliance,
      ),
      AppNotificationItem(
        id: '2',
        title: 'FSSAI Regulatory Sync',
        message: 'Loaded standard allergen and nutritional declaration schemas.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.info,
      ),
    ]);
  }

  final List<AppNotificationItem> _notifications = [];

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void notify({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) {
    final item = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, item);
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  static void showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationCenterModal(),
    );
  }
}

class NotificationCenterModal extends StatefulWidget {
  const NotificationCenterModal({super.key});

  @override
  State<NotificationCenterModal> createState() =>
      _NotificationCenterModalState();
}

class _NotificationCenterModalState extends State<NotificationCenterModal> {
  final SmallBusinessNotificationService _service =
      SmallBusinessNotificationService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _service.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        var filteredList = _service.notifications;
        if (_selectedFilter == 'Alerts') {
          filteredList =
              filteredList
                  .where((n) => n.type == NotificationType.warning)
                  .toList();
        } else if (_selectedFilter == 'Success') {
          filteredList =
              filteredList
                  .where((n) => n.type == NotificationType.success)
                  .toList();
        } else if (_selectedFilter == 'Legal') {
          filteredList =
              filteredList
                  .where((n) => n.type == NotificationType.compliance)
                  .toList();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.brandDeepGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activity & Notifications',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${_service.notifications.length} logged events with timestamps',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_service.notifications.isNotEmpty)
                      TextButton(
                        onPressed: () => _service.clearAll(),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children:
                      ['All', 'Success', 'Alerts', 'Legal'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected:
                                (selected) =>
                                    setState(() => _selectedFilter = filter),
                            selectedColor: AppColors.brandDeepGreen,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? AppColors.brandDeepGreen
                                        : AppColors.outlineVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.outlineVariant),

              // Notification List
              Expanded(
                child:
                    filteredList.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 48,
                                color: AppColors.outlineVariant,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No notifications in this filter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: item.color.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.color,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item.timeFormatted,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: item.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
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
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
