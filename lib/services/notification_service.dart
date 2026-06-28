import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/pressure_entry.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _reminderNotificationId = 1800;
  static const _enabledKey = 'pressure_reminders_enabled';
  static const _reminderHour = 18;
  static const _reminderMinute = 0;
  static const _scheduledReminderDays = 30;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    _initialized = true;
  }

  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<bool> setRemindersEnabled(
    bool enabled, {
    required List<PressureEntry> entries,
  }) async {
    if (enabled) {
      final granted = await _requestPermissions();
      if (!granted) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await scheduleNextReminderIfNeeded(entries);
    } else {
      await cancelReminder();
    }

    return true;
  }

  Future<void> scheduleNextReminderIfNeeded(List<PressureEntry> entries) async {
    if (kIsWeb || !await areRemindersEnabled()) return;
    await initialize();
    await cancelReminder();

    final now = DateTime.now();
    final todayReminder = DateTime(
      now.year,
      now.month,
      now.day,
      _reminderHour,
      _reminderMinute,
    );
    final hasTodayEntry = entries.any(
      (entry) => _isSameDay(entry.createdAt, now),
    );

    final firstReminderDate = hasTodayEntry || !todayReminder.isAfter(now)
        ? todayReminder.add(const Duration(days: 1))
        : todayReminder;

    for (var dayOffset = 0; dayOffset < _scheduledReminderDays; dayOffset++) {
      final scheduledDate = firstReminderDate.add(Duration(days: dayOffset));
      await _notifications.zonedSchedule(
        id: _reminderNotificationId + dayOffset,
        title: 'Czas na pomiar ciśnienia',
        body:
            'Nie widzimy jeszcze dzisiejszego wpisu. Dodaj pomiar przed końcem dnia.',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pressure_reminders',
            'Przypomnienia o pomiarze',
            channelDescription: 'Przypomnienia o codziennym pomiarze ciśnienia',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelReminder() async {
    if (kIsWeb) return;
    await initialize();
    for (var dayOffset = 0; dayOffset < _scheduledReminderDays; dayOffset++) {
      await _notifications.cancel(id: _reminderNotificationId + dayOffset);
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
