abstract final class AppValidators {
  static String? requiredText(String? value, {String field = 'Kolom'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi.';
    }
    return null;
  }

  static String? displayName(String? value) {
    final required = requiredText(value, field: 'Nama');
    if (required != null) return required;
    if (value!.trim().length < 2) return 'Nama minimal 2 karakter.';
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, field: 'Email');
    if (required != null) return required;
    final normalized = value!.trim();
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(normalized)) return 'Format email tidak valid.';
    return null;
  }

  static String? password(String? value) {
    final required = requiredText(value, field: 'Kata sandi');
    if (required != null) return required;
    if (value!.length < 6) return 'Kata sandi minimal 6 karakter.';
    return null;
  }

  static String? confirmation(String? value, String password) {
    final required = requiredText(value, field: 'Konfirmasi kata sandi');
    if (required != null) return required;
    if (value != password) return 'Konfirmasi kata sandi tidak sama.';
    return null;
  }

  static String? year(String? value, {int? currentYear}) {
    final required = requiredText(value, field: 'Tahun');
    if (required != null) return required;
    final parsed = int.tryParse(value!.trim());
    final maximum = (currentYear ?? DateTime.now().year) + 1;
    if (parsed == null || parsed < 1900 || parsed > maximum) {
      return 'Masukkan tahun antara 1900 dan $maximum.';
    }
    return null;
  }

  static String? plateNumber(String? value) {
    final required = requiredText(value, field: 'Nomor polisi');
    if (required != null) return required;
    final normalized = value!.trim().toUpperCase();
    if (normalized.length < 3 || normalized.length > 12) {
      return 'Nomor polisi harus 3–12 karakter.';
    }
    if (!RegExp(r'^[A-Z0-9\s-]+$').hasMatch(normalized)) {
      return 'Nomor polisi hanya boleh berisi huruf dan angka.';
    }
    return null;
  }

  static String? nonNegativeInteger(String? value, {String field = 'Nilai'}) {
    final required = requiredText(value, field: field);
    if (required != null) return required;
    final parsed = int.tryParse(value!.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (parsed == null || parsed < 0) {
      return '$field harus berupa angka positif.';
    }
    return null;
  }

  static String? optionalNonNegativeInteger(
    String? value, {
    String field = 'Nilai',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    return nonNegativeInteger(value, field: field);
  }

  static String? updatedOdometer(
    String? value, {
    required int currentOdometer,
  }) {
    final required = requiredText(value, field: 'Kilometer baru');
    if (required != null) return required;

    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return 'Kilometer baru harus berupa angka nonnegatif.';
    }
    if (parsed < currentOdometer) {
      return 'Kilometer baru tidak boleh lebih kecil dari kilometer saat ini.';
    }
    return null;
  }
}
