import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_repository_provider.dart';

class VehicleActionState {
  const VehicleActionState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;
}

class VehicleController extends Notifier<VehicleActionState> {
  late final VehicleRepository _repository;

  @override
  VehicleActionState build() {
    _repository = ref.watch(vehicleRepositoryProvider);
    return const VehicleActionState();
  }

  Future<Vehicle?> createVehicle(Vehicle vehicle) async {
    if (state.isSubmitting) return null;
    final uid = _currentUid();
    if (uid == null) return null;

    state = const VehicleActionState(isSubmitting: true);
    try {
      final created = await _repository.createVehicle(uid, vehicle);
      state = const VehicleActionState();
      return created;
    } on Object catch (error) {
      state = VehicleActionState(errorMessage: _messageFor(error));
      return null;
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    if (state.isSubmitting) return false;
    final uid = _currentUid();
    if (uid == null) return false;

    state = const VehicleActionState(isSubmitting: true);
    try {
      await _repository.updateVehicle(uid, vehicle);
      state = const VehicleActionState();
      return true;
    } on Object catch (error) {
      state = VehicleActionState(errorMessage: _messageFor(error));
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    if (state.isSubmitting) return false;
    final uid = _currentUid();
    if (uid == null) return false;

    state = const VehicleActionState(isSubmitting: true);
    try {
      final reminderIds = await _repository.reminderIdsForVehicle(
        uid,
        vehicleId,
      );
      await ref.read(vehicleReminderCancellerProvider).cancelAll(reminderIds);
      await _repository.deleteCascade(uid, vehicleId);
      state = const VehicleActionState();
      return true;
    } on Object catch (error) {
      state = VehicleActionState(errorMessage: _messageFor(error));
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) state = const VehicleActionState();
  }

  String? _currentUid() {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || uid.isEmpty) {
      state = const VehicleActionState(
        errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      );
      return null;
    }
    return uid;
  }

  String _messageFor(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Anda tidak memiliki izin untuk mengubah kendaraan ini.',
        'not-found' => 'Data kendaraan tidak ditemukan.',
        'unavailable' || 'deadline-exceeded' =>
          'Layanan sedang tidak tersedia. Silakan coba lagi.',
        _ => 'Data kendaraan belum dapat disimpan. Silakan coba lagi.',
      };
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
