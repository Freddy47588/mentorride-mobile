import 'package:mentorride/app/router/app_routes.dart';

enum AuthAccessStatus { loading, authenticated, unauthenticated }

enum OnboardingAccessStatus { loading, pending, completed }

String? appRedirect({
  required AuthAccessStatus authStatus,
  required OnboardingAccessStatus onboardingStatus,
  required String location,
}) {
  if (onboardingStatus == OnboardingAccessStatus.loading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (onboardingStatus == OnboardingAccessStatus.pending) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }
  if (location == AppRoutes.onboarding) {
    return switch (authStatus) {
      AuthAccessStatus.loading => AppRoutes.splash,
      AuthAccessStatus.authenticated => AppRoutes.home,
      AuthAccessStatus.unauthenticated => AppRoutes.login,
    };
  }
  return authRedirect(status: authStatus, location: location);
}

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
