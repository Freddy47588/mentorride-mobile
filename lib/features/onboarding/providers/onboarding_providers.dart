import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/storage/shared_preferences_provider.dart';
import 'package:mentorride/features/onboarding/data/onboarding_store.dart';

final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return SharedPreferencesOnboardingStore(ref.watch(sharedPreferencesProvider));
});

final onboardingStatusProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<bool> {
  bool _isCompleting = false;

  @override
  Future<bool> build() {
    return ref.watch(onboardingStoreProvider).isCompleted();
  }

  Future<bool> completeOnboarding() async {
    if (_isCompleting || state.value == true) return false;

    _isCompleting = true;
    try {
      await ref.read(onboardingStoreProvider).markCompleted();
      state = const AsyncData(true);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    } finally {
      _isCompleting = false;
    }
  }
}
