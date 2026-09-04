abstract final class BackupFilenameSanitizer {
  static String build(DateTime exportedAt) {
    final local = exportedAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'mentorride_backup_${local.year}-$month-$day.json';
  }
}
