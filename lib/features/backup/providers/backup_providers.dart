import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/backup/application/backup_service.dart';
import 'package:mentorride/features/backup/data/repositories/firestore_backup_repository.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/repositories/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return FirestoreBackupRepository(ref.watch(firestoreProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(backupRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  );
});

class BackupActionState {
  const BackupActionState({this.isBusy = false, this.errorMessage});

  final bool isBusy;
  final String? errorMessage;
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupActionState>(BackupController.new);

class BackupController extends Notifier<BackupActionState> {
  @override
  BackupActionState build() => const BackupActionState();

  Future<bool> createAndShare() async {
    final uid = _uid();
    if (uid == null || state.isBusy) return false;
    state = const BackupActionState(isBusy: true);
    try {
      await ref.read(backupServiceProvider).createAndShare(uid);
      state = const BackupActionState();
      return true;
    } on Object catch (error) {
      state = BackupActionState(errorMessage: _message(error));
      return false;
    }
  }

  Future<MentorRideBackup?> pickAndValidate() async {
    if (state.isBusy) return null;
    state = const BackupActionState(isBusy: true);
    try {
      final backup = await ref.read(backupServiceProvider).pickAndValidate();
      state = const BackupActionState();
      return backup;
    } on Object catch (error) {
      state = BackupActionState(errorMessage: _message(error));
      return null;
    }
  }

  Future<BackupRestoreResult?> restore(MentorRideBackup backup) async {
    final uid = _uid();
    if (uid == null || state.isBusy) return null;
    state = const BackupActionState(isBusy: true);
    try {
      final result = await ref
          .read(backupServiceProvider)
          .restore(uid: uid, backup: backup);
      state = const BackupActionState();
      return result;
    } on Object catch (error) {
      state = BackupActionState(errorMessage: _message(error));
      return null;
    }
  }

  String? _uid() {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || uid.isEmpty) {
      state = const BackupActionState(
        errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      );
      return null;
    }
    return uid;
  }

  String _message(Object error) {
    if (error is AppException) return error.message;
    if (error is FormatException) {
      return 'File cadangan rusak atau tidak valid.';
    }
    if (error is FirebaseException) {
      return error.code == 'permission-denied'
          ? 'Anda tidak memiliki izin untuk mengakses cadangan data.'
          : 'Data belum dapat diproses. Periksa koneksi Anda.';
    }
    return 'Cadangan data belum dapat diproses. Silakan coba lagi.';
  }
}
