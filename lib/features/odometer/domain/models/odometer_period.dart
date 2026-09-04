enum OdometerPeriod {
  thirtyDays('30 hari', 30),
  threeMonths('3 bulan', 90),
  sixMonths('6 bulan', 180),
  oneYear('1 tahun', 365);

  const OdometerPeriod(this.label, this.days);

  final String label;
  final int days;
}
