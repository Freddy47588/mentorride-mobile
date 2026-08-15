import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/mentorride_app.dart';

void main() {
  testWidgets('menampilkan layar awal MentorRide', (tester) async {
    await tester.pumpWidget(const MentorRideApp());

    expect(find.text('Menyiapkan MentorRide...'), findsOneWidget);
  });
}
