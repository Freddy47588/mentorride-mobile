import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';

abstract interface class BackupRepository {
  Future<MentorRideBackup> createBackup(String uid);

  Future<BackupRestoreResult> restoreBackup({
    required String uid,
    required MentorRideBackup backup,
  });
}
