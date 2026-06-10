import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/features/notifications/data/models/notification_model.dart';
import 'package:calculator/features/notifications/data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;
  const NotificationsScreen({super.key, this.onRead});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await getIt<NotificationRepository>().getAll();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await getIt<NotificationRepository>().markAllRead();
    await _load();
    widget.onRead?.call();
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    await getIt<NotificationRepository>().markRead(n.id);
    if (mounted) {
      setState(() {
        _notifications = _notifications.map((e) => e.id == n.id
            ? NotificationModel(id: e.id, title: e.title, message: e.message, isRead: true, createdAt: e.createdAt)
            : e).toList();
      });
      widget.onRead?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Column(
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: Text('Отметить все как прочитанные ($unread)'),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Нет уведомлений',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          return _NotificationCard(notification: n, onTap: () => _markRead(n));
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final isApproved = notification.title.contains('одобрен');
    final isRejected = notification.title.contains('отклонён');
    final isDeleted = notification.title.contains('удалён');

    final Color color = isApproved
        ? Colors.green
        : isRejected || isDeleted
            ? Colors.red
            : Colors.blue;

    final IconData icon = isApproved
        ? Icons.check_circle_outline
        : isRejected
            ? Icons.cancel_outlined
            : isDeleted
                ? Icons.delete_outline
                : Icons.edit_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: notification.isRead ? Colors.white : color.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
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
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text(
                      dateFormat.format(notification.createdAt.toLocal()),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
