import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/notification_id.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/service_schedules/application/service_schedule_coordinator.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/repositories/service_schedule_repository.dart';

void main() {
  group('ServiceScheduleCoordinator', () {
    test('create menyimpan jadwal lalu menjadwalkan pengingat', () async {
      final events = <String>[];
      final repository = _FakeServiceScheduleRepository(events);
      final scheduler = _FakeReminderScheduler(events);
      final coordinator = ServiceScheduleCoordinator(repository, scheduler);
      final input = _pendingSchedule(id: '', localNotificationId: 0);

      final created = await coordinator.create(
        uid: 'user-1',
        vehicleId: 'vehicle-1',
        schedule: input,
      );

      final expectedNotificationId = StableNotificationId.fromUuid(created.id);
      expect(repository.createdUid, 'user-1');
      expect(repository.createdVehicleId, 'vehicle-1');
      expect(repository.createdSchedule, same(input));
      expect(created.id, _FakeServiceScheduleRepository.createdId);
      expect(created.localNotificationId, expectedNotificationId);
      expect(scheduler.permissionStatusCalls, 1);
      expect(scheduler.requestPermissionCalls, 0);
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.id, expectedNotificationId);
      expect(
        scheduler.scheduled.single.payload,
        '/schedules/${_FakeServiceScheduleRepository.createdId}',
      );
      expect(events, ['repository.create', 'scheduler.schedule']);
    });

    test('update menormalkan ID notifikasi sebelum menyimpan', () async {
      final events = <String>[];
      final repository = _FakeServiceScheduleRepository(events);
      final scheduler = _FakeReminderScheduler(events);
      final coordinator = ServiceScheduleCoordinator(repository, scheduler);
      final input = _pendingSchedule(localNotificationId: 7);

      await coordinator.update(
        uid: 'user-1',
        vehicleId: 'vehicle-1',
        schedule: input,
      );

      final expectedNotificationId = StableNotificationId.fromUuid(input.id);
      expect(repository.updatedSchedule?.id, input.id);
      expect(
        repository.updatedSchedule?.localNotificationId,
        expectedNotificationId,
      );
      expect(scheduler.scheduled.single.id, expectedNotificationId);
      expect(events, ['repository.update', 'scheduler.schedule']);
    });

    test('delete membatalkan pengingat sebelum menghapus data', () async {
      final events = <String>[];
      final repository = _FakeServiceScheduleRepository(events);
      final scheduler = _FakeReminderScheduler(events);
      final coordinator = ServiceScheduleCoordinator(repository, scheduler);
      final schedule = _pendingSchedule(localNotificationId: 321);

      await coordinator.delete(
        uid: 'user-1',
        vehicleId: 'vehicle-1',
        schedule: schedule,
      );

      expect(scheduler.cancelled, [321]);
      expect(repository.deletedUid, 'user-1');
      expect(repository.deletedVehicleId, 'vehicle-1');
      expect(repository.deletedScheduleId, schedule.id);
      expect(events, ['scheduler.cancel', 'repository.delete']);
    });

    test('complete menandai selesai dan mematikan pengingat', () async {
      final events = <String>[];
      final repository = _FakeServiceScheduleRepository(events);
      final scheduler = _FakeReminderScheduler(events);
      final coordinator = ServiceScheduleCoordinator(repository, scheduler);
      final schedule = _pendingSchedule(localNotificationId: 7);

      final completed = await coordinator.complete(
        uid: 'user-1',
        vehicleId: 'vehicle-1',
        schedule: schedule,
      );

      final expectedNotificationId = StableNotificationId.fromUuid(schedule.id);
      expect(completed.status, ServiceScheduleStatus.completed);
      expect(completed.reminderEnabled, isFalse);
      expect(completed.localNotificationId, expectedNotificationId);
      expect(repository.updatedSchedule, same(completed));
      expect(scheduler.cancelled, [expectedNotificationId]);
      expect(events, ['scheduler.cancel', 'repository.update']);
    });

    test('tidak menyimpan jadwal bila izin pengingat ditolak', () async {
      final events = <String>[];
      final repository = _FakeServiceScheduleRepository(events);
      final scheduler = _FakeReminderScheduler(
        events,
        permission: NotificationPermissionStatus.denied,
        requestedPermission: NotificationPermissionStatus.denied,
      );
      final coordinator = ServiceScheduleCoordinator(repository, scheduler);

      await expectLater(
        coordinator.create(
          uid: 'user-1',
          vehicleId: 'vehicle-1',
          schedule: _pendingSchedule(id: '', localNotificationId: 0),
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            contains('Izin notifikasi'),
          ),
        ),
      );

      expect(scheduler.permissionStatusCalls, 1);
      expect(scheduler.requestPermissionCalls, 1);
      expect(repository.createdSchedule, isNull);
      expect(events, isEmpty);
    });
  });
}

const _scheduleId = '550e8400-e29b-41d4-a716-446655440000';

ServiceSchedule _pendingSchedule({
  String id = _scheduleId,
  required int localNotificationId,
}) {
  final now = DateTime.now();
  return ServiceSchedule(
    id: id,
    title: 'Servis berkala',
    serviceType: 'Ganti oli',
    dueDate: now.add(const Duration(days: 30)),
    dueOdometer: 18000,
    reminderAt: now.add(const Duration(days: 29)),
    reminderEnabled: true,
    localNotificationId: localNotificationId,
    status: ServiceScheduleStatus.pending,
  );
}

class _FakeServiceScheduleRepository implements ServiceScheduleRepository {
  _FakeServiceScheduleRepository(this.events);

  static const createdId = '123e4567-e89b-12d3-a456-426614174000';

  final List<String> events;
  String? createdUid;
  String? createdVehicleId;
  ServiceSchedule? createdSchedule;
  ServiceSchedule? updatedSchedule;
  String? deletedUid;
  String? deletedVehicleId;
  String? deletedScheduleId;

  @override
  Future<ServiceSchedule> createServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    events.add('repository.create');
    createdUid = uid;
    createdVehicleId = vehicleId;
    createdSchedule = schedule;
    return schedule.copyWith(
      id: createdId,
      localNotificationId: StableNotificationId.fromUuid(createdId),
    );
  }

  @override
  Future<void> deleteServiceSchedule({
    required String uid,
    required String vehicleId,
    required String scheduleId,
  }) async {
    events.add('repository.delete');
    deletedUid = uid;
    deletedVehicleId = vehicleId;
    deletedScheduleId = scheduleId;
  }

  @override
  Future<void> updateServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    events.add('repository.update');
    updatedSchedule = schedule;
  }

  @override
  Stream<List<ServiceSchedule>> watchServiceSchedules({
    required String uid,
    required String vehicleId,
  }) {
    return const Stream.empty();
  }
}

class _FakeReminderScheduler implements ReminderScheduler {
  _FakeReminderScheduler(
    this.events, {
    this.permission = NotificationPermissionStatus.granted,
    this.requestedPermission = NotificationPermissionStatus.granted,
  });

  final List<String> events;
  final NotificationPermissionStatus permission;
  final NotificationPermissionStatus requestedPermission;
  final List<_ScheduledReminder> scheduled = [];
  final List<int> cancelled = [];
  int permissionStatusCalls = 0;
  int requestPermissionCalls = 0;

  @override
  Future<void> cancel(int notificationId) async {
    events.add('scheduler.cancel');
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {
    cancelled.addAll(notificationIds);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    permissionStatusCalls += 1;
    return permission;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestPermissionCalls += 1;
    return requestedPermission;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    events.add('scheduler.schedule');
    scheduled.add(
      _ScheduledReminder(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        payload: payload,
      ),
    );
  }
}

class _ScheduledReminder {
  const _ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String? payload;
}
