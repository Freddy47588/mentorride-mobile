import 'dart:typed_data';

import 'package:mentorride/features/service_reports/domain/models/service_report.dart';

abstract interface class ServiceReportDocumentGenerator {
  ServiceReportFormat get format;

  Future<Uint8List> generate(ServiceReportData report);
}
