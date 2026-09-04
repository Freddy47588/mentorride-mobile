import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/repositories/backup_repository.dart';
import 'package:mentorride/features/backup/domain/services/backup_filename_sanitizer.dart';
import 'package:mentorride/features/backup/domain/services/backup_serializer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  const BackupService(this._repository, this._reminderScheduler);

  final BackupRepository _repository;
  final ReminderScheduler _reminderScheduler;

  Future<void> createAndShare(String uid) async {
    final backup = await _repository.createBackup(uid);
    final json = BackupSerializer.serialize(backup);
    BackupSerializer.deserialize(json);
    final fileName = BackupFilenameSanitizer.build(backup.exportedAt);
    final directory = await getTemporaryDirectory();
    final backupDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}mentorride_backups',
    );
    await backupDirectory.create(recursive: true);
    final file = File(
      '${backupDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsString(json, encoding: utf8, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        fileNameOverrides: [fileName],
        title: 'Cadangkan data MentorRide',
        subject: 'Cadangan data MentorRide',
        text: 'Simpan file ini di tempat yang aman.',
      ),
    );
  }

  Future<MentorRideBackup?> pickAndValidate() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (selected == null) return null;
    final bytes = await selected.readAsBytes();
    final source = utf8.decode(bytes, allowMalformed: false);
    return BackupSerializer.deserialize(source);
  }

  Future<BackupRestoreResult> restore({
    required String uid,
    required MentorRideBackup backup,
  }) async {
    final needsReminderPermission = backup.vehicles.any(
      (vehicle) => vehicle.serviceSchedules.any(
        (schedule) =>
            schedule.reminderEnabled &&
            !schedule.isCompleted &&
            schedule.reminderAt.isAfter(DateTime.now()),
      ),
    );
    if (needsReminderPermission) {
      var permission = await _reminderScheduler.permissionStatus();
      if (permission != NotificationPermissionStatus.granted) {
        permission = await _reminderScheduler.requestPermission();
      }
      if (permission != NotificationPermissionStatus.granted) {
        throw const AppException(
          'Izin notifikasi diperlukan untuk memulihkan pengingat aktif.',
        );
      }
    }

    final result = await _repository.restoreBackup(uid: uid, backup: backup);
    for (final reminder in result.reminders) {
      await _reminderScheduler.schedule(
        id: reminder.notificationId,
        title: 'Pengingat servis: ${reminder.title}',
        body:
            '${reminder.serviceType} untuk kendaraan Anda segera dijadwalkan.',
        scheduledAt: reminder.reminderAt,
        payload: '/schedules/${reminder.scheduleId}',
      );
    }
    return result;
  }
}
