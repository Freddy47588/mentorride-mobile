import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

class ServiceSchedulePrefill {
  const ServiceSchedulePrefill({
    required this.title,
    required this.serviceType,
  });

  factory ServiceSchedulePrefill.fromSchedule(ServiceSchedule schedule) {
    return ServiceSchedulePrefill(
      title: schedule.title,
      serviceType: schedule.serviceType,
    );
  }

  final String title;
  final String serviceType;
}
