import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

abstract interface class ServiceScheduleRepository {
  Stream<List<ServiceSchedule>> watchServiceSchedules({
    required String uid,
    required String vehicleId,
  });

  Future<ServiceSchedule> createServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  });

  Future<void> updateServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  });

  Future<void> deleteServiceSchedule({
    required String uid,
    required String vehicleId,
    required String scheduleId,
  });
}
