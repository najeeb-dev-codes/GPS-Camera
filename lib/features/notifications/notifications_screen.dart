import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';
import 'models/app_notification.dart';
import 'notification_details_screen.dart';
import 'services/notification_repository.dart';
import 'widgets/notification_card.dart';

enum _NotificationFilter { all, unread, read }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository.instance;
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await _repository.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  List<AppNotification> get _visibleNotifications {
    return _repository.notifications.where((notification) {
      return switch (_filter) {
        _NotificationFilter.all => true,
        _NotificationFilter.unread => !notification.isRead,
        _NotificationFilter.read => notification.isRead,
      };
    }).toList(growable: false);
  }

  String _timeLabel(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<bool> _confirmDelete() {
    return showDeleteConfirmationDialog(
      context,
      title: 'Delete notification?',
      message: 'This notification will be permanently removed.',
    );
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _repository.delete(notification.id);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Notification deleted successfully',
        icon: Icons.delete_outline_rounded,
        backgroundColor: Colors.red,
      );
    } catch (_) {
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Unable to delete notification.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _openDetails(AppNotification notification) async {
    await _repository.markRead(notification.id);
    if (!mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NotificationDetailsScreen(
          notification: notification.copyWith(isRead: true),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.centerRight,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.white),
          SizedBox(height: 2),
          Text('Delete', style: TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotifications;
    final unread = _repository.unreadCount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Notifications',
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _repository.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 600
                ? 48.0
                : AppSpacing.screenPadding;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        AppSpacing.md,
                        padding,
                        AppSpacing.sm,
                      ),
                      child: AppTabSelector(
                        tabs: [
                          'All',
                          unread == 0 ? 'Unread' : 'Unread ($unread)',
                          'Read',
                        ],
                        selectedIndex: _filter.index,
                        onChanged: (index) => setState(
                          () => _filter = _NotificationFilter.values[index],
                        ),
                        scrollable: false,
                      ),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : visible.isEmpty
                              ? EmptyStatePlaceholder(
                                  icon: Icons.notifications_none_rounded,
                                  title: switch (_filter) {
                                    _NotificationFilter.all =>
                                      'No notifications',
                                    _NotificationFilter.unread =>
                                      'No unread notifications',
                                    _NotificationFilter.read =>
                                      'No read notifications',
                                  },
                                  description: _filter == _NotificationFilter.all
                                      ? 'New app activity will appear here.'
                                      : 'There are no matching notifications.',
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    padding,
                                    AppSpacing.sm,
                                    padding,
                                    AppSpacing.xxl,
                                  ),
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    final notification = visible[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Dismissible(
                                        key: ValueKey(notification.id),
                                        direction: DismissDirection.endToStart,
                                        background: _deleteBackground(),
                                        confirmDismiss: (_) => _confirmDelete(),
                                        onDismissed: (_) =>
                                            _deleteNotification(notification),
                                        child: NotificationCard(
                                          notification: notification,
                                          timeLabel:
                                              _timeLabel(notification.createdAt),
                                          onTap: () =>
                                              _openDetails(notification),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          AppBottomNavBar(
            currentIndex: -1,
            onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
          ),
        ],
      ),
    );
  }
}
