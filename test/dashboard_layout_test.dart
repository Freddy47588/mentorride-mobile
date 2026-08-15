import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:mentorride/features/dashboard/presentation/widgets/dashboard_overview.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('dashboard tidak overflow pada lebar 320 dan teks besar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 15);
    final summary = DashboardAggregator.aggregate(
      activeVehicle: const Vehicle(
        id: 'vehicle-1',
        name: 'Motor harian keluarga',
        brand: 'Honda',
        model: 'Vario 160',
        year: 2024,
        plateNumber: 'B 1234 XYZ',
        currentOdometer: 12450,
      ),
      serviceRecords: [
        ServiceRecord(
          id: 'record-1',
          serviceDate: DateTime(2026, 8, 1),
          odometer: 12000,
          workshop: 'Bengkel langganan',
          items: const [
            ServiceItem(
              name: 'Oli mesin',
              action: ServiceAction.ganti,
              cost: 75000,
            ),
          ],
          notes: '',
        ),
      ],
      serviceSchedules: [
        ServiceSchedule(
          id: 'schedule-1',
          title: 'Perawatan rutin berikutnya',
          serviceType: 'Oli mesin',
          dueDate: DateTime(2026, 8, 20),
          dueOdometer: 12500,
          reminderAt: DateTime(2026, 8, 19, 8),
          reminderEnabled: false,
          localNotificationId: 1,
          status: ServiceScheduleStatus.pending,
        ),
      ],
      now: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.35)),
          child: child!,
        ),
        home: Scaffold(
          body: DashboardOverview(
            summary: summary,
            now: now,
            onRefresh: () async {},
            onManageVehicles: () {},
            onAddService: () {},
            onAddSchedule: () {},
            onUpdateOdometer: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Perbarui kilometer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Enam bulan terakhir'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
