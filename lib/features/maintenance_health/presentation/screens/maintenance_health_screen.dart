import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_health.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_health_calculator.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_insights_calculator.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class MaintenanceHealthScreen extends ConsumerWidget {
  const MaintenanceHealthScreen({this.now, super.key});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProvider);
    final records = ref.watch(serviceRecordsProvider);
    final schedules = ref.watch(serviceSchedulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kondisi Perawatan')),
      body: vehicle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: 'Kendaraan aktif belum dapat dimuat.',
          onRetry: () => ref.invalidate(activeVehicleProvider),
        ),
        data: (value) {
          if (value == null) {
            return const EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Belum ada kendaraan aktif',
              message: 'Pilih kendaraan untuk melihat kondisi perawatannya.',
            );
          }
          if (records.isLoading || schedules.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (records.hasError || schedules.hasError) {
            return ErrorState(
              message: 'Kondisi perawatan belum dapat dihitung.',
              onRetry: () {
                ref.invalidate(serviceRecordsProvider);
                ref.invalidate(serviceSchedulesProvider);
              },
            );
          }
          final summary = MaintenanceHealthCalculator.calculate(
            records: records.value ?? const [],
            schedules: schedules.value ?? const [],
            currentOdometer: value.currentOdometer,
            now: now ?? DateTime.now(),
          );
          final insights = MaintenanceInsightsCalculator.calculate(
            records: records.value ?? const [],
            now: now ?? DateTime.now(),
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serviceRecordsProvider);
              ref.invalidate(serviceSchedulesProvider);
              await Future.wait([
                ref.read(serviceRecordsProvider.future),
                ref.read(serviceSchedulesProvider.future),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SummaryCard(summary: summary),
                if (insights.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insight perawatan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          for (final insight in insights)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(insight.label),
                              trailing: SizedBox(
                                width: 130,
                                child: Text(
                                  insight.value,
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Estimasi berdasarkan interval perawatan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in summary.items) ...[
                  _HealthItemCard(item: item),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final MaintenanceHealthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.percentage == null
                  ? 'Kondisi perawatan belum tersedia'
                  : 'Kondisi perawatan ${summary.percentage}%',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dihitung dari catatan dan jadwal yang Anda masukkan, bukan '
              'diagnosis kondisi mesin.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthItemCard extends StatelessWidget {
  const _HealthItemCard({required this.item});

  final MaintenanceHealthItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, item.status);
    final estimate = item.estimate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.preset.componentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.description),
            if (estimate != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (estimate.dueOdometer case final value?)
                    Text(
                      'Estimasi ${AppFormatters.kilometer(value)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (estimate.dueDate case final value?)
                    Text(
                      'Estimasi ${AppFormatters.date(value)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, MaintenanceHealthStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    MaintenanceHealthStatus.safe => scheme.secondary,
    MaintenanceHealthStatus.approaching => Colors.orange.shade700,
    MaintenanceHealthStatus.due => Colors.deepOrange,
    MaintenanceHealthStatus.overdue => scheme.error,
    MaintenanceHealthStatus.noData => scheme.outline,
  };
}
