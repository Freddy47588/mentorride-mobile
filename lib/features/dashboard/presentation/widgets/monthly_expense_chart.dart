import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';

class MonthlyExpenseChart extends StatelessWidget {
  const MonthlyExpenseChart({required this.expenses, super.key});

  final List<MonthlyExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final largestExpense = expenses.fold<int>(
      0,
      (largest, expense) => math.max(largest, expense.total),
    );
    final maximumY = largestExpense == 0 ? 1.0 : largestExpense * 1.2;

    return Semantics(
      label: _semanticsLabel(),
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maximumY,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    AppFormatters.rupiah(rod.toY.round()),
                    TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
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
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= expenses.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _monthLabel(expenses[index].month.month),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var index = 0; index < expenses.length; index++)
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: expenses[index].total.toDouble(),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      color: index == expenses.length - 1
                          ? colorScheme.primary
                          : colorScheme.primaryContainer,
                    ),
                  ],
                ),
            ],
          ),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
        ),
      ),
    );
  }

  String _semanticsLabel() {
    final details = expenses.map(
      (expense) =>
          '${_monthLabel(expense.month.month)} ${expense.month.year}: '
          '${AppFormatters.rupiah(expense.total)}',
    );
    return 'Grafik biaya perawatan enam bulan. ${details.join(', ')}';
  }

  String _monthLabel(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month - 1];
  }
}
