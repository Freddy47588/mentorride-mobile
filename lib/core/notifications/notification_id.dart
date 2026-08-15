abstract final class StableNotificationId {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?'
    r'[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$',
  );

  /// Menghasilkan ID Android positif yang konsisten pada setiap proses.
  ///
  /// `String.hashCode` sengaja tidak digunakan karena kestabilannya lintas
  /// proses tidak dijamin oleh Dart.
  static int fromUuid(String uuid) {
    if (!_uuidPattern.hasMatch(uuid)) {
      throw ArgumentError.value(uuid, 'uuid', 'UUID tidak valid.');
    }

    final hexadecimal = uuid.replaceAll('-', '').toLowerCase();
    var hash = 0x811c9dc5;
    for (var index = 0; index < hexadecimal.length; index += 2) {
      final byte = int.parse(
        hexadecimal.substring(index, index + 2),
        radix: 16,
      );
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
