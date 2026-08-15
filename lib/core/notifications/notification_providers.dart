import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/notifications/local_notification_service.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return LocalNotificationService();
});

final notificationPermissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>((ref) {
      return ref.watch(reminderSchedulerProvider).permissionStatus();
    });
