
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings("@mipmap/ic_launcher");

const InitializationSettings initializationSettings =
  InitializationSettings(
  android: androidInitializationSettings,
);

const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
  'channel id',
  'channel name',
  importance: Importance.high,
  priority: Priority.high
);

const NotificationDetails notificationDetails = NotificationDetails(
  android: androidNotificationDetails,
  macOS: null,
);

showNotification(id, title, desc, DateTime atWhen) {
  tz.initializeTimeZones();
  final tz.TZDateTime scheduledAt = tz.TZDateTime.from(atWhen, tz.local);

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
  flutterLocalNotificationsPlugin.zonedSchedule(
    int.parse(id), title, desc, scheduledAt, notificationDetails,
    uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
    androidAllowWhileIdle: true,
  );
}

removeNotification(id) {
  flutterLocalNotificationsPlugin.cancel(int.parse(id));
}