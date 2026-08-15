class MaintenancePreset {
  const MaintenancePreset({
    required this.componentName,
    required this.serviceType,
    required this.actionWireValue,
  });

  final String componentName;
  final String serviceType;
  final String actionWireValue;
}

abstract final class MaintenancePresets {
  static const values = <MaintenancePreset>[
    MaintenancePreset(
      componentName: 'Oli mesin',
      serviceType: 'Ganti oli mesin',
      actionWireValue: 'ganti',
    ),
    MaintenancePreset(
      componentName: 'Oli gardan',
      serviceType: 'Ganti oli gardan',
      actionWireValue: 'ganti',
    ),
    MaintenancePreset(
      componentName: 'Busi',
      serviceType: 'Ganti busi',
      actionWireValue: 'ganti',
    ),
    MaintenancePreset(
      componentName: 'Filter udara',
      serviceType: 'Servis filter udara',
      actionWireValue: 'servis',
    ),
    MaintenancePreset(
      componentName: 'Kampas rem',
      serviceType: 'Periksa kampas rem',
      actionWireValue: 'periksa',
    ),
    MaintenancePreset(
      componentName: 'CVT',
      serviceType: 'Servis CVT',
      actionWireValue: 'servis',
    ),
    MaintenancePreset(
      componentName: 'V-belt',
      serviceType: 'Ganti V-belt',
      actionWireValue: 'ganti',
    ),
    MaintenancePreset(
      componentName: 'Ban',
      serviceType: 'Periksa kondisi ban',
      actionWireValue: 'periksa',
    ),
    MaintenancePreset(
      componentName: 'Aki',
      serviceType: 'Periksa kondisi aki',
      actionWireValue: 'periksa',
    ),
    MaintenancePreset(
      componentName: 'Rantai dan gear',
      serviceType: 'Servis rantai dan gear',
      actionWireValue: 'servis',
    ),
    MaintenancePreset(
      componentName: 'Coolant',
      serviceType: 'Ganti coolant',
      actionWireValue: 'ganti',
    ),
    MaintenancePreset(
      componentName: 'Tune up',
      serviceType: 'Tune up',
      actionWireValue: 'servis',
    ),
  ];

  static final List<String> serviceTypeSuggestions = List.unmodifiable(
    values.map((preset) => preset.componentName),
  );
}
