import 'dart:convert';

import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/services/backup_mapper.dart';
import 'package:mentorride/features/backup/domain/services/backup_validator.dart';

abstract final class BackupSerializer {
  static String serialize(MentorRideBackup backup) {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(BackupMapper.toMap(backup));
  }

  static MentorRideBackup deserialize(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const AppException('Struktur file cadangan tidak valid.');
      }
      final map = decoded.map(
        (key, value) => MapEntry(key.toString(), value as Object?),
      );
      return BackupValidator.validate(map);
    } on AppException {
      rethrow;
    } on FormatException {
      throw const AppException(
        'File cadangan rusak atau bukan JSON yang valid.',
      );
    } on Object {
      throw const AppException('File cadangan tidak dapat dibaca.');
    }
  }
}
