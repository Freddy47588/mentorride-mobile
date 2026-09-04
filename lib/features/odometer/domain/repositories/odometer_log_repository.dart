import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';

abstract interface class OdometerLogRepository {
  Stream<List<OdometerLog>> watchLogs({
    required String uid,
    required String vehicleId,
    required DateTime since,
    int limit = 500,
  });
}
