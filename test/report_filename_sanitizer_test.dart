import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/report_filename_sanitizer.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_mapper.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  test('membuat nama file laporan yang aman dan deterministik', () {
    final report = _report(
      brand: 'Honda',
      model: 'Beat',
      plateNumber: 'B 1234 ABC',
    );

    expect(
      ReportFilenameSanitizer.build(
        report: report,
        format: ServiceReportFormat.pdf,
      ),
      'mentorride_honda_beat_b1234abc_2026-09-03.pdf',
    );
  });

  test('menghapus separator path dan karakter nama file yang tidak aman', () {
    final report = _report(
      brand: '../Honda',
      model: 'Beat / Deluxe:*?',
      plateNumber: r'B\12/34 "ABC"',
    );

    final fileName = ReportFilenameSanitizer.build(
      report: report,
      format: ServiceReportFormat.csv,
    );

    expect(fileName, 'mentorride_honda_beat_deluxe_b1234abc_2026-09-03.csv');
    expect(fileName, isNot(contains('/')));
    expect(fileName, isNot(contains(r'\')));
  });

  test('menggunakan nama kendaraan ketika merek dan model kosong', () {
    final report = _report(
      brand: '',
      model: '',
      plateNumber: '',
      name: 'Motor Harian',
    );

    expect(
      ReportFilenameSanitizer.build(
        report: report,
        format: ServiceReportFormat.pdf,
      ),
      'mentorride_motor_harian_2026-09-03.pdf',
    );
  });

  test('nama panjang tetap mempertahankan nomor polisi dan tanggal', () {
    final report = _report(
      brand: List.filled(30, 'Kendaraan').join(' '),
      model: List.filled(30, 'Harian').join(' '),
      plateNumber: 'B 1234 ABC',
    );

    final fileName = ReportFilenameSanitizer.build(
      report: report,
      format: ServiceReportFormat.pdf,
    );

    expect(fileName, endsWith('_b1234abc_2026-09-03.pdf'));
    expect(fileName.length, lessThanOrEqualTo(124));
  });
}

ServiceReportData _report({
  required String brand,
  required String model,
  required String plateNumber,
  String name = 'Motor',
}) {
  return ServiceReportMapper.map(
    vehicle: Vehicle(
      id: 'vehicle-1',
      name: name,
      brand: brand,
      model: model,
      year: 2024,
      plateNumber: plateNumber,
      currentOdometer: 10000,
    ),
    records: [
      ServiceRecord(
        id: 'record-1',
        serviceDate: DateTime(2026, 9, 1),
        odometer: 10000,
        workshop: 'Bengkel',
        items: const [
          ServiceItem(name: 'Oli', action: ServiceAction.ganti, cost: 100000),
        ],
        notes: '',
      ),
    ],
    generatedAt: DateTime(2026, 9, 3),
  );
}
