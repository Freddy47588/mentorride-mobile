import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/notifications/notification_id.dart';

void main() {
  group('StableNotificationId.fromUuid', () {
    const dashed = '550e8400-e29b-41d4-a716-446655440000';
    const compact = '550e8400e29b41d4a716446655440000';

    test('menghasilkan nilai deterministik untuk UUID yang sama', () {
      expect(StableNotificationId.fromUuid(dashed), 1555386546);
      expect(StableNotificationId.fromUuid(dashed), 1555386546);
      expect(StableNotificationId.fromUuid(compact), 1555386546);
    });

    test('menghasilkan ID Android positif', () {
      expect(StableNotificationId.fromUuid(dashed), greaterThan(0));
    });

    test('menolak nilai yang bukan UUID', () {
      expect(
        () => StableNotificationId.fromUuid('bukan-uuid'),
        throwsArgumentError,
      );
    });
  });
}
