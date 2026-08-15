import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/shared/widgets/app_logo.dart';

void main() {
  testWidgets('menampilkan logo MentorRide dari asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppLogo())),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Logo MentorRide'), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/mentorride_logo.png',
    );
    expect(tester.takeException(), isNull);
  });
}
