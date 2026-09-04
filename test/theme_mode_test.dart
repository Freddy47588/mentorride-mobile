import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/app/theme/theme_mode_store.dart';

void main() {
  test('theme preference default sistem dan menyimpan dark mode', () async {
    final store = _FakeThemeModeStore();
    final container = ProviderContainer(
      overrides: [themeModeStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(await container.read(themeModeProvider.future), ThemeMode.system);
    await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
    expect(store.saved, ThemeMode.dark);
    expect(container.read(themeModeProvider).value, ThemeMode.dark);
  });

  testWidgets('dark mode widget memakai tema Material 3 gelap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => Text(
            Theme.of(context).brightness.name,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
    expect(find.text('dark'), findsOneWidget);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });
}

class _FakeThemeModeStore implements ThemeModeStore {
  ThemeMode? saved;

  @override
  Future<ThemeMode> read() async => ThemeMode.system;

  @override
  Future<void> write(ThemeMode mode) async => saved = mode;
}
