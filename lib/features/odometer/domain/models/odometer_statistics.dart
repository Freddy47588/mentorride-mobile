class OdometerStatistics {
  const OdometerStatistics({
    required this.currentOdometer,
    required this.periodIncrease,
    required this.averageMonthlyUsage,
  });

  final int currentOdometer;
  final int periodIncrease;
  final int? averageMonthlyUsage;
}
