import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:uuid/uuid.dart';

class FirestoreVehicleRepository implements VehicleRepository {
  FirestoreVehicleRepository({
    required FirebaseFirestore firestore,
    Uuid uuid = const Uuid(),
  }) : this._(firestore, uuid);

  FirestoreVehicleRepository._(this._firestore, this._uuid);

  static const int _batchSize = 400;

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> _vehicles(String uid) {
    return _firestore.collection('users').doc(uid).collection('vehicles');
  }

  DocumentReference<Map<String, dynamic>> _vehicle(
    String uid,
    String vehicleId,
  ) {
    return _vehicles(uid).doc(vehicleId);
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String uid) {
    return _vehicles(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_vehicleFromSnapshot).toList());
  }

  @override
  Stream<Vehicle?> watchVehicle(String uid, String vehicleId) {
    return _vehicle(uid, vehicleId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return _vehicleFromSnapshot(snapshot);
    });
  }

  @override
  Future<Vehicle> createVehicle(String uid, Vehicle vehicle) async {
    final id = _uuid.v4();
    final createdVehicle = vehicle.copyWith(id: id);

    await _vehicle(uid, id).set({
      ..._writableFields(createdVehicle),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return createdVehicle;
  }

  @override
  Future<void> updateVehicle(String uid, Vehicle vehicle) async {
    if (vehicle.id.isEmpty) {
      throw ArgumentError.value(vehicle.id, 'vehicle.id', 'ID wajib diisi.');
    }

    final reference = _vehicle(uid, vehicle.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw const AppException('Kendaraan tidak ditemukan.');
      }

      final rawCurrent = snapshot.data()?['currentOdometer'];
      final current = rawCurrent is num
          ? rawCurrent.toInt()
          : int.tryParse(rawCurrent?.toString() ?? '') ?? 0;
      if (vehicle.currentOdometer < current) {
        throw const AppException(
          'Kilometer baru tidak boleh lebih kecil dari kilometer saat ini.',
        );
      }

      transaction.update(reference, {
        ..._writableFields(vehicle),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<VehicleOdometerUpdateResult> updateOdometer({
    required String uid,
    required String vehicleId,
    required int odometer,
  }) {
    if (vehicleId.isEmpty) {
      throw const AppException('Kendaraan tidak valid.');
    }
    if (odometer < 0) {
      throw const AppException('Kilometer tidak boleh bernilai negatif.');
    }

    final reference = _vehicle(uid, vehicleId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw const AppException('Kendaraan tidak ditemukan.');
      }

      final rawCurrent = snapshot.data()?['currentOdometer'];
      final current = rawCurrent is num
          ? rawCurrent.toInt()
          : int.tryParse(rawCurrent?.toString() ?? '') ?? 0;
      if (odometer < current) {
        throw const AppException(
          'Kilometer baru tidak boleh lebih kecil dari kilometer saat ini.',
        );
      }
      if (odometer == current) {
        return VehicleOdometerUpdateResult.unchanged;
      }

      transaction.update(reference, {
        'currentOdometer': odometer,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return VehicleOdometerUpdateResult.updated;
    });
  }

  @override
  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId) async {
    final schedules = _vehicle(uid, vehicleId).collection('service_schedules');
    final reminderIds = <int>{};
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = schedules
          .orderBy(FieldPath.documentId)
          .limit(_batchSize);
      if (cursor != null) query = query.startAfterDocument(cursor);

      final snapshot = await query.get();
      for (final document in snapshot.docs) {
        final value = document.data()['localNotificationId'];
        if (value is int) {
          reminderIds.add(value);
        } else if (value is num) {
          reminderIds.add(value.toInt());
        }
      }

      if (snapshot.docs.length < _batchSize) break;
      cursor = snapshot.docs.last;
    }

    return reminderIds.toList(growable: false);
  }

  @override
  Future<void> deleteCascade(String uid, String vehicleId) async {
    final vehicle = _vehicle(uid, vehicleId);

    await _deleteCollectionInChunks(vehicle.collection('service_records'));
    await _deleteCollectionInChunks(vehicle.collection('service_schedules'));
    await vehicle.delete();
  }

  Future<void> _deleteCollectionInChunks(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(_batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  Vehicle _vehicleFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Vehicle.fromMap({
      ...data,
      'id': snapshot.id,
      'createdAt': _dateTimeFromTimestamp(data['createdAt']),
      'updatedAt': _dateTimeFromTimestamp(data['updatedAt']),
    });
  }

  Map<String, Object?> _writableFields(Vehicle vehicle) {
    return {
      'name': vehicle.name.trim(),
      'brand': vehicle.brand.trim(),
      'model': vehicle.model.trim(),
      'year': vehicle.year,
      'plateNumber': vehicle.plateNumber.trim().toUpperCase(),
      'currentOdometer': vehicle.currentOdometer,
    };
  }

  DateTime? _dateTimeFromTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
