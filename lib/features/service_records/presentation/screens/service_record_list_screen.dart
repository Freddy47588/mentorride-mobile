import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_records/domain/models/maintenance_statistics.dart';
import 'package:mentorride/features/service_records/presentation/widgets/service_record_timeline_tile.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/presentation/controllers/service_report_controller.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class ServiceRecordListScreen extends ConsumerStatefulWidget {
  const ServiceRecordListScreen({super.key});

  @override
  ConsumerState<ServiceRecordListScreen> createState() =>
      _ServiceRecordListScreenState();
}

class _ServiceRecordListScreenState
    extends ConsumerState<ServiceRecordListScreen> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(serviceRecordFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final exportState = ref.watch(serviceReportControllerProvider);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat servis'),
        actions: [
          if (activeVehicle.value != null)
            AnimatedSwitcher(
              duration: duration,
              child: exportState.isExporting
                  ? const Padding(
                      key: ValueKey('report-export-loading'),
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : IconButton(
                      key: const ValueKey('report-export-action'),
                      tooltip: 'Ekspor laporan',
                      onPressed: _chooseReportFormat,
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: activeVehicle.when(
          loading: () => const Center(
            key: ValueKey('history-vehicle-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => ErrorState(
            key: const ValueKey('history-vehicle-error'),
            message: 'Kendaraan aktif belum dapat dimuat.',
            onRetry: () => ref.invalidate(activeVehicleProvider),
          ),
          data: (vehicle) {
            if (vehicle == null) {
              return const EmptyState(
                key: ValueKey('history-no-vehicle'),
                icon: Icons.two_wheeler_rounded,
                title: 'Pilih kendaraan dahulu',
                message:
                    'Tambahkan atau pilih kendaraan untuk melihat riwayat servis.',
              );
            }

            return _HistoryContent(
              key: ValueKey(vehicle.id),
              vehicle: vehicle,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onClearSearch: _clearSearch,
              onEditCostRange: _editCostRange,
              onResetFilters: _resetFilters,
              onAdd: () => context.push('/history/new'),
            );
          },
        ),
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(serviceRecordFilterProvider.notifier).updateQuery(query);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(serviceRecordFilterProvider.notifier).updateQuery('');
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(serviceRecordFilterProvider.notifier).reset();
  }

  Future<void> _editCostRange() async {
    final filter = ref.read(serviceRecordFilterProvider);
    final selection = await showModalBottomSheet<_CostRangeSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CostRangeSheet(filter: filter),
    );
    if (selection == null || !mounted) return;

    final controller = ref.read(serviceRecordFilterProvider.notifier);
    if (selection.shouldClear) {
      controller.clearCostRange();
      return;
    }
    controller.updateCostRange(
      minimumCost: selection.minimum,
      maximumCost: selection.maximum,
    );
  }

  Future<void> _chooseReportFormat() async {
    final format = await showModalBottomSheet<ServiceReportFormat>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  'Ekspor laporan',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Dokumen PDF'),
                subtitle: const Text('Laporan A4 yang siap dibagikan'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ServiceReportFormat.pdf),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Data CSV'),
                subtitle: const Text('Data UTF-8 yang dapat dibuka di Excel'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ServiceReportFormat.csv),
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !mounted) return;

    final result = await ref
        .read(serviceReportControllerProvider.notifier)
        .exportActiveVehicle(format);
    if (!mounted) return;

    final exportState = ref.read(serviceReportControllerProvider);
    final message = result != null
        ? 'Laporan ${format.label} berhasil dibuat.'
        : exportState.errorMessage ?? 'Laporan belum dapat diekspor.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    ref.read(serviceReportControllerProvider.notifier).clearFeedback();
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({
    required this.vehicle,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onEditCostRange,
    required this.onResetFilters,
    required this.onAdd,
    super.key,
  });

  final Vehicle vehicle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onEditCostRange;
  final VoidCallback onResetFilters;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredServiceRecordsProvider);
    final statistics = ref.watch(filteredMaintenanceStatisticsProvider);
    final filter = ref.watch(serviceRecordFilterProvider);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    if (records.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.hasError) {
      return ErrorState(
        message: 'Riwayat servis belum dapat dimuat.',
        onRetry: () => ref.invalidate(serviceRecordsProvider),
      );
    }

    final items = records.value ?? const [];
    final statisticValue =
        statistics.value ??
        const MaintenanceStatistics(
          totalCost: 0,
          averageCostPerService: 0,
          serviceCount: 0,
          components: [],
        );

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: RefreshIndicator(
        key: ValueKey(items.isEmpty ? 'history-empty' : 'history-list'),
        onRefresh: () async {
          ref.invalidate(serviceRecordsProvider);
          await ref.read(serviceRecordsProvider.future);
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ActiveVehicleHeader(
                name: vehicle.name,
                plateNumber: vehicle.plateNumber,
              ),
            ),
            SliverToBoxAdapter(
              child: _MaintenanceStatisticsPanel(
                statistics: statisticValue,
                isFiltered: filter.hasActiveFilter,
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterBar(
                filter: filter,
                searchController: searchController,
                onSearchChanged: onSearchChanged,
                onClearSearch: onClearSearch,
                onEditCostRange: onEditCostRange,
                onResetFilters: onResetFilters,
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: filter.hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.build_circle_outlined,
                  title: filter.hasActiveFilter
                      ? 'Riwayat tidak ditemukan'
                      : 'Belum ada riwayat servis',
                  message: filter.hasActiveFilter
                      ? 'Ubah kata kunci atau filter untuk melihat hasil lain.'
                      : 'Catat servis pertama agar perawatan kendaraan lebih terpantau.',
                  actionLabel: filter.hasActiveFilter
                      ? 'Hapus semua filter'
                      : 'Tambah servis',
                  onAction: filter.hasActiveFilter ? onResetFilters : onAdd,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => ServiceRecordTimelineTile(
                    record: items[index],
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                    onTap: () => context.push('/history/${items[index].id}'),
                  ),
                ),
              ),
          ],
        ),
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

class _MaintenanceStatisticsPanel extends StatelessWidget {
  const _MaintenanceStatisticsPanel({
    required this.statistics,
    required this.isFiltered,
  });

  final MaintenanceStatistics statistics;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topComponent = statistics.mostFrequentComponent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFiltered ? 'Ringkasan hasil' : 'Statistik perawatan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  _StatisticValue(
                    width: itemWidth,
                    label: 'Total biaya',
                    value: AppFormatters.rupiah(statistics.totalCost),
                  ),
                  _StatisticValue(
                    width: itemWidth,
                    label: 'Rata-rata / servis',
                    value: AppFormatters.rupiah(
                      statistics.averageCostPerService,
                    ),
                  ),
                  _StatisticValue(
                    width: itemWidth,
                    label: 'Jumlah servis',
                    value: '${statistics.serviceCount}',
                  ),
                  _StatisticValue(
                    width: itemWidth,
                    label: 'Paling sering dirawat',
                    value: topComponent == null
                        ? '-'
                        : '${topComponent.name} (${topComponent.occurrenceCount}×)',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatisticValue extends StatelessWidget {
  const _StatisticValue({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: duration,
            child: Text(
              value,
              key: ValueKey(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.filter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onEditCostRange,
    required this.onResetFilters,
  });

  final ServiceRecordFilter filter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onEditCostRange;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, searchValue, child) => TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Cari riwayat',
                hintText: 'Bengkel, komponen, atau catatan',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchValue.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                const SizedBox(width: 8),
                FilterChip(
                  selected: filter.hasCostRange,
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(_costRangeLabel(filter)),
                  onSelected: (_) => onEditCostRange(),
                ),
                if (filter.hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Reset'),
                    onPressed: onResetFilters,
                  ),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: filter.type == ServiceRecordFilterType.all
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAnchor(context, ref, filter.anchor),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        filter.type == ServiceRecordFilterType.month
                            ? AppFormatters.monthYear(filter.anchor)
                            : filter.anchor.year.toString(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _costRangeLabel(ServiceRecordFilter filter) {
    if (!filter.hasCostRange) return 'Biaya';
    final minimum = filter.minimumCost;
    final maximum = filter.maximumCost;
    if (minimum != null && maximum != null) {
      return '${AppFormatters.rupiah(minimum)}–${AppFormatters.rupiah(maximum)}';
    }
    if (minimum != null) return 'Mulai ${AppFormatters.rupiah(minimum)}';
    return 'Maks. ${AppFormatters.rupiah(maximum!)}';
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

class _CostRangeSheet extends StatefulWidget {
  const _CostRangeSheet({required this.filter});

  final ServiceRecordFilter filter;

  @override
  State<_CostRangeSheet> createState() => _CostRangeSheetState();
}

class _CostRangeSheetState extends State<_CostRangeSheet> {
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _minimumController = TextEditingController(
      text: widget.filter.minimumCost?.toString() ?? '',
    );
    _maximumController = TextEditingController(
      text: widget.filter.maximumCost?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rentang biaya',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Filter memakai total biaya setiap transaksi servis.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _minimumController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Biaya minimum',
                  prefixText: 'Rp',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maximumController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Biaya maksimum',
                  prefixText: 'Rp',
                ),
                onSubmitted: (_) => _apply(),
              ),
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: _errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 12,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _CostRangeSelection.clear()),
                    child: const Text('Hapus filter'),
                  ),
                  FilledButton(
                    onPressed: _apply,
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply() {
    final minimum = int.tryParse(_minimumController.text);
    final maximum = int.tryParse(_maximumController.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      setState(() {
        _errorMessage = 'Biaya minimum tidak boleh melebihi biaya maksimum.';
      });
      return;
    }
    Navigator.of(
      context,
    ).pop(_CostRangeSelection(minimum: minimum, maximum: maximum));
  }
}

class _CostRangeSelection {
  const _CostRangeSelection({this.minimum, this.maximum}) : shouldClear = false;

  const _CostRangeSelection.clear()
    : minimum = null,
      maximum = null,
      shouldClear = true;

  final int? minimum;
  final int? maximum;
  final bool shouldClear;
}
