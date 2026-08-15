import 'package:mentorride/app/router/app_routes.dart';

enum AuthAccessStatus { loading, authenticated, unauthenticated }

String? authRedirect({
  required AuthAccessStatus status,
  required String location,
}) {
  final isAuthLocation = switch (location) {
    AppRoutes.login || AppRoutes.register || AppRoutes.forgotPassword => true,
    _ => false,
  };

  return switch (status) {
    AuthAccessStatus.loading =>
      location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthAccessStatus.unauthenticated => isAuthLocation ? null : AppRoutes.login,
    AuthAccessStatus.authenticated =>
      (isAuthLocation || location == AppRoutes.splash) ? AppRoutes.home : null,
  };
}
