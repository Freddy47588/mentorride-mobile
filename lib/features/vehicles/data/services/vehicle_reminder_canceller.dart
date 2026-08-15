import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class VehicleReminderCanceller {
  Future<void> cancelAll(Iterable<int> notificationIds);
}

class LocalVehicleReminderCanceller implements VehicleReminderCanceller {
  LocalVehicleReminderCanceller(FlutterLocalNotificationsPlugin plugin)
    : _plugin = plugin;

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> cancelAll(Iterable<int> notificationIds) async {
    for (final id in notificationIds.toSet()) {
      await _plugin.cancel(id: id);
    }
  }
}
