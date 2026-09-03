import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_list_screen.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('riwayat responsif pada layar kecil dan teks besar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeVehicleProvider.overrideWith(
            () => _FakeActiveVehicleController(_vehicle),
          ),
          serviceRecordsProvider.overrideWith((ref) => Stream.value([_record])),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const ServiceRecordListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cari riwayat'), findsOneWidget);
    expect(find.text('Statistik perawatan'), findsOneWidget);
    expect(find.text('Oli mesin (1×)'), findsOneWidget);
    expect(find.byTooltip('Ekspor laporan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeActiveVehicleController extends ActiveVehicleController {
  _FakeActiveVehicleController(this.vehicle);

  final Vehicle vehicle;

  @override
  Future<Vehicle?> build() async => vehicle;
}

const _vehicle = Vehicle(
  id: 'vehicle-1',
  name: 'Motor harian keluarga',
  brand: 'Honda',
  model: 'Vario 160',
  year: 2024,
  plateNumber: 'B 1234 XYZ',
  currentOdometer: 12450,
);

final _record = ServiceRecord(
  id: 'record-1',
  serviceDate: DateTime(2026, 9, 1),
  odometer: 12000,
  workshop: 'Bengkel langganan',
  items: const [
    ServiceItem(name: 'Oli mesin', action: ServiceAction.ganti, cost: 75000),
  ],
  notes: 'Servis rutin',
);
