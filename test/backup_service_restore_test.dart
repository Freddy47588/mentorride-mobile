import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/backup/application/backup_service.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/repositories/backup_repository.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  test('restore kendaraan arsip tidak meminta izin notifikasi', () async {
    final backup = _backup(isArchived: true);
    final repository = _FakeBackupRepository(_result());
    final scheduler = _FakeReminderScheduler();
    final service = BackupService(repository, scheduler);

    final result = await service.restore(uid: 'user-1', backup: backup);

    expect(result.vehicleCount, 1);
    expect(scheduler.permissionStatusCalls, 0);
    expect(scheduler.requestPermissionCalls, 0);
  });

  test('kegagalan reminder tidak menyamarkan restore yang berhasil', () async {
    final reminderAt = DateTime.now().add(const Duration(days: 2));
    final resultFromRepository = _result(reminderAt: reminderAt);
    final repository = _FakeBackupRepository(resultFromRepository);
    final scheduler = _FakeReminderScheduler(failSchedule: true);
    final service = BackupService(repository, scheduler);

    final result = await service.restore(
      uid: 'user-1',
      backup: _backup(isArchived: false, reminderAt: reminderAt),
    );

    expect(result.warningMessage, contains('Data berhasil dipulihkan'));
    expect(scheduler.cancelledIds, [101]);
  });
}

MentorRideBackup _backup({required bool isArchived, DateTime? reminderAt}) {
  final reminder = reminderAt ?? DateTime.now().add(const Duration(days: 2));
  return MentorRideBackup(
    exportedAt: DateTime.now(),
    vehicles: [
      BackupVehicleData(
        vehicle: Vehicle(
          id: 'vehicle-old',
          name: 'Motor',
          brand: 'Honda',
          model: 'Vario',
          year: 2024,
          plateNumber: 'B 1 MR',
          currentOdometer: 1000,
          isArchived: isArchived,
        ),
        serviceRecords: const [],
        serviceSchedules: [
          ServiceSchedule(
            id: 'schedule-old',
            title: 'Ganti oli',
            serviceType: 'Oli mesin',
            dueDate: reminder.add(const Duration(days: 1)),
            dueOdometer: 2000,
            reminderAt: reminder,
            reminderEnabled: true,
            localNotificationId: 99,
            status: ServiceScheduleStatus.pending,
          ),
        ],
        odometerLogs: const [],
      ),
    ],
  );
}

BackupRestoreResult _result({DateTime? reminderAt}) {
  return BackupRestoreResult(
    vehicleIdMapping: const {'vehicle-old': 'vehicle-new'},
    vehicleCount: 1,
    recordCount: 0,
    scheduleCount: 1,
    odometerLogCount: 0,
    reminders: reminderAt == null
        ? const []
        : [
            RestoredReminder(
              notificationId: 101,
              scheduleId: 'schedule-new',
              title: 'Ganti oli',
              serviceType: 'Oli mesin',
              reminderAt: reminderAt,
            ),
          ],
  );
}

class _FakeBackupRepository implements BackupRepository {
  _FakeBackupRepository(this.result);

  final BackupRestoreResult result;

  @override
  Future<MentorRideBackup> createBackup(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<BackupRestoreResult> restoreBackup({
    required String uid,
    required MentorRideBackup backup,
  }) async => result;
}

class _FakeReminderScheduler implements ReminderScheduler {
  _FakeReminderScheduler({this.failSchedule = false});

  final bool failSchedule;
  int permissionStatusCalls = 0;
  int requestPermissionCalls = 0;
  final List<int> cancelledIds = [];

  @override
  Future<void> cancel(int notificationId) async {
    cancelledIds.add(notificationId);
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {
    cancelledIds.addAll(notificationIds);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    permissionStatusCalls++;
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    if (failSchedule) throw StateError('scheduler gagal');
  }
}
