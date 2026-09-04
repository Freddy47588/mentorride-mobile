import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/app/router/auth_redirect.dart';
import 'package:mentorride/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mentorride/features/auth/presentation/screens/login_screen.dart';
import 'package:mentorride/features/auth/presentation/screens/register_screen.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mentorride/features/navigation/presentation/splash_screen.dart';
import 'package:mentorride/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mentorride/features/onboarding/providers/onboarding_providers.dart';
import 'package:mentorride/features/profile/presentation/screens/profile_screen.dart';
import 'package:mentorride/features/maintenance_health/presentation/screens/maintenance_health_screen.dart';
import 'package:mentorride/features/maintenance_calendar/presentation/screens/maintenance_calendar_screen.dart';
import 'package:mentorride/features/odometer/presentation/screens/odometer_history_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_detail_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_form_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_list_screen.dart';
import 'package:mentorride/features/service_schedules/presentation/screens/service_schedule_detail_screen.dart';
import 'package:mentorride/features/service_schedules/presentation/screens/service_schedule_form_screen.dart';
import 'package:mentorride/features/service_schedules/presentation/screens/service_schedule_list_screen.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_prefill.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_form_screen.dart';
import 'package:mentorride/features/vehicles/presentation/screens/vehicle_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');
final _scheduleNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AsyncValue<AuthSession?>>(authStateProvider, (_, _) {
    refreshNotifier.refresh();
  });
  ref.listen<AsyncValue<bool>>(onboardingStatusProvider, (_, _) {
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final authStatus = authState.when(
        data: (session) => session == null
            ? AuthAccessStatus.unauthenticated
            : AuthAccessStatus.authenticated,
        error: (_, _) => AuthAccessStatus.unauthenticated,
        loading: () => AuthAccessStatus.loading,
      );
      final onboardingStatus = ref
          .read(onboardingStatusProvider)
          .when(
            data: (completed) => completed
                ? OnboardingAccessStatus.completed
                : OnboardingAccessStatus.pending,
            error: (_, _) => OnboardingAccessStatus.pending,
            loading: () => OnboardingAccessStatus.loading,
          );
      return appRedirect(
        authStatus: authStatus,
        onboardingStatus: onboardingStatus,
        location: state.uri.path,
      );
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 52),
              const SizedBox(height: 16),
              const Text(
                'Halaman yang Anda cari tidak tersedia.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.login,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.register,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.vehicles,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: VehicleListScreen(
            onAddVehicle: () => context.push(AppRoutes.vehicleNew),
            onOpenVehicle: (vehicleId) {
              context.push(AppRoutes.vehicleDetail(vehicleId));
            },
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.vehicleNew,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const VehicleFormScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.maintenanceHealth,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const MaintenanceHealthScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.odometerHistory,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const OdometerHistoryScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.maintenanceCalendar,
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: const MaintenanceCalendarScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/vehicles/:vehicleId',
        pageBuilder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return _transitionPage(
            context: context,
            state: state,
            child: VehicleDetailScreen(
              vehicleId: vehicleId,
              onEditVehicle: (_) {
                context.push(AppRoutes.vehicleEdit(vehicleId));
              },
              onDeleted: () => context.pop(),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/vehicles/:vehicleId/edit',
        pageBuilder: (context, state) => _transitionPage(
          context: context,
          state: state,
          child: VehicleFormScreen(
            vehicleId: state.pathParameters['vehicleId']!,
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const ServiceRecordListScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'new',
                    pageBuilder: (context, state) => _transitionPage(
                      context: context,
                      state: state,
                      child: const ServiceRecordFormScreen(),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':recordId',
                    pageBuilder: (context, state) => _transitionPage(
                      context: context,
                      state: state,
                      child: ServiceRecordDetailScreen(
                        recordId: state.pathParameters['recordId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':recordId/edit',
                    pageBuilder: (context, state) => _transitionPage(
                      context: context,
                      state: state,
                      child: ServiceRecordFormScreen(
                        recordId: state.pathParameters['recordId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _scheduleNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.schedules,
                builder: (context, state) => const ServiceScheduleListScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'new',
                    pageBuilder: (context, state) {
                      final extra = state.extra;
                      return _transitionPage(
                        context: context,
                        state: state,
                        child: ServiceScheduleFormScreen(
                          prefill: extra is ServiceSchedulePrefill
                              ? extra
                              : null,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':scheduleId',
                    pageBuilder: (context, state) => _transitionPage(
                      context: context,
                      state: state,
                      child: ServiceScheduleDetailScreen(
                        scheduleId: state.pathParameters['scheduleId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':scheduleId/edit',
                    pageBuilder: (context, state) => _transitionPage(
                      context: context,
                      state: state,
                      child: ServiceScheduleFormScreen(
                        scheduleId: state.pathParameters['scheduleId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

CustomTransitionPage<void> _transitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final transitionDuration = disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 220);
  final reverseTransitionDuration = disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 180);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
