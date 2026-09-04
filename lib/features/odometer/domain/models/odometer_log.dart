enum OdometerLogSource {
  manualUpdate('manual_update', 'Pembaruan manual'),
  serviceRecord('service_record', 'Riwayat servis');

  const OdometerLogSource(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static OdometerLogSource fromValue(Object? value) {
    return OdometerLogSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => OdometerLogSource.manualUpdate,
    );
  }
}

class OdometerLog {
  const OdometerLog({
    required this.id,
    required this.odometer,
    required this.recordedAt,
    required this.source,
  });

  final String id;
  final int odometer;
  final DateTime? recordedAt;
  final OdometerLogSource source;

  factory OdometerLog.fromMap(Map<String, Object?> map) {
    return OdometerLog(
      id: map['id'] as String? ?? '',
      odometer: _intFrom(map['odometer']),
      recordedAt: _dateTimeFrom(map['recordedAt']),
      source: OdometerLogSource.fromValue(map['source']),
    );
  }

  Map<String, Object?> toMap() => {
    'odometer': odometer,
    'recordedAt': recordedAt,
    'source': source.storageValue,
  };

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTimeFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
