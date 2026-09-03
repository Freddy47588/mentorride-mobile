import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/onboarding/data/onboarding_store.dart';
import 'package:mentorride/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mentorride/features/onboarding/providers/onboarding_providers.dart';

void main() {
  test('first launch belum selesai dan penyelesaian disimpan lokal', () async {
    final store = _MemoryOnboardingStore();
    final container = ProviderContainer(
      overrides: [onboardingStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(await container.read(onboardingStatusProvider.future), isFalse);

    final completed = await container
        .read(onboardingStatusProvider.notifier)
        .completeOnboarding();

    expect(completed, isTrue);
    expect(store.completed, isTrue);
    expect(store.markCompletedCalls, 1);
    expect(container.read(onboardingStatusProvider).value, isTrue);
  });

  test('peluncuran berikutnya membaca status onboarding selesai', () async {
    final store = _MemoryOnboardingStore()..completed = true;
    final container = ProviderContainer(
      overrides: [onboardingStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(await container.read(onboardingStatusProvider.future), isTrue);
    expect(store.markCompletedCalls, 0);
  });

  testWidgets('onboarding menampilkan tiga halaman lalu tombol Mulai', (
    tester,
  ) async {
    final store = _MemoryOnboardingStore();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat perawatan kendaraan'), findsOneWidget);
    expect(find.text('Berikutnya'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(find.text('Jangan lewatkan jadwal servis'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(find.text('Pantau kendaraan dengan mudah'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_start_button')));
    await tester.pump();

    expect(store.completed, isTrue);
    expect(store.markCompletedCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lewati menyimpan onboarding tanpa melewati halaman lain', (
    tester,
  ) async {
    final store = _MemoryOnboardingStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding_skip_button')));
    await tester.pump();

    expect(store.completed, isTrue);
    expect(store.markCompletedCalls, 1);
  });
}

class _MemoryOnboardingStore implements OnboardingStore {
  bool completed = false;
  int markCompletedCalls = 0;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    markCompletedCalls += 1;
    completed = true;
  }
}
