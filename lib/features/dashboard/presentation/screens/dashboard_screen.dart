import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:mentorride/features/dashboard/presentation/widgets/monthly_expense_chart.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({this.now, super.key});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: 'Kelola kendaraan',
            onPressed: () => context.push('/vehicles'),
            icon: const Icon(Icons.two_wheeler_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: activeVehicle.when(
        loading: () => const _DashboardLoading(),
        error: (error, stackTrace) => ErrorState(
          message: 'Kendaraan aktif belum dapat dimuat.',
          onRetry: () => ref.invalidate(activeVehicleProvider),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return _NoVehicleDashboard(onRefresh: () => _refreshVehicle(ref));
          }
          return _DashboardData(vehicle: vehicle, now: now ?? DateTime.now());
        },
      ),
    );
  }

  Future<void> _refreshVehicle(WidgetRef ref) async {
    ref.invalidate(activeVehicleProvider);
    await ref.read(activeVehicleProvider.future);
  }
}

class _DashboardData extends ConsumerWidget {
  const _DashboardData({required this.vehicle, required this.now});

  final Vehicle vehicle;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsValue = ref.watch(serviceRecordsProvider);
    final schedulesValue = ref.watch(serviceSchedulesProvider);

    return recordsValue.when(
      loading: () => const _DashboardLoading(),
      error: (error, stackTrace) => ErrorState(
        message: 'Ringkasan riwayat servis belum dapat dimuat.',
        onRetry: () => ref.invalidate(serviceRecordsProvider),
      ),
      data: (records) {
        return schedulesValue.when(
          loading: () => const _DashboardLoading(),
          error: (error, stackTrace) => ErrorState(
            message: 'Ringkasan jadwal servis belum dapat dimuat.',
            onRetry: () => ref.invalidate(serviceSchedulesProvider),
          ),
          data: (schedules) {
            final summary = DashboardAggregator.aggregate(
              activeVehicle: vehicle,
              serviceRecords: records,
              serviceSchedules: schedules,
              now: now,
            );
            return _DashboardContent(
              summary: summary,
              now: now,
              onRefresh: () => _refreshDashboard(ref),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshDashboard(WidgetRef ref) async {
    ref.invalidate(serviceRecordsProvider);
    ref.invalidate(serviceSchedulesProvider);
    await Future.wait([
      ref.read(serviceRecordsProvider.future),
      ref.read(serviceSchedulesProvider.future),
    ]);
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.now,
    required this.onRefresh,
  });

  final DashboardSummary summary;
  final DateTime now;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final vehicle = summary.activeVehicle!;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Motor terawat, perjalanan lebih tenang.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ActiveVehicleCard(vehicle: vehicle),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Aksi cepat'),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Perawatan terkini'),
          const SizedBox(height: 12),
          _MaintenanceCards(
            latestService: summary.latestService,
            nearestSchedule: summary.nearestPendingSchedule,
            now: now,
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Biaya perawatan'),
          const SizedBox(height: 12),
          _ExpenseOverview(summary: summary, now: now),
          const SizedBox(height: 12),
          _ChartCard(expenses: summary.monthlyExpenses),
        ],
      ),
    );
  }
}

class _NoVehicleDashboard extends StatelessWidget {
  const _NoVehicleDashboard({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.two_wheeler_rounded,
                            size: 46,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tambahkan kendaraan pertama',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Data servis, biaya, dan pengingat akan dirangkum di beranda setelah kendaraan tersedia.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/vehicles/new'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah kendaraan'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/vehicles'),
                            icon: const Icon(Icons.list_alt_rounded),
                            label: const Text('Lihat daftar kendaraan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ActiveVehicleCard extends StatelessWidget {
  const _ActiveVehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colorScheme.primary, const Color(0xFF174EA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kendaraan aktif',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${vehicle.brand} ${vehicle.model} • ${vehicle.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Kelola kendaraan',
                onPressed: () => context.push('/vehicles'),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kilometer saat ini',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Text(
                  AppFormatters.kilometer(vehicle.currentOdometer),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 350;
        final itemWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _QuickActionCard(
                icon: Icons.build_circle_outlined,
                label: 'Tambah servis',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/history/new'),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickActionCard(
                icon: Icons.event_available_outlined,
                label: 'Tambah jadwal',
                color: const Color(0xFF0D9488),
                onTap: () => context.push('/schedules/new'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCards extends StatelessWidget {
  const _MaintenanceCards({
    required this.latestService,
    required this.nearestSchedule,
    required this.now,
  });

  final ServiceRecord? latestService;
  final ServiceSchedule? nearestSchedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 620;
        final cards = [
          _LatestServiceCard(record: latestService),
          _NearestScheduleCard(schedule: nearestSchedule, now: now),
        ];
        if (!twoColumns) {
          return Column(
            children: [cards.first, const SizedBox(height: 12), cards.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _LatestServiceCard extends StatelessWidget {
  const _LatestServiceCard({required this.record});

  final ServiceRecord? record;

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.history_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'Servis terakhir',
      child: record == null
          ? const _MissingInformation(
              message: 'Belum ada riwayat servis untuk kendaraan ini.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.date(record!.serviceDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record!.workshop.isEmpty
                      ? 'Lokasi bengkel tidak dicatat'
                      : record!.workshop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _InlineDetail(
                  icon: Icons.speed_rounded,
                  text: AppFormatters.kilometer(record!.odometer),
                ),
                const SizedBox(height: 5),
                _InlineDetail(
                  icon: Icons.payments_outlined,
                  text: AppFormatters.rupiah(record!.totalCost),
                ),
              ],
            ),
    );
  }
}

class _NearestScheduleCard extends StatelessWidget {
  const _NearestScheduleCard({required this.schedule, required this.now});

  final ServiceSchedule? schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final timing = schedule == null
        ? null
        : _ScheduleTiming.from(schedule!.dueDate, now);

    return _InformationCard(
      icon: Icons.event_note_rounded,
      iconColor: const Color(0xFF0D9488),
      title: 'Jadwal terdekat',
      child: schedule == null
          ? const _MissingInformation(
              message: 'Belum ada jadwal servis yang perlu diselesaikan.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppFormatters.date(schedule!.dueDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 9),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: timing!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      timing.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: timing.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (schedule!.dueOdometer case final odometer?) ...[
                  const SizedBox(height: 9),
                  _InlineDetail(
                    icon: Icons.speed_rounded,
                    text: AppFormatters.kilometer(odometer),
                  ),
                ],
              ],
            ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}

class _MissingInformation extends StatelessWidget {
  const _MissingInformation({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InlineDetail extends StatelessWidget {
  const _InlineDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ExpenseOverview extends StatelessWidget {
  const _ExpenseOverview({required this.summary, required this.now});

  final DashboardSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 350;
        final itemWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _ExpenseCard(
                label: 'Bulan ini',
                period: AppFormatters.monthYear(now),
                amount: summary.currentMonthExpense,
                icon: Icons.calendar_view_month_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ExpenseCard(
                label: 'Tahun ini',
                period: now.year.toString(),
                amount: summary.currentYearExpense,
                icon: Icons.date_range_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.label,
    required this.period,
    required this.amount,
    required this.icon,
  });

  final String label;
  final String period;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppFormatters.rupiah(amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              period,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.expenses});

  final List<MonthlyExpense> expenses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren enam bulan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              'Total biaya servis per bulan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            MonthlyExpenseChart(expenses: expenses),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ScheduleTiming {
  const _ScheduleTiming({required this.label, required this.color});

  final String label;
  final Color color;

  factory _ScheduleTiming.from(DateTime dueDate, DateTime now) {
    final localDueDate = dueDate.toLocal();
    final localNow = now.toLocal();
    final dueDay = DateTime(
      localDueDate.year,
      localDueDate.month,
      localDueDate.day,
    );
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final days = dueDay.difference(today).inDays;
    if (days < 0) {
      return _ScheduleTiming(
        label: 'Terlambat ${-days} hari',
        color: const Color(0xFFDC2626),
      );
    }
    if (days == 0) {
      return const _ScheduleTiming(
        label: 'Jatuh tempo hari ini',
        color: Color(0xFFD97706),
      );
    }
    return _ScheduleTiming(
      label: '$days hari lagi',
      color: const Color(0xFF0D9488),
    );
  }
}
