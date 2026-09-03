import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:share_plus/share_plus.dart';

class SharePlusServiceReportSharer implements ServiceReportSharer {
  const SharePlusServiceReportSharer();

  @override
  Future<void> share({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String vehicleName,
  }) async {
    final displayName = vehicleName.trim().isEmpty
        ? 'kendaraan aktif'
        : vehicleName.trim();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: mimeType)],
        fileNameOverrides: [fileName],
        title: 'Bagikan laporan servis',
        subject: 'Laporan servis MentorRide - $displayName',
        text: 'Laporan riwayat servis MentorRide untuk $displayName.',
      ),
    );
  }
}
