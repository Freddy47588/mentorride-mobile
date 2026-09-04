import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_status_badge.dart';

void main() {
  testWidgets('badge menampilkan status kalkulator dan status selesai', (
    tester,
  ) async {
    final schedule = _schedule(ServiceScheduleStatus.pending);
    final dueStatus = ServiceScheduleDueCalculator.calculate(
      schedule: schedule,
      now: DateTime(2026, 9, 1),
      currentOdometer: 10000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ServiceScheduleStatusBadge(
              schedule: schedule,
              dueStatus: dueStatus,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mendekati'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final completed = _schedule(ServiceScheduleStatus.completed);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ServiceScheduleStatusBadge(
            schedule: completed,
            dueStatus: dueStatus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selesai'), findsOneWidget);
  });
}

ServiceSchedule _schedule(ServiceScheduleStatus status) {
  return ServiceSchedule(
    id: 'schedule-1',
    title: 'Ganti oli',
    serviceType: 'Oli mesin',
    dueDate: DateTime(2026, 9, 5),
    dueOdometer: 12000,
    reminderAt: DateTime(2026, 9, 4),
    reminderEnabled: false,
    localNotificationId: 1,
    status: status,
  );
}
