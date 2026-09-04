import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';
import 'package:mentorride/features/service_reports/presentation/controllers/service_report_controller.dart';
import 'package:mentorride/features/service_reports/providers/service_report_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

void main() {
  test('menolak riwayat lama ketika scope kendaraan sedang berganti', () async {
    final exportService = _SpyExportService();
    final container = ProviderContainer(
      overrides: [
        activeVehicleProvider.overrideWith(
          () => _FakeActiveVehicleController(_newVehicle),
        ),
        activeServiceRecordScopeProvider.overrideWithValue(
          const ActiveServiceRecordScope(uid: 'user-1', vehicleId: 'old'),
        ),
        serviceRecordsProvider.overrideWith(
          (ref) => Stream.value([_oldRecord]),
        ),
        serviceReportExportServiceProvider.overrideWithValue(exportService),
      ],
    );
    addTearDown(container.dispose);
    final recordsSubscription = container.listen(
      serviceRecordsProvider,
      (previous, next) {},
    );
    addTearDown(recordsSubscription.close);

    await container.read(activeVehicleProvider.future);
    await container.read(serviceRecordsProvider.future);

    final result = await container
        .read(serviceReportControllerProvider.notifier)
        .exportActiveVehicle(ServiceReportFormat.csv);

    expect(result, isNull);
    expect(exportService.calls, 0);
    expect(
      container.read(serviceReportControllerProvider).errorMessage,
      'Tunggu hingga riwayat kendaraan aktif siap.',
    );
  });

  test('mengekspor hanya setelah kendaraan dan riwayat satu scope', () async {
    final exportService = _SpyExportService();
    final container = ProviderContainer(
      overrides: [
        activeVehicleProvider.overrideWith(
          () => _FakeActiveVehicleController(_newVehicle),
        ),
        activeServiceRecordScopeProvider.overrideWithValue(
          const ActiveServiceRecordScope(uid: 'user-1', vehicleId: 'new'),
        ),
        serviceRecordsProvider.overrideWith(
          (ref) => Stream.value([_newRecord]),
        ),
        serviceReportExportServiceProvider.overrideWithValue(exportService),
      ],
    );
    addTearDown(container.dispose);
    final recordsSubscription = container.listen(
      serviceRecordsProvider,
      (previous, next) {},
    );
    addTearDown(recordsSubscription.close);

    await container.read(activeVehicleProvider.future);
    await container.read(serviceRecordsProvider.future);

    final result = await container
        .read(serviceReportControllerProvider.notifier)
        .exportActiveVehicle(ServiceReportFormat.csv);

    expect(result?.format, ServiceReportFormat.csv);
    expect(exportService.calls, 1);
    expect(exportService.lastVehicleId, 'new');
    expect(exportService.lastRecordIds, ['new-record']);
  });
}

class _FakeActiveVehicleController extends ActiveVehicleController {
  _FakeActiveVehicleController(this.vehicle);

  final Vehicle vehicle;

  @override
  Future<Vehicle?> build() async => vehicle;
}

class _SpyExportService extends ServiceReportExportService {
  _SpyExportService()
    : super(
        pdfGenerator: _Generator(ServiceReportFormat.pdf),
        csvGenerator: _Generator(ServiceReportFormat.csv),
        fileStore: _FileStore(),
        sharer: _Sharer(),
      );

  int calls = 0;
  String? lastVehicleId;
  List<String>? lastRecordIds;

  @override
  Future<ExportedServiceReport> exportAndShare({
    required Vehicle vehicle,
    required Iterable<ServiceRecord> records,
    required ServiceReportFormat format,
  }) async {
    calls += 1;
    lastVehicleId = vehicle.id;
    lastRecordIds = records.map((record) => record.id).toList(growable: false);
    return ExportedServiceReport(
      filePath: 'report.${format.extension}',
      fileName: 'report.${format.extension}',
      format: format,
    );
  }
}

class _Generator implements ServiceReportDocumentGenerator {
  const _Generator(this.format);

  @override
  final ServiceReportFormat format;

  @override
  Future<Uint8List> generate(ServiceReportData report) async => Uint8List(1);
}

class _FileStore implements ServiceReportFileStore {
  @override
  Future<String> writeTemporary({
    required String fileName,
    required Uint8List bytes,
  }) async => fileName;
}

class _Sharer implements ServiceReportSharer {
  @override
  Future<void> share({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String vehicleName,
  }) async {}
}

const _newVehicle = Vehicle(
  id: 'new',
  name: 'Motor baru',
  brand: 'Honda',
  model: 'Beat',
  year: 2026,
  plateNumber: 'B 1234 NEW',
  currentOdometer: 1000,
);

final _oldRecord = ServiceRecord(
  id: 'old-record',
  serviceDate: DateTime(2026, 8, 1),
  odometer: 900,
  workshop: 'Bengkel lama',
  items: const [],
  notes: '',
);

final _newRecord = ServiceRecord(
  id: 'new-record',
  serviceDate: DateTime(2026, 9, 1),
  odometer: 1000,
  workshop: 'Bengkel baru',
  items: const [],
  notes: '',
);
