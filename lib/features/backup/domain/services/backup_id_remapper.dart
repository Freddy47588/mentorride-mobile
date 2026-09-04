typedef BackupIdGenerator = String Function();

abstract final class BackupIdRemapper {
  static Map<String, String> vehicleIds(
    Iterable<String> oldIds,
    BackupIdGenerator generate,
  ) {
    final mapping = <String, String>{};
    for (final oldId in oldIds) {
      if (oldId.isEmpty || mapping.containsKey(oldId)) {
        throw ArgumentError(
          'ID kendaraan cadangan harus unik dan tidak kosong.',
        );
      }
      mapping[oldId] = generate();
    }
    return Map.unmodifiable(mapping);
  }
}
