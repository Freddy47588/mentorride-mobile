import 'dart:io';
import 'dart:typed_data';

import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:path_provider/path_provider.dart';

class TemporaryServiceReportFileStore implements ServiceReportFileStore {
  const TemporaryServiceReportFileStore();

  @override
  Future<String> writeTemporary({
    required String fileName,
    required Uint8List bytes,
  }) async {
    _validateFileName(fileName);
    final temporaryDirectory = await getTemporaryDirectory();
    final reportDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}mentorride_reports',
    );
    await reportDirectory.create(recursive: true);
    final file = File(
      '${reportDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _validateFileName(String fileName) {
    if (fileName.isEmpty ||
        fileName == '.' ||
        fileName == '..' ||
        fileName.contains('/') ||
        fileName.contains('\\')) {
      throw ArgumentError.value(fileName, 'fileName', 'Nama file tidak aman.');
    }
  }
}
