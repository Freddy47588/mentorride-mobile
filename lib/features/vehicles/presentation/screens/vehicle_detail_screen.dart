import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_form_screen.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({
    required this.vehicleId,
    this.onEditVehicle,
    this.onDeleted,
    super.key,
  });

  final String vehicleId;
  final ValueChanged<Vehicle>? onEditVehicle;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleValue = ref.watch(vehicleDetailProvider(vehicleId));
    final actionState = ref.watch(vehicleControllerProvider);

    return vehicleValue.when(
      loading: () => const Scaffold(
        appBar: _DetailAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _DetailAppBar(),
        body: ErrorState(
          message: 'Detail kendaraan belum dapat dimuat.',
          onRetry: () => ref.invalidate(vehicleDetailProvider(vehicleId)),
        ),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return Scaffold(
            appBar: const _DetailAppBar(),
            body: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Kendaraan tidak ditemukan',
              message: 'Data mungkin telah dihapus dari perangkat lain.',
              actionLabel: 'Kembali',
              onAction: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        final activeVehicle = ref.watch(activeVehicleProvider);
        final isActive = activeVehicle.value?.id == vehicle.id;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail kendaraan'),
            actions: [
              IconButton(
                tooltip: 'Edit kendaraan',
                onPressed: actionState.isSubmitting
                    ? null
                    : () => _openEdit(context, vehicle),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus kendaraan',
                onPressed: actionState.isSubmitting
                    ? null
                    : () => _confirmDelete(context, ref, vehicle),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              _VehicleHeader(vehicle: vehicle, isActive: isActive),
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Informasi kendaraan',
                children: [
                  _DetailRow(
                    icon: Icons.factory_outlined,
                    label: 'Merek',
                    value: vehicle.brand,
                  ),
                  _DetailRow(
                    icon: Icons.two_wheeler_outlined,
                    label: 'Model',
                    value: vehicle.model,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tahun',
                    value: vehicle.year.toString(),
                  ),
                  _DetailRow(
                    icon: Icons.pin_outlined,
                    label: 'Nomor polisi',
                    value: vehicle.plateNumber,
                  ),
                  _DetailRow(
                    icon: Icons.speed_rounded,
                    label: 'Kilometer saat ini',
                    value: AppFormatters.kilometer(vehicle.currentOdometer),
                    isLast: true,
                  ),
                ],
              ),
              if (vehicle.updatedAt case final updatedAt?) ...[
                const SizedBox(height: 12),
                Text(
                  'Terakhir diperbarui ${AppFormatters.date(updatedAt)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              if (!isActive)
                FilledButton.icon(
                  onPressed: activeVehicle.isLoading
                      ? null
                      : () => _selectVehicle(context, ref, vehicle),
                  icon: activeVehicle.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Jadikan kendaraan aktif'),
                )
              else
                const _ActiveNotice(),
              if (actionState.isSubmitting) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (actionState.errorMessage case final message?) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context, Vehicle vehicle) {
    if (onEditVehicle case final callback?) {
      callback(vehicle);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleFormScreen(initialVehicle: vehicle),
      ),
    );
  }

  Future<void> _selectVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final success = await ref
        .read(activeVehicleProvider.notifier)
        .selectVehicle(vehicle.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${vehicle.name} kini menjadi kendaraan aktif.'
                : 'Kendaraan aktif belum dapat diubah.',
          ),
        ),
      );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kendaraan?'),
        content: Text(
          'Semua riwayat servis, jadwal, dan pengingat untuk '
          '${vehicle.name} juga akan dihapus. Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(vehicleControllerProvider.notifier)
        .deleteVehicle(vehicle.id);
    if (!context.mounted) return;

    if (deleted) {
      if (onDeleted case final callback?) {
        callback();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }

    final message = ref.read(vehicleControllerProvider).errorMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message ?? 'Kendaraan belum dapat dihapus.')),
      );
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Detail kendaraan'));
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle, required this.isActive});

  final Vehicle vehicle;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              size: 58,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${vehicle.brand} ${vehicle.model}',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Kendaraan aktif'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
          trailing: Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _ActiveNotice extends StatelessWidget {
  const _ActiveNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Kendaraan ini sedang aktif',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
