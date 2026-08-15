enum ServiceAction {
  periksa('periksa', 'Periksa'),
  servis('servis', 'Servis'),
  ganti('ganti', 'Ganti');

  const ServiceAction(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ServiceAction fromWire(Object? value) {
    return switch (value) {
      'servis' => ServiceAction.servis,
      'ganti' => ServiceAction.ganti,
      _ => ServiceAction.periksa,
    };
  }
}
