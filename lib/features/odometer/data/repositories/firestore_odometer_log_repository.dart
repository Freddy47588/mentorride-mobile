import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/odometer/domain/repositories/odometer_log_repository.dart';

class FirestoreOdometerLogRepository implements OdometerLogRepository {
  FirestoreOdometerLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<OdometerLog>> watchLogs({
    required String uid,
    required String vehicleId,
    required DateTime since,
    int limit = 500,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('odometer_logs')
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) {
                final data = document.data();
                return OdometerLog.fromMap({
                  ...data,
                  'id': document.id,
                  'recordedAt': _dateTime(data['recordedAt']),
                });
              })
              .toList(growable: false),
        )
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            const AppException('Riwayat kilometer belum dapat dimuat.'),
            stackTrace,
          );
        });
  }

  DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
