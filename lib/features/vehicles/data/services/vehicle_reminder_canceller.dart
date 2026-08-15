import 'package:mentorride/core/notifications/reminder_scheduler.dart';

abstract interface class VehicleReminderCanceller {
  Future<void> cancelAll(Iterable<int> notificationIds);
}

class SchedulerVehicleReminderCanceller implements VehicleReminderCanceller {
  SchedulerVehicleReminderCanceller(this._scheduler);

  final ReminderScheduler _scheduler;

  @override
  Future<void> cancelAll(Iterable<int> notificationIds) async {
    await _scheduler.cancelMany(notificationIds);
  }
}
