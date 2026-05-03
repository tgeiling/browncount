// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const int _idDailyReminder = 1;
const int _idStreakWarningBrown = 2;
const int _idStreakWarningRating = 3;

const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
  'browncount_channel',
  'Brown Tracker Reminders',
  channelDescription: 'Daily reminders and streak warnings',
  importance: Importance.high,
  priority: Priority.high,
);

const NotificationDetails _notificationDetails = NotificationDetails(
  android: _androidDetails,
);

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();

  const AndroidInitializationSettings android = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const InitializationSettings settings = InitializationSettings(
    android: android,
  );

  await _plugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {},
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

Future<void> scheduleDailyReminder() async {
  await _plugin.zonedSchedule(
    id: _idDailyReminder,
    title: 'End of Day',
    body: 'Don\'t forget to log your brown and rate today!',
    scheduledDate: _nextInstanceOfTime(11, 0),
    notificationDetails: _notificationDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> scheduleStreakWarningBrown() async {
  await _plugin.zonedSchedule(
    id: _idStreakWarningBrown,
    title: 'Brown Streak at Risk! 💩',
    body: 'Log a brown before midnight or your streak is gone!',
    scheduledDate: _nextInstanceOfTime(20, 0),
    notificationDetails: _notificationDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> scheduleStreakWarningRating() async {
  await _plugin.zonedSchedule(
    id: _idStreakWarningRating,
    title: 'Rating Streak at Risk! ⭐',
    body: 'Rate your day before midnight or your streak is gone!',
    scheduledDate: _nextInstanceOfTime(20, 0),
    notificationDetails: _notificationDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> cancelStreakWarningBrown() async {
  await _plugin.cancel(id: _idStreakWarningBrown);
}

Future<void> cancelStreakWarningRating() async {
  await _plugin.cancel(id: _idStreakWarningRating);
}

Future<void> scheduleAllNotifications() async {
  await scheduleDailyReminder();
  await scheduleStreakWarningBrown();
  await scheduleStreakWarningRating();
}
