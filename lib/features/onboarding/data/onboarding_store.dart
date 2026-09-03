import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStore {
  Future<bool> isCompleted();

  Future<void> markCompleted();
}

class SharedPreferencesOnboardingStore implements OnboardingStore {
  SharedPreferencesOnboardingStore(this._preferences);

  static const _completedKey = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCompleted() async {
    return await _preferences.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> markCompleted() {
    return _preferences.setBool(_completedKey, true);
  }
}
