import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/data/services/pdf_service_report_generator.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_mapper.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('menghasilkan dokumen PDF A4 multi-halaman dari data laporan', () async {
    final report = ServiceReportMapper.map(
      vehicle: _vehicle,
      records: List.generate(
        80,
        (index) => ServiceRecord(
          id: 'record-$index',
          serviceDate: DateTime(2026, 9, 3).subtract(Duration(days: index)),
          odometer: 15000 - index,
          workshop: 'Bengkel MentorRide',
          items: const [
            ServiceItem(
              name: 'Oli mesin',
              action: ServiceAction.ganti,
              cost: 125000,
            ),
          ],
          notes: 'Servis berkala',
        ),
      ),
      generatedAt: DateTime(2026, 9, 3, 12),
    );

    final bytes = await PdfServiceReportGenerator().generate(report);

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('menghasilkan PDF valid ketika riwayat kosong', () async {
    final report = ServiceReportMapper.map(
      vehicle: _vehicle,
      records: const [],
      generatedAt: DateTime(2026, 9, 3, 12),
    );

    final bytes = await PdfServiceReportGenerator().generate(report);

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
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
