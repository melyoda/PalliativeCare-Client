// In lib/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palliatave_care_client/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

    @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  @override
  void initState() {
    super.initState();
    // ✅ CALL THE "MARK ALL AS READ" METHOD WHEN THE PAGE FIRST OPENS
    // We use a small delay to make sure the widget is fully built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.notifications.isEmpty) {
            return Center(child: Text("No notifications yet."));
          }
          return ListView.builder(
            itemCount: notificationService.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationService.notifications[index];
              return ListTile(
                leading: Icon(
                  notification.read ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: notification.read ? Colors.grey : Theme.of(context).primaryColor,
                ),
                title: Text(notification.title),
                subtitle: Text(notification.message),
                onTap: () {
                  if (!notification.read) {
                    notificationService.markAsRead(notification.id);
                  }
                  // Optionally, navigate to the related topic or post
                },
              );
            },
          );
        },
      ),
    );
  }
}