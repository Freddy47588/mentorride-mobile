import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_form_screen.dart';
import 'package:mentorride/features/vehicles/presentation/widgets/vehicle_card.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({this.onAddVehicle, this.onOpenVehicle, super.key});

  final VoidCallback? onAddVehicle;
  final ValueChanged<String>? onOpenVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesValue = ref.watch(vehiclesProvider);
    final activeVehicleValue = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kendaraan')),
      body: vehiclesValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: 'Daftar kendaraan belum dapat dimuat.',
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Belum ada kendaraan',
              message:
                  'Tambahkan sepeda motor untuk mulai mencatat servis dan '
                  'jadwal perawatan.',
              actionLabel: 'Tambah kendaraan',
              onAction: () => _openAddForm(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehiclesProvider);
              await ref.read(vehiclesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: vehicles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isActive = activeVehicleValue.value?.id == vehicle.id;
                return VehicleCard(
                  vehicle: vehicle,
                  isActive: isActive,
                  isSelecting: activeVehicleValue.isLoading,
                  onTap: () => _openDetail(context, vehicle),
                  onSelect: () => _selectVehicle(context, ref, vehicle),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddForm(context),
        tooltip: 'Tambah kendaraan',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openAddForm(BuildContext context) {
    if (onAddVehicle case final callback?) {
      callback();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const VehicleFormScreen()));
  }

  void _openDetail(BuildContext context, Vehicle vehicle) {
    if (onOpenVehicle case final callback?) {
      callback(vehicle.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id),
      ),
    );
  }

  Future<void> _selectVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final selected = await ref
        .read(activeVehicleProvider.notifier)
        .selectVehicle(vehicle.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            selected
                ? '${vehicle.name} dipilih sebagai kendaraan aktif.'
                : 'Kendaraan aktif belum dapat diubah.',
          ),
        ),
      );
  }
}
