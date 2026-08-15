import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/app/router/auth_redirect.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mentorride/features/auth/presentation/screens/login_screen.dart';
import 'package:mentorride/features/auth/presentation/screens/register_screen.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mentorride/features/navigation/presentation/navigation_placeholder_screen.dart';
import 'package:mentorride/features/navigation/presentation/splash_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_detail_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_form_screen.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_list_screen.dart';
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

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final status = authState.when(
        data: (session) => session == null
            ? AuthAccessStatus.unauthenticated
            : AuthAccessStatus.authenticated,
        error: (_, _) => AuthAccessStatus.unauthenticated,
        loading: () => AuthAccessStatus.loading,
      );
      return authRedirect(status: status, location: state.uri.path);
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
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.vehicles,
        builder: (context, state) => VehicleListScreen(
          onAddVehicle: () => context.push(AppRoutes.vehicleNew),
          onOpenVehicle: (vehicleId) {
            context.push(AppRoutes.vehicleDetail(vehicleId));
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.vehicleNew,
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/vehicles/:vehicleId',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return VehicleDetailScreen(
            vehicleId: vehicleId,
            onEditVehicle: (_) {
              context.push(AppRoutes.vehicleEdit(vehicleId));
            },
            onDeleted: () => context.pop(),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/vehicles/:vehicleId/edit',
        builder: (context, state) =>
            VehicleFormScreen(vehicleId: state.pathParameters['vehicleId']!),
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
                builder: (context, state) => const NavigationPlaceholderScreen(
                  title: 'Beranda',
                  message:
                      'Ringkasan kendaraan dan perawatan akan tampil di sini.',
                  icon: Icons.home_rounded,
                ),
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
                    builder: (context, state) =>
                        const ServiceRecordFormScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':recordId',
                    builder: (context, state) => ServiceRecordDetailScreen(
                      recordId: state.pathParameters['recordId']!,
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':recordId/edit',
                    builder: (context, state) => ServiceRecordFormScreen(
                      recordId: state.pathParameters['recordId']!,
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
                builder: (context, state) => const NavigationPlaceholderScreen(
                  title: 'Jadwal servis',
                  message: 'Jadwal dan pengingat servis akan tampil di sini.',
                  icon: Icons.event_note_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const NavigationPlaceholderScreen(
                  title: 'Profil',
                  message: 'Informasi akun dan aplikasi akan tampil di sini.',
                  icon: Icons.person_rounded,
                ),
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
