import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

abstract final class CalendarScheduleGrouper {
  static Map<DateTime, List<ServiceSchedule>> group(
    Iterable<ServiceSchedule> schedules,
  ) {
    final grouped = <DateTime, List<ServiceSchedule>>{};
    for (final schedule in schedules) {
      final local = schedule.dueDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(day, () => []).add(schedule);
    }
    for (final values in grouped.values) {
      values.sort((a, b) => a.title.compareTo(b.title));
    }
    return Map<DateTime, List<ServiceSchedule>>.unmodifiable(
      grouped.map(
        (key, value) =>
            MapEntry(key, List<ServiceSchedule>.unmodifiable(value)),
      ),
    );
  }
}
