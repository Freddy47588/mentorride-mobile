import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_records/presentation/widgets/service_record_timeline_tile.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class ServiceRecordListScreen extends ConsumerWidget {
  const ServiceRecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat servis')),
      body: activeVehicle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: 'Kendaraan aktif belum dapat dimuat.',
          onRetry: () => ref.invalidate(activeVehicleProvider),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return const EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Pilih kendaraan dahulu',
              message:
                  'Tambahkan atau pilih kendaraan untuk melihat riwayat servis.',
            );
          }

          return Column(
            children: [
              _ActiveVehicleHeader(
                name: vehicle.name,
                plateNumber: vehicle.plateNumber,
              ),
              const _FilterBar(),
              Expanded(
                child: _ServiceRecordList(
                  onAdd: () => context.push('/history/new'),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: activeVehicle.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/history/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah servis'),
            ),
    );
  }
}

class _ActiveVehicleHeader extends StatelessWidget {
  const _ActiveVehicleHeader({required this.name, required this.plateNumber});

  final String name;
  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.two_wheeler_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  plateNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(serviceRecordFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  type: ServiceRecordFilterType.all,
                  selectedType: filter.type,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bulan',
                  type: ServiceRecordFilterType.month,
                  selectedType: filter.type,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tahun',
                  type: ServiceRecordFilterType.year,
                  selectedType: filter.type,
                ),
              ],
            ),
          ),
          if (filter.type != ServiceRecordFilterType.all) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickAnchor(context, ref, filter.anchor),
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                filter.type == ServiceRecordFilterType.month
                    ? AppFormatters.monthYear(filter.anchor)
                    : filter.anchor.year.toString(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAnchor(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
  ) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Pilih periode servis',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !context.mounted) return;
    ref.read(serviceRecordFilterProvider.notifier).selectAnchor(selected);
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip({
    required this.label,
    required this.type,
    required this.selectedType,
  });

  final String label;
  final ServiceRecordFilterType type;
  final ServiceRecordFilterType selectedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(label),
      selected: type == selectedType,
      onSelected: (_) {
        ref.read(serviceRecordFilterProvider.notifier).selectType(type);
      },
    );
  }
}

class _ServiceRecordList extends ConsumerWidget {
  const _ServiceRecordList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredServiceRecordsProvider);
    final filter = ref.watch(serviceRecordFilterProvider);

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorState(
        message: 'Riwayat servis belum dapat dimuat.',
        onRetry: () => ref.invalidate(serviceRecordsProvider),
      ),
      data: (items) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRecordsProvider);
            await ref.read(serviceRecordsProvider.future);
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.48,
                      child: EmptyState(
                        icon: Icons.build_circle_outlined,
                        title: filter.type == ServiceRecordFilterType.all
                            ? 'Belum ada riwayat servis'
                            : 'Tidak ada servis di periode ini',
                        message: filter.type == ServiceRecordFilterType.all
                            ? 'Catat servis pertama agar perawatan kendaraan lebih terpantau.'
                            : 'Pilih periode lain atau tampilkan semua riwayat.',
                        actionLabel: filter.type == ServiceRecordFilterType.all
                            ? 'Tambah servis'
                            : 'Tampilkan semua',
                        onAction: filter.type == ServiceRecordFilterType.all
                            ? onAdd
                            : () => ref
                                  .read(serviceRecordFilterProvider.notifier)
                                  .selectType(ServiceRecordFilterType.all),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) => ServiceRecordTimelineTile(
                    record: items[index],
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                    onTap: () => context.push('/history/${items[index].id}'),
                  ),
                ),
        );
      },
    );
  }
}
