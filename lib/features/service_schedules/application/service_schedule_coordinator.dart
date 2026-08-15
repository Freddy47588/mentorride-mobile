import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/notification_id.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/repositories/service_schedule_repository.dart';

class ServiceScheduleCoordinator {
  const ServiceScheduleCoordinator(this._repository, this._reminderScheduler);

  final ServiceScheduleRepository _repository;
  final ReminderScheduler _reminderScheduler;

  Future<ServiceSchedule> create({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    await _ensurePermissionWhenNeeded(schedule);
    final created = await _repository.createServiceSchedule(
      uid: uid,
      vehicleId: vehicleId,
      schedule: schedule,
    );
    try {
      await _syncReminder(created);
      return created;
    } on Object catch (error, stackTrace) {
      await _rollbackCreate(uid: uid, vehicleId: vehicleId, schedule: created);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> update({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    final normalized = _withStableNotificationId(schedule);
    await _ensurePermissionWhenNeeded(normalized);
    await _repository.updateServiceSchedule(
      uid: uid,
      vehicleId: vehicleId,
      schedule: normalized,
    );
    await _syncReminder(normalized);
  }

  Future<void> delete({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    await _reminderScheduler.cancel(schedule.localNotificationId);
    await _repository.deleteServiceSchedule(
      uid: uid,
      vehicleId: vehicleId,
      scheduleId: schedule.id,
    );
  }

  Future<ServiceSchedule> complete({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    final completed = _withStableNotificationId(
      schedule,
    ).copyWith(status: ServiceScheduleStatus.completed, reminderEnabled: false);
    await _reminderScheduler.cancel(completed.localNotificationId);
    await _repository.updateServiceSchedule(
      uid: uid,
      vehicleId: vehicleId,
      schedule: completed,
    );
    return completed;
  }

  bool _needsReminder(ServiceSchedule schedule) {
    return schedule.reminderEnabled &&
        !schedule.isCompleted &&
        schedule.reminderAt.isAfter(DateTime.now());
  }

  Future<void> _ensurePermissionWhenNeeded(ServiceSchedule schedule) async {
    if (!_needsReminder(schedule)) return;

    var permission = await _reminderScheduler.permissionStatus();
    if (permission != NotificationPermissionStatus.granted) {
      permission = await _reminderScheduler.requestPermission();
    }
    if (permission == NotificationPermissionStatus.granted) return;

    throw AppException(
      permission == NotificationPermissionStatus.denied
          ? 'Izin notifikasi diperlukan untuk mengaktifkan pengingat.'
          : 'Layanan notifikasi belum tersedia pada perangkat ini.',
    );
  }

  Future<void> _syncReminder(ServiceSchedule schedule) async {
    if (!_needsReminder(schedule)) {
      await _reminderScheduler.cancel(schedule.localNotificationId);
      return;
    }

    await _reminderScheduler.schedule(
      id: schedule.localNotificationId,
      title: 'Pengingat servis: ${schedule.title}',
      body: '${schedule.serviceType} untuk kendaraan Anda segera dijadwalkan.',
      scheduledAt: schedule.reminderAt,
      payload: '/schedules/${schedule.id}',
    );
  }

  ServiceSchedule _withStableNotificationId(ServiceSchedule schedule) {
    if (schedule.id.isEmpty) return schedule;
    return schedule.copyWith(
      localNotificationId: StableNotificationId.fromUuid(schedule.id),
    );
  }

  Future<void> _rollbackCreate({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    try {
      await _reminderScheduler.cancel(schedule.localNotificationId);
    } on Object {
      // Pembersihan best-effort; kegagalan penjadwalan awal tetap dilaporkan.
    }
    try {
      await _repository.deleteServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        scheduleId: schedule.id,
      );
    } on Object {
      // Pembersihan best-effort; kegagalan penjadwalan awal tetap dilaporkan.
    }
  }
}
