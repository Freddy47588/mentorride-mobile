import 'package:mentorride/features/service_records/domain/models/service_record.dart';

abstract interface class ServiceRecordRepository {
  Stream<List<ServiceRecord>> watchServiceRecords({
    required String uid,
    required String vehicleId,
  });

  Future<ServiceRecord> createServiceRecord({
    required String uid,
    required String vehicleId,
    required ServiceRecord record,
  });

  Future<void> updateServiceRecord({
    required String uid,
    required String vehicleId,
    required ServiceRecord record,
  });

  Future<void> deleteServiceRecord({
    required String uid,
    required String vehicleId,
    required String recordId,
  });
}
