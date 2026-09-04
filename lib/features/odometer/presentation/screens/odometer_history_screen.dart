import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_period.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_statistics.dart';
import 'package:mentorride/features/odometer/domain/services/odometer_statistics_calculator.dart';
import 'package:mentorride/features/odometer/providers/odometer_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class OdometerHistoryScreen extends ConsumerWidget {
  const OdometerHistoryScreen({this.now, super.key});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProvider).value;
    final logsValue = ref.watch(odometerLogsProvider);
    final period = ref.watch(odometerPeriodProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Kilometer')),
      body: vehicle == null
          ? const EmptyState(
              icon: Icons.speed_rounded,
              title: 'Belum ada kendaraan aktif',
              message: 'Pilih kendaraan untuk melihat perkembangan kilometer.',
            )
          : logsValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: 'Riwayat kilometer belum dapat dimuat.',
                onRetry: () => ref.invalidate(odometerLogsProvider),
              ),
              data: (allLogs) {
                final referenceNow = now ?? DateTime.now();
                final cutoff = referenceNow.subtract(
                  Duration(days: period.days),
                );
                final ranged = allLogs
                    .where(
                      (log) =>
                          log.recordedAt != null &&
                          !log.recordedAt!.isBefore(cutoff),
                    )
                    .toList(growable: false);
                final shown = ranged.length >= 2 ? ranged : allLogs;
                final statistics = OdometerStatisticsCalculator.calculate(
                  logs: shown,
                  currentOdometer: vehicle.currentOdometer,
                  now: referenceNow,
                  periodDays: period.days,
                );
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(odometerLogsProvider);
                    await ref.read(odometerLogsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<OdometerPeriod>(
                          segments: [
                            for (final value in OdometerPeriod.values)
                              ButtonSegment(
                                value: value,
                                label: Text(value.label),
                              ),
                          ],
                          selected: {period},
                          onSelectionChanged: (selection) {
                            ref
                                .read(odometerPeriodProvider.notifier)
                                .select(selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatisticsCard(statistics: statistics),
                      const SizedBox(height: 12),
                      _OdometerChart(logs: shown),
                      const SizedBox(height: 8),
                      if (ranged.length < 2 && allLogs.length > ranged.length)
                        Text(
                          'Data pada periode ini belum cukup; grafik menampilkan semua data satu tahun.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Catatan kilometer',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (allLogs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Belum ada perubahan kilometer yang dicatat.',
                          ),
                        )
                      else
                        for (final log in allLogs) _LogTile(log: log),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.statistics});

  final OdometerStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            _Metric(
              label: 'Kilometer sekarang',
              value: AppFormatters.kilometer(statistics.currentOdometer),
            ),
            _Metric(
              label: 'Kenaikan periode',
              value: AppFormatters.kilometer(statistics.periodIncrease),
            ),
            if (statistics.averageMonthlyUsage case final int average)
              _Metric(
                label: 'Rata-rata bulanan',
                value: AppFormatters.kilometer(average),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OdometerChart extends StatelessWidget {
  const _OdometerChart({required this.logs});

  final List<OdometerLog> logs;

  @override
  Widget build(BuildContext context) {
    final sorted = logs.where((log) => log.recordedAt != null).toList()
      ..sort((a, b) => a.recordedAt!.compareTo(b.recordedAt!));
    if (sorted.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Minimal dua catatan diperlukan untuk menampilkan grafik.',
          ),
        ),
      );
    }
    final minKm = sorted.map((log) => log.odometer).reduce(math.min).toDouble();
    final maxKm = sorted.map((log) => log.odometer).reduce(math.max).toDouble();
    final padding = math.max(100, ((maxKm - minKm) * 0.15).round()).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 18, 12),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (sorted.length - 1).toDouble(),
              minY: math.max(0, minKm - padding),
              maxY: maxKm + padding,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index != 0 && index != sorted.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          AppFormatters.date(sorted[index].recordedAt!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < sorted.length; index++)
                      FlSpot(
                        index.toDouble(),
                        sorted[index].odometer.toDouble(),
                      ),
                  ],
                  isCurved: false,
                  barWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final OdometerLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.speed_rounded),
      title: Text(AppFormatters.kilometer(log.odometer)),
      subtitle: Text(
        '${log.recordedAt == null ? 'Sedang disimpan' : AppFormatters.date(log.recordedAt!)} · ${log.source.label}',
      ),
    );
  }
}
