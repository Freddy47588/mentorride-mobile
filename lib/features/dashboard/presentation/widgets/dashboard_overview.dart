import 'package:flutter/material.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:mentorride/features/dashboard/presentation/widgets/monthly_expense_chart.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_status_badge.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_health.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({
    required this.summary,
    this.healthSummary = const MaintenanceHealthSummary(items: []),
    required this.now,
    required this.onRefresh,
    required this.onManageVehicles,
    required this.onAddService,
    required this.onAddSchedule,
    required this.onUpdateOdometer,
    this.onViewMaintenanceHealth,
    super.key,
  });

  final DashboardSummary summary;
  final MaintenanceHealthSummary healthSummary;
  final DateTime now;
  final Future<void> Function() onRefresh;
  final VoidCallback onManageVehicles;
  final VoidCallback onAddService;
  final VoidCallback onAddSchedule;
  final VoidCallback onUpdateOdometer;
  final VoidCallback? onViewMaintenanceHealth;

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant DashboardOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.activeVehicle?.id !=
        widget.summary.activeVehicle?.id) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.summary.activeVehicle!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const Key('dashboard-overview'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _DashboardEntrance(
            animation: _animation(0, 0.55, reduceMotion),
            child: _ActiveVehiclePanel(
              vehicle: vehicle,
              onManageVehicles: widget.onManageVehicles,
              onUpdateOdometer: widget.onUpdateOdometer,
            ),
          ),
          const SizedBox(height: 12),
          _DashboardEntrance(
            animation: _animation(0.12, 0.67, reduceMotion),
            child: _QuickActions(
              onAddService: widget.onAddService,
              onAddSchedule: widget.onAddSchedule,
            ),
          ),
          const SizedBox(height: 20),
          _DashboardEntrance(
            animation: _animation(0.25, 0.8, reduceMotion),
            child: _MaintenanceOverview(
              latestService: widget.summary.latestService,
              nearestSchedule: widget.summary.nearestPendingSchedule,
              currentOdometer: vehicle.currentOdometer,
              now: widget.now,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardEntrance(
            animation: _animation(0.38, 1, reduceMotion),
            child: _HealthSummaryCard(
              summary: widget.healthSummary,
              onViewDetail: widget.onViewMaintenanceHealth,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardEntrance(
            animation: _animation(0.48, 1, reduceMotion),
            child: _ExpenseOverview(summary: widget.summary, now: widget.now),
          ),
        ],
      ),
    );
  }

  Animation<double> _animation(double begin, double end, bool reduceMotion) {
    if (reduceMotion) return const AlwaysStoppedAnimation(1);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.summary, required this.onViewDetail});

  final MaintenanceHealthSummary summary;
  final VoidCallback? onViewDetail;

  @override
  Widget build(BuildContext context) {
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
                    summary.percentage == null
                        ? 'Kondisi Perawatan'
                        : 'Kondisi Perawatan ${summary.percentage}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewDetail,
                  child: const Text('Lihat detail'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HealthCount(
                  label: 'Aman',
                  count: summary.count(MaintenanceHealthStatus.safe),
                ),
                _HealthCount(
                  label: 'Mendekati',
                  count: summary.count(MaintenanceHealthStatus.approaching),
                ),
                _HealthCount(
                  label: 'Jatuh tempo',
                  count: summary.count(MaintenanceHealthStatus.due),
                ),
                _HealthCount(
                  label: 'Terlambat',
                  count: summary.count(MaintenanceHealthStatus.overdue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCount extends StatelessWidget {
  const _HealthCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $count'));
  }
}

class _DashboardEntrance extends StatelessWidget {
  const _DashboardEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _ActiveVehiclePanel extends StatelessWidget {
  const _ActiveVehiclePanel({
    required this.vehicle,
    required this.onManageVehicles,
    required this.onUpdateOdometer,
  });

  final Vehicle vehicle;
  final VoidCallback onManageVehicles;
  final VoidCallback onUpdateOdometer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D3A60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kendaraan aktif',
                  style: textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: onManageVehicles,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vehicle.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${vehicle.brand} ${vehicle.model} • ${vehicle.year}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _VehicleMetric(
                  label: 'Nomor polisi',
                  value: vehicle.plateNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VehicleMetric(
                  label: 'Kilometer',
                  value: AppFormatters.kilometer(vehicle.currentOdometer),
                  animateValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onUpdateOdometer,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              minimumSize: const Size(0, 40),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.speed_rounded, size: 18),
            label: const Text('Perbarui kilometer'),
          ),
        ],
      ),
    );
  }
}

class _VehicleMetric extends StatelessWidget {
  const _VehicleMetric({
    required this.label,
    required this.value,
    this.animateValue = false,
  });

  final String label;
  final String value;
  final bool animateValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 3),
        if (animateValue)
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _VehicleMetricValue(key: ValueKey(value), value: value),
          )
        else
          _VehicleMetricValue(value: value),
      ],
    );
  }
}

class _VehicleMetricValue extends StatelessWidget {
  const _VehicleMetricValue({required this.value, super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddService,
    required this.onAddSchedule,
  });

  final VoidCallback onAddService;
  final VoidCallback onAddSchedule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340;
        final width = stacked
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            SizedBox(
              width: width,
              child: OutlinedButton.icon(
                onPressed: onAddService,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah servis'),
              ),
            ),
            SizedBox(
              width: width,
              child: OutlinedButton.icon(
                onPressed: onAddSchedule,
                icon: const Icon(Icons.event_outlined),
                label: const Text('Tambah jadwal'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MaintenanceOverview extends StatelessWidget {
  const _MaintenanceOverview({
    required this.latestService,
    required this.nearestSchedule,
    required this.currentOdometer,
    required this.now,
  });

  final ServiceRecord? latestService;
  final ServiceSchedule? nearestSchedule;
  final int currentOdometer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Perawatan terkini'),
            const SizedBox(height: 16),
            _LatestServiceSummary(record: latestService),
            const Divider(height: 32),
            _NearestScheduleSummary(
              schedule: nearestSchedule,
              currentOdometer: currentOdometer,
              now: now,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestServiceSummary extends StatelessWidget {
  const _LatestServiceSummary({required this.record});

  final ServiceRecord? record;

  @override
  Widget build(BuildContext context) {
    final value = record;
    return _SummarySection(
      label: 'Servis terakhir',
      child: value == null
          ? const Text('Belum ada riwayat servis.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.date(value.serviceDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.workshop.isEmpty
                      ? 'Bengkel tidak dicatat'
                      : value.workshop,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppFormatters.kilometer(value.odometer)} • '
                  '${AppFormatters.rupiah(value.totalCost)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _NearestScheduleSummary extends StatelessWidget {
  const _NearestScheduleSummary({
    required this.schedule,
    required this.currentOdometer,
    required this.now,
  });

  final ServiceSchedule? schedule;
  final int currentOdometer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final value = schedule;
    if (value == null) {
      return const _SummarySection(
        label: 'Jadwal terdekat',
        child: Text('Belum ada jadwal aktif.'),
      );
    }

    final dueStatus = ServiceScheduleDueCalculator.calculate(
      schedule: value,
      now: now,
      currentOdometer: currentOdometer,
    );
    return _SummarySection(
      label: 'Jadwal terdekat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(value.serviceType, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ServiceScheduleStatusBadge(
              schedule: value,
              dueStatus: dueStatus,
            ),
          ),
          const SizedBox(height: 10),
          _DueLine(
            icon: Icons.event_outlined,
            label:
                '${AppFormatters.date(value.dueDate)} • ${dueStatus.date.label}',
            isOverdue: dueStatus.date.isOverdue,
          ),
          if (dueStatus.odometer case final odometer?) ...[
            const SizedBox(height: 6),
            _DueLine(
              icon: Icons.speed_rounded,
              label: odometer.label,
              isOverdue: odometer.isOverdue,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DueLine extends StatelessWidget {
  const _DueLine({
    required this.icon,
    required this.label,
    required this.isOverdue,
  });

  final IconData icon;
  final String label;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final color = isOverdue
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: color)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Biaya perawatan'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ExpenseValue(
                    label: 'Bulan ini',
                    period: AppFormatters.monthYear(now),
                    amount: summary.currentMonthExpense,
                  ),
                ),
                const SizedBox(height: 54, child: VerticalDivider(width: 24)),
                Expanded(
                  child: _ExpenseValue(
                    label: 'Tahun ini',
                    period: now.year.toString(),
                    amount: summary.currentYearExpense,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Enam bulan terakhir',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            MonthlyExpenseChart(expenses: summary.monthlyExpenses),
          ],
        ),
      ),
    );
  }
}

class _ExpenseValue extends StatelessWidget {
  const _ExpenseValue({
    required this.label,
    required this.period,
    required this.amount,
  });

  final String label;
  final String period;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            AppFormatters.rupiah(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          period,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
