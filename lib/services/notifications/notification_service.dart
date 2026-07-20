import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  void _onTap(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rcm_general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    await _plugin.show(id, title, body, const NotificationDetails(android: androidDetails), payload: payload);
  }

  /// Show meeting reminder
  Future<void> showMeetingReminder({
    required int id,
    required String title,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rcm_meetings',
      'Meeting Reminders',
      channelDescription: 'Meeting and event reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    await _plugin.zonedSchedule(
      id,
      '📅 Meeting Reminder',
      title,
      tz.TZDateTime.from(scheduledDate.subtract(const Duration(minutes: 15)), tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show focus session complete
  Future<void> showFocusComplete({required int durationMinutes}) async {
    const androidDetails = AndroidNotificationDetails(
      'rcm_focus',
      'Focus Sessions',
      channelDescription: 'Focus timer notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎉 Focus Session Complete!',
      'Great job! You focused for $durationMinutes minutes.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Show task due reminder
  Future<void> showTaskDueReminder({
    required int id,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rcm_tasks',
      'Task Reminders',
      channelDescription: 'Task due date reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final scheduledTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
    if (scheduledTime.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        id,
        '📋 Task Due Today',
        taskTitle,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel notification
  Future<void> cancel(int id) async => await _plugin.cancel(id);

  /// Cancel all notifications
  Future<void> cancelAll() async => await _plugin.cancelAll();
}
