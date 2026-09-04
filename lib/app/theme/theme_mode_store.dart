import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemeModeStore {
  Future<ThemeMode> read();

  Future<void> write(ThemeMode mode);
}

class SharedPreferencesThemeModeStore implements ThemeModeStore {
  SharedPreferencesThemeModeStore(this._preferences);

  static const _key = 'theme_mode';
  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemeMode> read() async {
    final value = await _preferences.getString(_key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> write(ThemeMode mode) {
    return _preferences.setString(_key, mode.name);
  }
}

final themeModeStoreProvider = Provider<ThemeModeStore>((ref) {
  return SharedPreferencesThemeModeStore(ref.watch(sharedPreferencesProvider));
});

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() => ref.watch(themeModeStoreProvider).read();

  Future<void> select(ThemeMode mode) async {
    final previous = state.value ?? ThemeMode.system;
    state = AsyncData(mode);
    try {
      await ref.read(themeModeStoreProvider).write(mode);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
    }
  }
}
