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
  static const _morningMedicationNotificationId = 2800;
  static const _eveningMedicationNotificationId = 3800;
  static const _enabledKey = 'pressure_reminders_enabled';
  static const _morningMedicationEnabledKey =
      'morning_medication_reminders_enabled';
  static const _eveningMedicationEnabledKey =
      'evening_medication_reminders_enabled';
  static const _morningMedicationHourKey = 'morning_medication_reminder_hour';
  static const _morningMedicationMinuteKey =
      'morning_medication_reminder_minute';
  static const _eveningMedicationHourKey = 'evening_medication_reminder_hour';
  static const _eveningMedicationMinuteKey =
      'evening_medication_reminder_minute';
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

  Future<MedicationReminderSettings> getMedicationReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return MedicationReminderSettings(
      morningEnabled: prefs.getBool(_morningMedicationEnabledKey) ?? false,
      eveningEnabled: prefs.getBool(_eveningMedicationEnabledKey) ?? false,
      morningTime: ReminderTime(
        hour: prefs.getInt(_morningMedicationHourKey) ?? 8,
        minute: prefs.getInt(_morningMedicationMinuteKey) ?? 0,
      ),
      eveningTime: ReminderTime(
        hour: prefs.getInt(_eveningMedicationHourKey) ?? 20,
        minute: prefs.getInt(_eveningMedicationMinuteKey) ?? 0,
      ),
    );
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

  Future<bool> setMedicationReminderEnabled(
    MedicationReminderPeriod period,
    bool enabled,
  ) async {
    if (enabled) {
      final granted = await _requestPermissions();
      if (!granted) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_medicationEnabledKey(period), enabled);
    await _rescheduleMedicationReminder(period);
    return true;
  }

  Future<bool> setMedicationReminderTime(
    MedicationReminderPeriod period,
    ReminderTime time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_medicationHourKey(period), time.hour);
    await prefs.setInt(_medicationMinuteKey(period), time.minute);
    await _rescheduleMedicationReminder(period);
    return true;
  }

  Future<void> scheduleMedicationRemindersIfNeeded() async {
    await _rescheduleMedicationReminder(MedicationReminderPeriod.morning);
    await _rescheduleMedicationReminder(MedicationReminderPeriod.evening);
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

  Future<void> cancelAllMedicationReminders() async {
    await cancelMedicationReminder(MedicationReminderPeriod.morning);
    await cancelMedicationReminder(MedicationReminderPeriod.evening);
  }

  Future<void> cancelMedicationReminder(MedicationReminderPeriod period) async {
    if (kIsWeb) return;
    await initialize();
    final baseId = _medicationNotificationId(period);
    for (var dayOffset = 0; dayOffset < _scheduledReminderDays; dayOffset++) {
      await _notifications.cancel(id: baseId + dayOffset);
    }
  }

  Future<void> _rescheduleMedicationReminder(
    MedicationReminderPeriod period,
  ) async {
    if (kIsWeb) return;
    await initialize();
    await cancelMedicationReminder(period);

    final settings = await getMedicationReminderSettings();
    final enabled = period == MedicationReminderPeriod.morning
        ? settings.morningEnabled
        : settings.eveningEnabled;
    if (!enabled) return;

    final time = period == MedicationReminderPeriod.morning
        ? settings.morningTime
        : settings.eveningTime;
    final now = DateTime.now();
    final todayReminder = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final firstReminderDate = todayReminder.isAfter(now)
        ? todayReminder
        : todayReminder.add(const Duration(days: 1));
    final baseId = _medicationNotificationId(period);

    for (var dayOffset = 0; dayOffset < _scheduledReminderDays; dayOffset++) {
      final scheduledDate = firstReminderDate.add(Duration(days: dayOffset));
      await _notifications.zonedSchedule(
        id: baseId + dayOffset,
        title: 'Przypomnienie o lekach',
        body: period == MedicationReminderPeriod.morning
            ? 'Pora przyjąć poranne leki na ciśnienie.'
            : 'Pora przyjąć wieczorne leki na ciśnienie.',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Przypomnienia o lekach',
            channelDescription:
                'Przypomnienia o przyjmowaniu leków na ciśnienie',
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

  int _medicationNotificationId(MedicationReminderPeriod period) {
    return switch (period) {
      MedicationReminderPeriod.morning => _morningMedicationNotificationId,
      MedicationReminderPeriod.evening => _eveningMedicationNotificationId,
    };
  }

  String _medicationEnabledKey(MedicationReminderPeriod period) {
    return switch (period) {
      MedicationReminderPeriod.morning => _morningMedicationEnabledKey,
      MedicationReminderPeriod.evening => _eveningMedicationEnabledKey,
    };
  }

  String _medicationHourKey(MedicationReminderPeriod period) {
    return switch (period) {
      MedicationReminderPeriod.morning => _morningMedicationHourKey,
      MedicationReminderPeriod.evening => _eveningMedicationHourKey,
    };
  }

  String _medicationMinuteKey(MedicationReminderPeriod period) {
    return switch (period) {
      MedicationReminderPeriod.morning => _morningMedicationMinuteKey,
      MedicationReminderPeriod.evening => _eveningMedicationMinuteKey,
    };
  }
}

enum MedicationReminderPeriod { morning, evening }

class ReminderTime {
  const ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}

class MedicationReminderSettings {
  const MedicationReminderSettings({
    required this.morningEnabled,
    required this.eveningEnabled,
    required this.morningTime,
    required this.eveningTime,
  });

  final bool morningEnabled;
  final bool eveningEnabled;
  final ReminderTime morningTime;
  final ReminderTime eveningTime;
}
