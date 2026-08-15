import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class LocalNotificationService implements ReminderScheduler {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String timezoneName = 'Asia/Jakarta';
  static const String channelId = 'service_reminders';
  static const String channelName = 'Pengingat servis';
  static const String channelDescription =
      'Pengingat jadwal perawatan kendaraan MentorRide.';
  static const String notificationIcon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;

  timezone.Location? _location;
  Future<void>? _initialization;
  Object? _initializationError;

  bool get isAvailable => _location != null && _initializationError == null;

  Object? get initializationError => _initializationError;

  @override
  Future<void> initialize() {
    final current = _initialization;
    if (current != null) return current;

    final initialization = _initialize();
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    try {
      timezone_data.initializeTimeZones();
      final jakarta = timezone.getLocation(timezoneName);
      timezone.setLocalLocation(jakarta);

      const androidSettings = AndroidInitializationSettings(notificationIcon);
      const settings = InitializationSettings(android: androidSettings);
      final initialized = await _plugin.initialize(settings: settings);
      if (initialized == false) {
        throw StateError('Layanan notifikasi lokal gagal diinisialisasi.');
      }

      final android = _androidPlugin;
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
          ),
        );
      }

      _location = jakarta;
      _initializationError = null;
    } on Object catch (error) {
      _location = null;
      _initializationError = error;
      _initialization = null;
      rethrow;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (!await _ensureAvailable()) {
      return NotificationPermissionStatus.unavailable;
    }

    final android = _androidPlugin;
    if (android == null) return NotificationPermissionStatus.unavailable;

    final enabled = await android.areNotificationsEnabled();
    return enabled == true
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!await _ensureAvailable()) {
      return NotificationPermissionStatus.unavailable;
    }

    final android = _androidPlugin;
    if (android == null) return NotificationPermissionStatus.unavailable;

    final granted = await android.requestNotificationsPermission();
    return granted == true
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    await _requireAvailable();
    final location = _location!;
    final zonedDate = timezone.TZDateTime.from(scheduledAt, location);
    if (!zonedDate.isAfter(timezone.TZDateTime.now(location))) {
      await cancel(id);
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: zonedDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          icon: notificationIcon,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    if (notificationId <= 0) return;
    await _requireAvailable();
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {
    for (final id in notificationIds.where((id) => id > 0).toSet()) {
      await cancel(id);
    }
  }

  @override
  Future<void> cancelAll() async {
    await _requireAvailable();
    await _plugin.cancelAll();
  }

  Future<bool> _ensureAvailable() async {
    if (isAvailable) return true;
    try {
      await initialize();
      return isAvailable;
    } on Object {
      return false;
    }
  }

  Future<void> _requireAvailable() async {
    if (await _ensureAvailable()) return;
    throw StateError('Layanan notifikasi lokal tidak tersedia.');
  }
}
