import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationAdapter implements ReminderScheduler {
  NotificationAdapter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<ReminderActionEvent> _actionController =
      StreamController<ReminderActionEvent>.broadcast();

  bool _initialized = false;

  @override
  Stream<ReminderActionEvent> get onReminderAction => _actionController.stream;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    _initialized = true;
  }

  void _handleResponse(NotificationResponse response) {
    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) return;

    final action = switch (response.actionId) {
      'COMPLETE' => ReminderActionType.complete,
      'SNOOZE_15M' => ReminderActionType.snooze,
      _ => ReminderActionType.open,
    };
    _actionController.add(
      ReminderActionEvent(habitId: habitId, action: action),
    );
  }

  @override
  Future<Result<bool, Failure>> requestPermissionIfNeeded() async {
    try {
      await _ensureInitialized();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      bool granted = true;
      if (android != null) {
        granted = (await android.requestNotificationsPermission()) ?? true;
      }
      if (ios != null) {
        granted =
            (await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            true;
      }
      return Success(granted);
    } catch (e, st) {
      AppLogger.warn('NotificationAdapter', 'Permission request failed: $e');
      AppLogger.error('NotificationAdapter', 'Permission stack', e, st);
      return const Success(false);
    }
  }

  @override
  Future<Result<void, Failure>> syncLocalTimezone() async {
    try {
      await _ensureInitialized();
      // Keep tz.local synchronized with device offset on launch/resume.
      final now = DateTime.now();
      tz.setLocalLocation(tz.getLocation('UTC'));
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == now.timeZoneOffset.inMilliseconds) {
          tz.setLocalLocation(loc);
          break;
        }
      }
      return const Success(null);
    } catch (e) {
      return FailureResult(NotificationFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> scheduleHabitReminder(
    Habit habit,
    HabitScheduleVersion schedule,
  ) async {
    try {
      await _ensureInitialized();
      final minutes = schedule.reminderTimeMinutes;
      if (minutes == null) {
        return cancelHabitReminder(habit.id);
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        habit.id.hashCode & 0x7FFFFFFF,
        habit.title,
        habit.anchorHabitText ?? 'Loki',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            importance: Importance.high,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('COMPLETE', 'Complete'),
              AndroidNotificationAction('SNOOZE_15M', 'Snooze 15m'),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: habit.id,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(NotificationFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> cancelHabitReminder(String habitId) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(habitId.hashCode & 0x7FFFFFFF);
      return const Success(null);
    } catch (e) {
      return FailureResult(NotificationFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> snoozeHabitReminder(
    String habitId,
    String habitTitle,
    Duration delay,
  ) async {
    try {
      await _ensureInitialized();
      final scheduled = tz.TZDateTime.now(tz.local).add(delay);
      await _plugin.zonedSchedule(
        (habitId.hashCode ^ 0x1234) & 0x7FFFFFFF,
        habitTitle,
        'Snoozed',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: habitId,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(NotificationFailure(e.toString()));
    }
  }
}
