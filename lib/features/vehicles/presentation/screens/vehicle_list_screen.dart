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
    final archivedValue = ref.watch(archivedVehiclesProvider);
    final activeVehicleValue = ref.watch(activeVehicleProvider);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Scaffold(
      appBar: AppBar(title: const Text('Kendaraan')),
      body: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: vehiclesValue.when(
          loading: () => const Center(
            key: ValueKey('vehicle-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => ErrorState(
            key: const ValueKey('vehicle-error'),
            message: 'Daftar kendaraan belum dapat dimuat.',
            onRetry: () => ref.invalidate(vehiclesProvider),
          ),
          data: (vehicles) {
            final archived = archivedValue.value ?? const <Vehicle>[];
            if (vehicles.isEmpty &&
                archived.isEmpty &&
                !archivedValue.isLoading) {
              return EmptyState(
                key: const ValueKey('vehicle-empty'),
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
              key: const ValueKey('vehicle-list'),
              onRefresh: () async {
                ref.invalidate(vehiclesProvider);
                ref.invalidate(archivedVehiclesProvider);
                await Future.wait([
                  ref.read(vehiclesProvider.future),
                  ref.read(archivedVehiclesProvider.future),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  if (vehicles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Tidak ada kendaraan aktif.'),
                    ),
                  for (final vehicle in vehicles) ...[
                    VehicleCard(
                      vehicle: vehicle,
                      isActive: activeVehicleValue.value?.id == vehicle.id,
                      isSelecting: activeVehicleValue.isLoading,
                      onTap: () => _openDetail(context, vehicle),
                      onSelect: () => _selectVehicle(context, ref, vehicle),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (archivedValue.isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  if (archived.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Kendaraan diarsipkan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final vehicle in archived) ...[
                      VehicleCard(
                        vehicle: vehicle,
                        isActive: false,
                        showSelectAction: false,
                        onTap: () => _openDetail(context, vehicle),
                        onSelect: null,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
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
