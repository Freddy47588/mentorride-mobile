enum NotificationPermissionStatus { granted, denied, unavailable }

abstract interface class ReminderScheduler {
  Future<void> initialize();

  Future<NotificationPermissionStatus> permissionStatus();

  Future<NotificationPermissionStatus> requestPermission();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  });

  Future<void> cancel(int notificationId);

  Future<void> cancelMany(Iterable<int> notificationIds);

  Future<void> cancelAll();
}
