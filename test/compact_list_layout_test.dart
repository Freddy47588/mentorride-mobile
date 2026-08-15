import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/presentation/widgets/service_record_timeline_tile.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_card.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/presentation/widgets/vehicle_card.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('kartu kendaraan aman pada lebar 320 piksel', (tester) async {
    await _setCompactSurface(tester);

    const vehicle = Vehicle(
      id: 'vehicle-layout-test',
      name: 'Sepeda motor harian dengan nama yang sangat panjang',
      brand: 'Merek kendaraan panjang',
      model: 'Model kendaraan edisi perjalanan jarak jauh',
      year: 2026,
      plateNumber: 'B 1234 XYZ',
      currentOdometer: 987654321,
    );

    await tester.pumpWidget(
      _TestFrame(
        child: VehicleCard(
          vehicle: vehicle,
          isActive: false,
          onTap: () {},
          onSelect: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VehicleCard), findsOneWidget);
    expect(find.text('Jadikan aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline riwayat aman pada lebar 320 piksel', (tester) async {
    await _setCompactSurface(tester);

    final record = ServiceRecord(
      id: 'record-layout-test',
      serviceDate: DateTime(2026, 8, 15),
      odometer: 987654321,
      workshop: 'Bengkel dengan nama sangat panjang untuk pengujian layar',
      items: const [
        ServiceItem(
          name: 'Penggantian komponen',
          action: ServiceAction.ganti,
          cost: 987654321,
        ),
      ],
      notes: '',
    );

    await tester.pumpWidget(
      _TestFrame(
        child: ServiceRecordTimelineTile(
          record: record,
          isFirst: true,
          isLast: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRecordTimelineTile), findsOneWidget);
    expect(find.text('Total biaya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartu jadwal aman pada lebar 320 piksel', (tester) async {
    await _setCompactSurface(tester);

    final schedule = ServiceSchedule(
      id: 'schedule-layout-test',
      title: 'Perawatan berkala dengan judul yang sangat panjang',
      serviceType: 'Pemeriksaan sistem kendaraan secara menyeluruh',
      dueDate: DateTime(2026, 8, 10),
      dueOdometer: 123456789,
      reminderAt: DateTime(2026, 8, 9, 9),
      reminderEnabled: true,
      localNotificationId: 1,
      status: ServiceScheduleStatus.pending,
    );

    await tester.pumpWidget(
      _TestFrame(
        child: ServiceScheduleCard(
          schedule: schedule,
          currentOdometer: 123457000,
          now: DateTime(2026, 8, 15),
          onTap: () {},
          onComplete: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServiceScheduleCard), findsOneWidget);
    expect(find.text('Tandai selesai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setCompactSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

class _TestFrame extends StatelessWidget {
  const _TestFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.25)),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [child]),
        ),
      ),
    );
  }
}
