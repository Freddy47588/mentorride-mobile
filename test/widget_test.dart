import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/mentorride_app.dart';
import 'package:mentorride/app/router/app_router.dart';

void main() {
  testWidgets('menampilkan layar awal MentorRide', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('MentorRide siap'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const MentorRideApp(),
      ),
    );

    expect(find.text('MentorRide siap'), findsOneWidget);
  });
}
