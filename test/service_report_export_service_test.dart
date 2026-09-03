import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  test(
    'memilih generator, menyimpan file sementara, lalu membagikannya',
    () async {
      final pdfGenerator = _FakeGenerator(
        ServiceReportFormat.pdf,
        Uint8List.fromList([1, 2, 3]),
      );
      final csvGenerator = _FakeGenerator(
        ServiceReportFormat.csv,
        Uint8List.fromList([4, 5, 6]),
      );
      final fileStore = _FakeFileStore();
      final sharer = _FakeSharer();
      final service = ServiceReportExportService(
        pdfGenerator: pdfGenerator,
        csvGenerator: csvGenerator,
        fileStore: fileStore,
        sharer: sharer,
        now: () => DateTime(2026, 9, 3),
      );

      final result = await service.exportAndShare(
        vehicle: _vehicle,
        records: [_record],
        format: ServiceReportFormat.csv,
      );

      expect(pdfGenerator.receivedReport, isNull);
      expect(csvGenerator.receivedReport?.summary.totalCost, 125000);
      expect(fileStore.receivedBytes, [4, 5, 6]);
      expect(
        fileStore.receivedFileName,
        'mentorride_honda_beat_b1234abc_2026-09-03.csv',
      );
      expect(sharer.filePath, '/temporary/${fileStore.receivedFileName}');
      expect(sharer.mimeType, 'text/csv');
      expect(sharer.vehicleName, 'Motor Harian');
      expect(result.fileName, fileStore.receivedFileName);
      expect(result.format, ServiceReportFormat.csv);
    },
  );

  test('menolak generator yang didaftarkan untuk format keliru', () {
    expect(
      () => ServiceReportExportService(
        pdfGenerator: _FakeGenerator(ServiceReportFormat.csv, Uint8List(0)),
        csvGenerator: _FakeGenerator(ServiceReportFormat.csv, Uint8List(0)),
        fileStore: _FakeFileStore(),
        sharer: _FakeSharer(),
      ),
      throwsArgumentError,
    );
  });
}

class _FakeGenerator implements ServiceReportDocumentGenerator {
  _FakeGenerator(this.format, this.bytes);

  @override
  final ServiceReportFormat format;
  final Uint8List bytes;
  ServiceReportData? receivedReport;

  @override
  Future<Uint8List> generate(ServiceReportData report) async {
    receivedReport = report;
    return bytes;
  }
}

class _FakeFileStore implements ServiceReportFileStore {
  String? receivedFileName;
  Uint8List? receivedBytes;

  @override
  Future<String> writeTemporary({
    required String fileName,
    required Uint8List bytes,
  }) async {
    receivedFileName = fileName;
    receivedBytes = bytes;
    return '/temporary/$fileName';
  }
}

class _FakeSharer implements ServiceReportSharer {
  String? filePath;
  String? fileName;
  String? mimeType;
  String? vehicleName;

  @override
  Future<void> share({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String vehicleName,
  }) async {
    this.filePath = filePath;
    this.fileName = fileName;
    this.mimeType = mimeType;
    this.vehicleName = vehicleName;
  }
}

const _vehicle = Vehicle(
  id: 'vehicle-1',
  name: 'Motor Harian',
  brand: 'Honda',
  model: 'Beat',
  year: 2024,
  plateNumber: 'B 1234 ABC',
  currentOdometer: 15000,
);

final _record = ServiceRecord(
  id: 'record-1',
  serviceDate: DateTime(2026, 9, 1),
  odometer: 15000,
  workshop: 'Bengkel',
  items: const [
    ServiceItem(name: 'Oli mesin', action: ServiceAction.ganti, cost: 125000),
  ],
  notes: '',
);
