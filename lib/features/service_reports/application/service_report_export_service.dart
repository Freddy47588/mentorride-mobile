import 'dart:typed_data';

import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/report_filename_sanitizer.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_mapper.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

abstract interface class ServiceReportFileStore {
  Future<String> writeTemporary({
    required String fileName,
    required Uint8List bytes,
  });
}

abstract interface class ServiceReportSharer {
  Future<void> share({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String vehicleName,
  });
}

class ExportedServiceReport {
  const ExportedServiceReport({
    required this.filePath,
    required this.fileName,
    required this.format,
  });

  final String filePath;
  final String fileName;
  final ServiceReportFormat format;
}

class ServiceReportExportService {
  ServiceReportExportService({
    required ServiceReportDocumentGenerator pdfGenerator,
    required ServiceReportDocumentGenerator csvGenerator,
    required this.fileStore,
    required this.sharer,
    DateTime Function()? now,
  }) : _pdfGenerator = pdfGenerator,
       _csvGenerator = csvGenerator,
       _now = now ?? DateTime.now {
    if (pdfGenerator.format != ServiceReportFormat.pdf) {
      throw ArgumentError.value(
        pdfGenerator.format,
        'pdfGenerator.format',
        'Generator harus menghasilkan PDF.',
      );
    }
    if (csvGenerator.format != ServiceReportFormat.csv) {
      throw ArgumentError.value(
        csvGenerator.format,
        'csvGenerator.format',
        'Generator harus menghasilkan CSV.',
      );
    }
  }

  final ServiceReportDocumentGenerator _pdfGenerator;
  final ServiceReportDocumentGenerator _csvGenerator;
  final ServiceReportFileStore fileStore;
  final ServiceReportSharer sharer;
  final DateTime Function() _now;

  Future<ExportedServiceReport> exportAndShare({
    required Vehicle vehicle,
    required Iterable<ServiceRecord> records,
    required ServiceReportFormat format,
  }) async {
    final report = ServiceReportMapper.map(
      vehicle: vehicle,
      records: records,
      generatedAt: _now(),
    );
    final generator = switch (format) {
      ServiceReportFormat.pdf => _pdfGenerator,
      ServiceReportFormat.csv => _csvGenerator,
    };
    final bytes = await generator.generate(report);
    final fileName = ReportFilenameSanitizer.build(
      report: report,
      format: format,
    );
    final filePath = await fileStore.writeTemporary(
      fileName: fileName,
      bytes: bytes,
    );
    await sharer.share(
      filePath: filePath,
      fileName: fileName,
      mimeType: format.mimeType,
      vehicleName: report.vehicle.name,
    );
    return ExportedServiceReport(
      filePath: filePath,
      fileName: fileName,
      format: format,
    );
  }
}
