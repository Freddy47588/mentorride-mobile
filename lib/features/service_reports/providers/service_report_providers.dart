import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:mentorride/features/service_reports/data/services/csv_service_report_generator.dart';
import 'package:mentorride/features/service_reports/data/services/pdf_service_report_generator.dart';
import 'package:mentorride/features/service_reports/data/services/share_plus_service_report_sharer.dart';
import 'package:mentorride/features/service_reports/data/services/temporary_service_report_file_store.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';

final pdfServiceReportGeneratorProvider =
    Provider<ServiceReportDocumentGenerator>((ref) {
      return PdfServiceReportGenerator();
    });

final csvServiceReportGeneratorProvider =
    Provider<ServiceReportDocumentGenerator>((ref) {
      return CsvServiceReportGenerator();
    });

final serviceReportFileStoreProvider = Provider<ServiceReportFileStore>((ref) {
  return const TemporaryServiceReportFileStore();
});

final serviceReportSharerProvider = Provider<ServiceReportSharer>((ref) {
  return const SharePlusServiceReportSharer();
});

final serviceReportExportServiceProvider = Provider<ServiceReportExportService>(
  (ref) {
    return ServiceReportExportService(
      pdfGenerator: ref.watch(pdfServiceReportGeneratorProvider),
      csvGenerator: ref.watch(csvServiceReportGeneratorProvider),
      fileStore: ref.watch(serviceReportFileStoreProvider),
      sharer: ref.watch(serviceReportSharerProvider),
    );
  },
);
