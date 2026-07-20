import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database/collections/task_collection.dart';
import 'database/collections/outreach_collection.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);
            
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskDeadline(TaskItem task) async {
    if (task.dueDate == null) return;
    
    final dueDate = task.dueDate!;
    if (dueDate.isBefore(DateTime.now())) return;

    // We'll schedule the notification 15 minutes before the due date
    DateTime scheduleTime = dueDate.subtract(const Duration(minutes: 15));
    if (scheduleTime.isBefore(DateTime.now())) {
      scheduleTime = dueDate.add(const Duration(seconds: 10)); // just slightly in the future if very close
    }
    
    // Safety check
    if (scheduleTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduleTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_deadlines',
      'Task Deadlines',
      channelDescription: 'Notifications for upcoming task deadlines',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final int notificationId = task.isarId; 

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Upcoming Task Deadline',
        'Your task "${task.title}" is due soon!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
      debugPrint('Scheduled notification for task ${task.id} at $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelTaskDeadline(int taskId) async {
    await _notificationsPlugin.cancel(taskId);
  }

  Future<void> scheduleFollowUpReminder(OutreachItem item) async {
    if (item.followUpDate == null) return;
    
    // Schedule for 9 AM on the follow-up date
    DateTime scheduleTime = DateTime(
      item.followUpDate!.year,
      item.followUpDate!.month,
      item.followUpDate!.day,
      9, 0, 0
    );

    if (scheduleTime.isBefore(DateTime.now())) {
      // If it's already past 9 AM today but the date is today, we could trigger it now or ignore. 
      // Let's just ignore if it's strictly in the past.
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduleTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'follow_up_channel',
      'Follow-ups',
      channelDescription: 'Reminders for outreach follow-ups',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final notificationId = item.id.hashCode;

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Follow-up Reminder',
        'Time to follow up with ${item.name} from ${item.company ?? 'their company'}',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'outreach_${item.id}',
      );
      debugPrint('Scheduled follow-up reminder for ${item.id} at $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule follow-up notification: $e');
    }
  }

  Future<void> cancelFollowUpReminder(String itemId) async {
    await _notificationsPlugin.cancel(itemId.hashCode);
  }
}
