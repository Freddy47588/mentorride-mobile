import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/service_schedules/application/service_schedule_coordinator.dart';
import 'package:mentorride/features/service_schedules/data/repositories/firestore_service_schedule_repository.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/repositories/service_schedule_repository.dart';
import 'package:mentorride/features/service_schedules/presentation/controllers/service_schedule_controller.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

export 'package:mentorride/core/notifications/notification_providers.dart';
export 'package:mentorride/core/notifications/reminder_scheduler.dart';

final serviceScheduleRepositoryProvider = Provider<ServiceScheduleRepository>((
  ref,
) {
  return FirestoreServiceScheduleRepository(ref.watch(firestoreProvider));
});

final serviceScheduleCoordinatorProvider = Provider<ServiceScheduleCoordinator>(
  (ref) {
    return ServiceScheduleCoordinator(
      ref.watch(serviceScheduleRepositoryProvider),
      ref.watch(reminderSchedulerProvider),
    );
  },
);

class ActiveServiceScheduleScope {
  const ActiveServiceScheduleScope({
    required this.uid,
    required this.vehicleId,
  });

  final String uid;
  final String vehicleId;
}

final activeServiceScheduleScopeProvider =
    Provider<ActiveServiceScheduleScope?>((ref) {
      final uid = ref.watch(authSessionProvider).value?.uid;
      final vehicleId = ref.watch(activeVehicleProvider).value?.id;
      if (uid == null || vehicleId == null) return null;
      return ActiveServiceScheduleScope(uid: uid, vehicleId: vehicleId);
    });

final serviceSchedulesProvider = StreamProvider<List<ServiceSchedule>>((ref) {
  final scope = ref.watch(activeServiceScheduleScopeProvider);
  if (scope == null) return Stream.value(const <ServiceSchedule>[]);

  return ref
      .watch(serviceScheduleRepositoryProvider)
      .watchServiceSchedules(uid: scope.uid, vehicleId: scope.vehicleId);
});

final serviceScheduleByIdProvider =
    Provider.family<AsyncValue<ServiceSchedule?>, String>((ref, scheduleId) {
      return ref.watch(serviceSchedulesProvider).whenData((schedules) {
        for (final schedule in schedules) {
          if (schedule.id == scheduleId) return schedule;
        }
        return null;
      });
    });

final pendingServiceSchedulesProvider =
    Provider<AsyncValue<List<ServiceSchedule>>>((ref) {
      return ref
          .watch(serviceSchedulesProvider)
          .whenData(
            (schedules) => schedules
                .where((schedule) => !schedule.isCompleted)
                .toList(growable: false),
          );
    });

final nextServiceScheduleProvider = Provider<AsyncValue<ServiceSchedule?>>((
  ref,
) {
  return ref.watch(pendingServiceSchedulesProvider).whenData((schedules) {
    return schedules.isEmpty ? null : schedules.first;
  });
});

final serviceScheduleControllerProvider =
    NotifierProvider<ServiceScheduleController, ServiceScheduleActionState>(
      ServiceScheduleController.new,
    );
