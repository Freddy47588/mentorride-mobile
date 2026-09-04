import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/app/theme/theme_mode_store.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/backup/providers/backup_providers.dart';
import 'package:mentorride/features/profile/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('pemilih tema aman pada layar kecil dan teks besar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(
              const AuthSession(
                uid: 'user-1',
                email: 'rider@example.test',
                displayName: 'Pengendara MentorRide',
                isEmailVerified: true,
              ),
            ),
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'user-1',
                displayName: 'Pengendara MentorRide',
                email: 'rider@example.test',
              ),
            ),
          ),
          authControllerProvider.overrideWith(_FakeAuthController.new),
          backupControllerProvider.overrideWith(_FakeBackupController.new),
          themeModeProvider.overrideWith(_FakeThemeModeController.new),
          reminderSchedulerProvider.overrideWithValue(_FakeReminderScheduler()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(SegmentedButton<ThemeMode>),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthController extends AuthController {
  @override
  AuthActionState build() => const AuthActionState();
}

class _FakeBackupController extends BackupController {
  @override
  BackupActionState build() => const BackupActionState();
}

class _FakeThemeModeController extends ThemeModeController {
  @override
  Future<ThemeMode> build() async => ThemeMode.system;
}

class _FakeReminderScheduler implements ReminderScheduler {
  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {}
}
