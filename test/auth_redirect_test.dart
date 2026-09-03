import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/app/router/auth_redirect.dart';

void main() {
  group('authRedirect', () {
    test('status loading selalu diarahkan ke splash', () {
      expect(
        authRedirect(
          status: AuthAccessStatus.loading,
          location: AppRoutes.home,
        ),
        AppRoutes.splash,
      );
      expect(
        authRedirect(
          status: AuthAccessStatus.loading,
          location: AppRoutes.splash,
        ),
        isNull,
      );
    });

    test('pengguna tanpa sesi hanya dapat membuka rute autentikasi', () {
      for (final route in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(
          authRedirect(
            status: AuthAccessStatus.unauthenticated,
            location: route,
          ),
          isNull,
        );
      }

      expect(
        authRedirect(
          status: AuthAccessStatus.unauthenticated,
          location: AppRoutes.vehicles,
        ),
        AppRoutes.login,
      );
    });

    test('pengguna dengan sesi dialihkan dari splash dan autentikasi', () {
      for (final route in [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(
          authRedirect(status: AuthAccessStatus.authenticated, location: route),
          AppRoutes.home,
        );
      }

      expect(
        authRedirect(
          status: AuthAccessStatus.authenticated,
          location: AppRoutes.history,
        ),
        isNull,
      );
    });
  });

  group('appRedirect', () {
    test('menunggu status onboarding di splash', () {
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.unauthenticated,
          onboardingStatus: OnboardingAccessStatus.loading,
          location: AppRoutes.home,
        ),
        AppRoutes.splash,
      );
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.loading,
          onboardingStatus: OnboardingAccessStatus.loading,
          location: AppRoutes.splash,
        ),
        isNull,
      );
    });

    test('fresh install hanya dapat membuka onboarding', () {
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.unauthenticated,
          onboardingStatus: OnboardingAccessStatus.pending,
          location: AppRoutes.splash,
        ),
        AppRoutes.onboarding,
      );
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.authenticated,
          onboardingStatus: OnboardingAccessStatus.pending,
          location: AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('onboarding selesai kembali mengikuti status autentikasi', () {
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.unauthenticated,
          onboardingStatus: OnboardingAccessStatus.completed,
          location: AppRoutes.onboarding,
        ),
        AppRoutes.login,
      );
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.authenticated,
          onboardingStatus: OnboardingAccessStatus.completed,
          location: AppRoutes.onboarding,
        ),
        AppRoutes.home,
      );
      expect(
        appRedirect(
          authStatus: AuthAccessStatus.authenticated,
          onboardingStatus: OnboardingAccessStatus.completed,
          location: AppRoutes.history,
        ),
        isNull,
      );
    });
  });
}
