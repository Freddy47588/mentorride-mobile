enum ServiceReportFormat {
  pdf(extension: 'pdf', mimeType: 'application/pdf', label: 'PDF'),
  csv(extension: 'csv', mimeType: 'text/csv', label: 'CSV');

  const ServiceReportFormat({
    required this.extension,
    required this.mimeType,
    required this.label,
  });

  final String extension;
  final String mimeType;
  final String label;
}

class ServiceReportData {
  const ServiceReportData({
    required this.vehicle,
    required this.summary,
    required this.transactions,
    required this.generatedAt,
  });

  final ServiceReportVehicle vehicle;
  final ServiceReportSummary summary;
  final List<ServiceReportTransaction> transactions;
  final DateTime generatedAt;
}

class ServiceReportVehicle {
  const ServiceReportVehicle({
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.currentOdometer,
  });

  final String name;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final int currentOdometer;
}

class ServiceReportSummary {
  const ServiceReportSummary({
    required this.serviceCount,
    required this.totalCost,
    required this.periodStart,
    required this.periodEnd,
  });

  final int serviceCount;
  final int totalCost;
  final DateTime? periodStart;
  final DateTime? periodEnd;
}

class ServiceReportTransaction {
  const ServiceReportTransaction({
    required this.id,
    required this.serviceDate,
    required this.odometer,
    required this.workshop,
    required this.items,
    required this.totalCost,
    required this.notes,
  });

  final String id;
  final DateTime serviceDate;
  final int odometer;
  final String workshop;
  final List<ServiceReportItem> items;
  final int totalCost;
  final String notes;
}

class ServiceReportItem {
  const ServiceReportItem({
    required this.component,
    required this.action,
    required this.actionValue,
    required this.cost,
  });

  final String component;
  final String action;
  final String actionValue;
  final int cost;
}
