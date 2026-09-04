import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/maintenance_calendar/domain/services/calendar_schedule_grouper.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

void main() {
  test(
    'calendar schedule grouping mengabaikan jam dan mengelompokkan tanggal',
    () {
      final schedules = [
        _schedule('b', 'Cek CVT', DateTime(2026, 9, 10, 16)),
        _schedule('a', 'Ganti oli', DateTime(2026, 9, 10, 8)),
        _schedule('c', 'Periksa rem', DateTime(2026, 9, 11, 8)),
      ];
      final grouped = CalendarScheduleGrouper.group(schedules);
      expect(grouped[DateTime(2026, 9, 10)], hasLength(2));
      expect(grouped[DateTime(2026, 9, 10)]!.map((value) => value.title), [
        'Cek CVT',
        'Ganti oli',
      ]);
      expect(grouped[DateTime(2026, 9, 11)]!.single.title, 'Periksa rem');
    },
  );
}

ServiceSchedule _schedule(String id, String title, DateTime dueDate) {
  return ServiceSchedule(
    id: id,
    title: title,
    serviceType: title,
    dueDate: dueDate,
    dueOdometer: null,
    reminderAt: dueDate,
    reminderEnabled: false,
    localNotificationId: 1,
    status: ServiceScheduleStatus.pending,
  );
}
