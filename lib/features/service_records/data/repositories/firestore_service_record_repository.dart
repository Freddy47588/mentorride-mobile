import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/repositories/service_record_repository.dart';

class FirestoreServiceRecordRepository implements ServiceRecordRepository {
  FirestoreServiceRecordRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ServiceRecord>> watchServiceRecords({
    required String uid,
    required String vehicleId,
  }) {
    return _records(uid, vehicleId)
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_recordFromSnapshot).toList(growable: false),
        )
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(_mapError(error), stackTrace);
        });
  }

  @override
  Future<ServiceRecord> createServiceRecord({
    required String uid,
    required String vehicleId,
    required ServiceRecord record,
  }) async {
    final recordReference = _records(uid, vehicleId).doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final vehicleReference = _vehicle(uid, vehicleId);
        final vehicleSnapshot = await transaction.get(vehicleReference);
        if (!vehicleSnapshot.exists) {
          throw const AppException('Kendaraan aktif tidak ditemukan.');
        }

        transaction.set(recordReference, {
          ..._writableData(record),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _updateVehicleOdometerWhenHigher(
          transaction: transaction,
          vehicleReference: vehicleReference,
          vehicleData: vehicleSnapshot.data(),
          serviceOdometer: record.odometer,
        );
      });
      return record.copyWith(id: recordReference.id);
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> updateServiceRecord({
    required String uid,
    required String vehicleId,
    required ServiceRecord record,
  }) async {
    if (record.id.isEmpty) {
      throw const AppException('Catatan servis tidak valid.');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final vehicleReference = _vehicle(uid, vehicleId);
        final vehicleSnapshot = await transaction.get(vehicleReference);
        if (!vehicleSnapshot.exists) {
          throw const AppException('Kendaraan aktif tidak ditemukan.');
        }

        transaction.update(_records(uid, vehicleId).doc(record.id), {
          ..._writableData(record),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _updateVehicleOdometerWhenHigher(
          transaction: transaction,
          vehicleReference: vehicleReference,
          vehicleData: vehicleSnapshot.data(),
          serviceOdometer: record.odometer,
        );
      });
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> deleteServiceRecord({
    required String uid,
    required String vehicleId,
    required String recordId,
  }) async {
    if (recordId.isEmpty) return;

    try {
      await _records(uid, vehicleId).doc(recordId).delete();
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  CollectionReference<Map<String, dynamic>> _records(
    String uid,
    String vehicleId,
  ) {
    return _vehicle(uid, vehicleId).collection('service_records');
  }

  DocumentReference<Map<String, dynamic>> _vehicle(
    String uid,
    String vehicleId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc(vehicleId);
  }

  ServiceRecord _recordFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return ServiceRecord.fromMap({
      ...data,
      'id': snapshot.id,
      'serviceDate': _dateTimeFromValue(data['serviceDate']),
      'createdAt': _dateTimeFromValue(data['createdAt']),
      'updatedAt': _dateTimeFromValue(data['updatedAt']),
    });
  }

  Map<String, Object?> _writableData(ServiceRecord record) {
    return {
      'serviceDate': Timestamp.fromDate(record.serviceDate),
      'odometer': record.odometer,
      'workshop': record.workshop.trim(),
      'items': record.items.map((item) => item.toMap()).toList(growable: false),
      'totalCost': record.totalCost,
      'notes': record.notes.trim(),
    };
  }

  void _updateVehicleOdometerWhenHigher({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> vehicleReference,
    required Map<String, dynamic>? vehicleData,
    required int serviceOdometer,
  }) {
    final rawCurrentOdometer = vehicleData?['currentOdometer'];
    final currentOdometer = rawCurrentOdometer is num
        ? rawCurrentOdometer.toInt()
        : int.tryParse(rawCurrentOdometer?.toString() ?? '') ?? 0;
    if (serviceOdometer <= currentOdometer) return;

    transaction.update(vehicleReference, {
      'currentOdometer': serviceOdometer,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DateTime? _dateTimeFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  AppException _mapError(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException) {
      final message = switch (error.code) {
        'permission-denied' =>
          'Anda tidak memiliki izin untuk mengakses riwayat servis.',
        'unavailable' || 'deadline-exceeded' =>
          'Riwayat servis belum dapat diakses. Periksa koneksi Anda.',
        'not-found' => 'Catatan servis tidak ditemukan.',
        _ => 'Riwayat servis belum dapat diproses. Silakan coba lagi.',
      };
      return AppException(message, code: error.code);
    }
    return const AppException(
      'Terjadi kesalahan saat memproses riwayat servis.',
    );
  }
}
