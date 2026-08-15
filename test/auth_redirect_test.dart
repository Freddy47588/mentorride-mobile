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
}
