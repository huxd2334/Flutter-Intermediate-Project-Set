import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final vn = tz.getLocation('Asia/Ho_Chi_Minh');
  tz.setLocalLocation(vn);
  debugPrint('tz.local = ${tz.local.name}');
  debugPrint('now tz = ${tz.TZDateTime.now(tz.local)}');

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await notificationsPlugin.initialize(initSettings);
  runApp(const ReminderApp());
}



class Reminder {
  final int id;
  String title;
  DateTime when;
  bool repeatDaily;

  Reminder({
    required this.id,
    required this.title,
    required this.when,
    this.repeatDaily = false,
  });
}

class NotificationService {
  static const AndroidNotificationDetails _androidChannel =
  AndroidNotificationDetails(
    'reminder_channel_id',
    'Reminders',
    channelDescription: 'Local reminders',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  // Le Cam Binh

  static const NotificationDetails _platformChannelSpecifics =
  NotificationDetails(android: _androidChannel);

  static Future<bool> ensurePermissions() async {
    final androidImpl = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();

    final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
    if (!canExact) {
      await androidImpl?.requestExactAlarmsPermission();
    }
    return await androidImpl?.canScheduleExactNotifications() ?? true;
  }

  static Future<void> scheduleOneShot({
    required int id,
    required String title,
    required DateTime when,
    String? payload,
  }) async {
    final nowTz = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(nowTz.add(const Duration(seconds: 5)))) {
      scheduled = nowTz.add(const Duration(minutes: 1));
    }

    debugPrint('🕐 tz.local=${tz.local.name}');
    debugPrint('🕐 Scheduling id=$id at $scheduled'); // Kỳ vọng +0700

    await notificationsPlugin.zonedSchedule(
      id,
      'Reminder',
      title,
      scheduled,
      _platformChannelSpecifics,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

// Le Cam Binh

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required DateTime when,
    String? payload,
  }) async {
    final first = _nextDailyInstance(when.hour, when.minute);
    await notificationsPlugin.zonedSchedule(
      id,
      'Reminder',
      title,
      first,
      _platformChannelSpecifics,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
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

  static Future<void> cancel(int id) => notificationsPlugin.cancel(id);

  static Future<void> cancelAll() => notificationsPlugin.cancelAll();
}

Future<void> _debugListScheduled() async {
  final list = await notificationsPlugin.pendingNotificationRequests();
  debugPrint('PENDING COUNT = ${list.length}');
  for (final r in list) {
    debugPrint(' • id=${r.id} title=${r.title} body=${r.body}');
  }
}
 // Le Cam Binh

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2C7BE5),
        useMaterial3: true,
      ),
      home: const ReminderHomePage(),
    );
  }
}

class ReminderHomePage extends StatefulWidget {
  const ReminderHomePage({super.key});

  @override
  State<ReminderHomePage> createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> {
  final _reminders = <Reminder>[];
  final _titleCtrl = TextEditingController();
  DateTime? _pickedDateTime;
  bool _repeatDaily = false;
  final _fmt = DateFormat('EEE, dd MMM yyyy • HH:mm');

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: _pickedDateTime ?? now,
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _pickedDateTime != null
          ? TimeOfDay.fromDateTime(_pickedDateTime!)
          : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
    );
    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => _pickedDateTime = dt);
  }

  // Le Cam Binh

  Future<void> _schedule() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _pickedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tiêu đề và chọn thời gian')),
      );
      return;
    }

    final ok = await NotificationService.ensurePermissions();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu quyền thông báo/Exact alarm. Vui lòng cấp quyền.'),
        ),
      );
      return;
    }

    final id = Random().nextInt(1 << 31);

    if (_repeatDaily) {
      await NotificationService.scheduleDaily(
        id: id,
        title: title,
        when: _pickedDateTime!,
        payload: 'daily',
      );
    } else {
      await NotificationService.scheduleOneShot(
        id: id,
        title: title,
        when: _pickedDateTime!,
        payload: 'oneshot',
      );
    }
    await _debugListScheduled();

    setState(() {
      _reminders.add(Reminder(
        id: id,
        title: title,
        when: _pickedDateTime!,
        repeatDaily: _repeatDaily,
      ));
      _titleCtrl.clear();
      _pickedDateTime = null;
      _repeatDaily = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đặt lịch nhắc!')),
    );
  }


  Future<void> _cancel(Reminder r) async {
    await NotificationService.cancel(r.id);
    setState(() => _reminders.removeWhere((e) => e.id == r.id));
  }

  // Le Cam Binh

  Future<void> _cancelAll() async {
    await NotificationService.cancelAll();
    setState(() => _reminders.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder App'),
        actions: [
          IconButton(
            tooltip: 'Xoá tất cả',
            onPressed: _reminders.isEmpty ? null : _cancelAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề nhắc',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDateTime(context),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              _pickedDateTime == null
                                  ? 'Chọn ngày & giờ'
                                  : _fmt.format(_pickedDateTime!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          label: const Text('Lặp hằng ngày'),
                          selected: _repeatDaily,
                          onSelected: (v) => setState(() => _repeatDaily = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _schedule,
                        icon: const Icon(Icons.alarm_add),
                        label: const Text('Đặt lịch'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Danh sách nhắc',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (_reminders.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.inbox_outlined),
                      title: Text('Chưa có nhắc nào'),
                      subtitle: Text('Tạo nhắc mới ở trên.'),
                    )
                  else
                    ..._reminders.map((r) => Card(
                      elevation: 0,
                      child: ListTile(
                        leading: Icon(r.repeatDaily
                            ? Icons.repeat
                            : Icons.notifications_active_outlined),
                        title: Text(r.title),
                        subtitle: Text(r.repeatDaily
                            ? 'Mỗi ngày lúc ${DateFormat('HH:mm').format(r.when)}'
                            : DateFormat('EEE, dd MMM yyyy • HH:mm')
                            .format(r.when)),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          onPressed: () => _cancel(r),
                          tooltip: 'Huỷ nhắc này',
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}