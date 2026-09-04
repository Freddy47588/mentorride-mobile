import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

void main() {
  test('archive gagal memulihkan pengingat kendaraan', () async {
    final repository = _FakeVehicleRepository(failArchive: true);
    final scheduler = _FakeReminderScheduler();
    final container = _container(repository, scheduler);
    addTearDown(container.dispose);

    final success = await container
        .read(vehicleControllerProvider.notifier)
        .archiveVehicle('vehicle-1');

    expect(success, isFalse);
    expect(scheduler.cancelledIds, [99]);
    expect(scheduler.scheduledIds, [99]);
    expect(repository.archiveValues, [true]);
  });

  test(
    'restore gagal menjadwalkan ulang lalu mengarsipkan kendaraan',
    () async {
      final repository = _FakeVehicleRepository();
      final scheduler = _FakeReminderScheduler(failSchedule: true);
      final container = _container(repository, scheduler);
      addTearDown(container.dispose);

      final success = await container
          .read(vehicleControllerProvider.notifier)
          .restoreVehicle('vehicle-1');

      expect(success, isFalse);
      expect(scheduler.scheduledIds, [99]);
      expect(scheduler.cancelledIds, [99]);
      expect(repository.archiveValues, [false, true]);
    },
  );
}

ProviderContainer _container(
  VehicleRepository repository,
  ReminderScheduler scheduler,
) {
  return ProviderContainer(
    overrides: [
      vehicleRepositoryProvider.overrideWithValue(repository),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      authSessionProvider.overrideWithValue(
        const AsyncData(
          AuthSession(
            uid: 'user-1',
            email: 'rider@example.test',
            isEmailVerified: true,
          ),
        ),
      ),
    ],
  );
}

class _FakeVehicleRepository implements VehicleRepository {
  _FakeVehicleRepository({this.failArchive = false});

  final bool failArchive;
  final List<bool> archiveValues = [];

  @override
  Future<void> setArchived({
    required String uid,
    required String vehicleId,
    required bool isArchived,
  }) async {
    archiveValues.add(isArchived);
    if (isArchived && failArchive) throw StateError('archive gagal');
  }

  @override
  Future<List<ServiceSchedule>> schedulesForVehicle(
    String uid,
    String vehicleId,
  ) async => [_schedule()];

  @override
  Future<Vehicle> createVehicle(String uid, Vehicle vehicle) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCascade(String uid, String vehicleId) {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId) async =>
      const [99];

  @override
  Future<VehicleOdometerUpdateResult> updateOdometer({
    required String uid,
    required String vehicleId,
    required int odometer,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateVehicle(String uid, Vehicle vehicle) {
    throw UnimplementedError();
  }

  @override
  Stream<Vehicle?> watchVehicle(String uid, String vehicleId) {
    return const Stream.empty();
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String uid) {
    return const Stream.empty();
  }
}

class _FakeReminderScheduler implements ReminderScheduler {
  _FakeReminderScheduler({this.failSchedule = false});

  final bool failSchedule;
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];

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
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
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
    scheduledIds.add(id);
    if (failSchedule) throw StateError('scheduler gagal');
  }
}

ServiceSchedule _schedule() {
  final now = DateTime.now();
  return ServiceSchedule(
    id: '550e8400-e29b-41d4-a716-446655440000',
    title: 'Ganti oli',
    serviceType: 'Oli mesin',
    dueDate: now.add(const Duration(days: 3)),
    dueOdometer: 2000,
    reminderAt: now.add(const Duration(days: 2)),
    reminderEnabled: true,
    localNotificationId: 99,
    status: ServiceScheduleStatus.pending,
  );
}
