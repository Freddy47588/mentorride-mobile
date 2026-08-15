import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
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
      appBar: AppBar(title: const Text('Riwayat Servis')),
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
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(plateNumber, style: Theme.of(context).textTheme.bodySmall),
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
        message: error.toString(),
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
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ServiceRecordCard(record: items[index]),
                ),
        );
      },
    );
  }
}

class _ServiceRecordCard extends StatelessWidget {
  const _ServiceRecordCard({required this.record});

  final ServiceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/history/${record.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(record.serviceDate.day.toString())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.date(record.serviceDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.workshop.isEmpty
                          ? 'Bengkel tidak dicatat'
                          : record.workshop,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${record.items.length} item • ${AppFormatters.kilometer(record.odometer)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.rupiah(record.totalCost),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
