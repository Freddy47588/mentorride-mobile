class MaintenancePreset {
  const MaintenancePreset({
    required this.componentName,
    required this.serviceType,
    required this.actionWireValue,
    this.intervalKilometers,
    this.intervalMonths,
  });

  final String componentName;
  final String serviceType;
  final String actionWireValue;
  final int? intervalKilometers;
  final int? intervalMonths;
}

abstract final class MaintenancePresets {
  static const values = <MaintenancePreset>[
    MaintenancePreset(
      componentName: 'Oli mesin',
      serviceType: 'Ganti oli mesin',
      actionWireValue: 'ganti',
      intervalKilometers: 2000,
      intervalMonths: 3,
    ),
    MaintenancePreset(
      componentName: 'Oli gardan',
      serviceType: 'Ganti oli gardan',
      actionWireValue: 'ganti',
      intervalKilometers: 8000,
      intervalMonths: 12,
    ),
    MaintenancePreset(
      componentName: 'Busi',
      serviceType: 'Ganti busi',
      actionWireValue: 'ganti',
      intervalKilometers: 8000,
      intervalMonths: 12,
    ),
    MaintenancePreset(
      componentName: 'Filter udara',
      serviceType: 'Servis filter udara',
      actionWireValue: 'servis',
      intervalKilometers: 8000,
      intervalMonths: 12,
    ),
    MaintenancePreset(
      componentName: 'Kampas rem',
      serviceType: 'Periksa kampas rem',
      actionWireValue: 'periksa',
      intervalKilometers: 5000,
      intervalMonths: 6,
    ),
    MaintenancePreset(
      componentName: 'CVT',
      serviceType: 'Servis CVT',
      actionWireValue: 'servis',
      intervalKilometers: 8000,
      intervalMonths: 12,
    ),
    MaintenancePreset(
      componentName: 'V-belt',
      serviceType: 'Ganti V-belt',
      actionWireValue: 'ganti',
      intervalKilometers: 24000,
      intervalMonths: 24,
    ),
    MaintenancePreset(
      componentName: 'Ban',
      serviceType: 'Periksa kondisi ban',
      actionWireValue: 'periksa',
      intervalKilometers: 5000,
      intervalMonths: 6,
    ),
    MaintenancePreset(
      componentName: 'Aki',
      serviceType: 'Periksa kondisi aki',
      actionWireValue: 'periksa',
      intervalMonths: 12,
    ),
    MaintenancePreset(
      componentName: 'Rantai dan gear',
      serviceType: 'Servis rantai dan gear',
      actionWireValue: 'servis',
      intervalKilometers: 1000,
      intervalMonths: 3,
    ),
    MaintenancePreset(
      componentName: 'Coolant',
      serviceType: 'Ganti coolant',
      actionWireValue: 'ganti',
      intervalKilometers: 12000,
      intervalMonths: 24,
    ),
    MaintenancePreset(
      componentName: 'Tune up',
      serviceType: 'Tune up',
      actionWireValue: 'servis',
      intervalKilometers: 8000,
      intervalMonths: 12,
    ),
  ];

  static final List<String> serviceTypeSuggestions = List.unmodifiable(
    values.map((preset) => preset.componentName),
  );
}
