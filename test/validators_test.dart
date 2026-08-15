import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/utils/validators.dart';

void main() {
  group('AppValidators.email', () {
    test('menolak email kosong dan berformat tidak valid', () {
      expect(AppValidators.email(null), isNotNull);
      expect(AppValidators.email('mentorride'), 'Format email tidak valid.');
      expect(AppValidators.email('user@domain'), 'Format email tidak valid.');
    });

    test('menerima email valid dengan spasi di tepi', () {
      expect(AppValidators.email('  user@mentorride.id  '), isNull);
    });
  });

  group('AppValidators.password', () {
    test('menolak kata sandi kosong atau lebih pendek dari enam karakter', () {
      expect(AppValidators.password(''), isNotNull);
      expect(AppValidators.password('12345'), 'Kata sandi minimal 6 karakter.');
    });

    test('menerima kata sandi enam karakter', () {
      expect(AppValidators.password('123456'), isNull);
    });
  });

  group('AppValidators.confirmation', () {
    test('menolak konfirmasi kosong atau tidak sama', () {
      expect(AppValidators.confirmation('', 'rahasia'), isNotNull);
      expect(
        AppValidators.confirmation('berbeda', 'rahasia'),
        'Konfirmasi kata sandi tidak sama.',
      );
    });

    test('menerima konfirmasi yang sama persis', () {
      expect(AppValidators.confirmation('rahasia', 'rahasia'), isNull);
    });
  });

  group('AppValidators.year', () {
    test('menerima batas tahun yang diizinkan', () {
      expect(AppValidators.year('1900', currentYear: 2026), isNull);
      expect(AppValidators.year('2027', currentYear: 2026), isNull);
    });

    test('menolak tahun di luar rentang dan bukan angka', () {
      expect(AppValidators.year('1899', currentYear: 2026), isNotNull);
      expect(AppValidators.year('2028', currentYear: 2026), isNotNull);
      expect(AppValidators.year('dua ribu', currentYear: 2026), isNotNull);
    });
  });

  group('AppValidators.plateNumber', () {
    test('menerima huruf, angka, spasi, dan tanda hubung', () {
      expect(AppValidators.plateNumber(' b 1234 xyz '), isNull);
      expect(AppValidators.plateNumber('AB-12-CD'), isNull);
    });

    test('menolak panjang atau karakter yang tidak valid', () {
      expect(AppValidators.plateNumber('B1'), isNotNull);
      expect(AppValidators.plateNumber('B123456789012'), isNotNull);
      expect(AppValidators.plateNumber('B 1234 @BC'), isNotNull);
    });
  });

  group('validator angka', () {
    test('nonNegativeInteger menerima nol dan angka berformat', () {
      expect(AppValidators.nonNegativeInteger('0'), isNull);
      expect(AppValidators.nonNegativeInteger('Rp 12.345'), isNull);
    });

    test('nonNegativeInteger menolak nilai negatif dan bukan angka', () {
      expect(AppValidators.nonNegativeInteger('-1'), isNotNull);
      expect(AppValidators.nonNegativeInteger('abc'), isNotNull);
    });

    test('optionalNonNegativeInteger mengizinkan nilai kosong', () {
      expect(AppValidators.optionalNonNegativeInteger(null), isNull);
      expect(AppValidators.optionalNonNegativeInteger('  '), isNull);
      expect(AppValidators.optionalNonNegativeInteger('-5'), isNotNull);
    });
  });

  group('AppValidators.updatedOdometer', () {
    test('menerima nilai yang sama atau lebih besar', () {
      expect(
        AppValidators.updatedOdometer('12000', currentOdometer: 12000),
        isNull,
      );
      expect(
        AppValidators.updatedOdometer('12500', currentOdometer: 12000),
        isNull,
      );
    });

    test('menolak nilai negatif, tidak valid, atau lebih kecil', () {
      expect(
        AppValidators.updatedOdometer('-1', currentOdometer: 12000),
        isNotNull,
      );
      expect(
        AppValidators.updatedOdometer('abc', currentOdometer: 12000),
        isNotNull,
      );
      expect(
        AppValidators.updatedOdometer('11999', currentOdometer: 12000),
        contains('tidak boleh lebih kecil'),
      );
    });
  });
}
