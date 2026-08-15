import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/app/mentorride_app.dart';
import 'package:mentorride/core/notifications/local_notification_service.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final reminderScheduler = LocalNotificationService();
  try {
    await reminderScheduler.initialize();
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'MentorRide bootstrap',
        context: ErrorDescription('saat menyiapkan notifikasi lokal'),
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        reminderSchedulerProvider.overrideWithValue(reminderScheduler),
      ],
      child: const MentorRideApp(),
    ),
  );
}
