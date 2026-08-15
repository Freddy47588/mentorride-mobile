import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/utils/formatters.dart';

void main() {
  group('AppFormatters.rupiah', () {
    test('memformat nol tanpa desimal', () {
      expect(AppFormatters.rupiah(0), 'Rp0');
    });

    test('menggunakan pemisah ribuan Indonesia', () {
      expect(AppFormatters.rupiah(1234567), 'Rp1.234.567');
    });
  });
}
