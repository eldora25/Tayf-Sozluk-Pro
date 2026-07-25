import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Android 13 ve üstü için bildirim ve alarm izni ister
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyNotifications(int pendingCount) async {
    // Eski bildirimleri sil (sayı güncellenmiş olabilir)
    await _notificationsPlugin.cancelAll(); 

    // Eğer tekrar edecek kelime yoksa bildirim atıp kullanıcıyı darlamayız
    if (pendingCount <= 0) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tayf_sozluk_daily',
      'Günlük Hatırlatıcılar',
      channelDescription: 'Kelime tekrarları ve seri koruma bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // 1. BİLDİRİM: Sabah 09:00
    await _notificationsPlugin.zonedSchedule(
      1,
      'Günaydın! ☀️',
      'Bugün tekrar etmen gereken $pendingCount kelime var. Serini kaybetme!',
      _nextInstanceOfTime(9, 0), // Saat 09:00
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarlar
    );

    // 2. BİLDİRİM: Akşam 20:00
    await _notificationsPlugin.zonedSchedule(
      2,
      '🔥 Serini Korumayı Unutma!',
      'Hala tekrar etmen gereken $pendingCount kelimen var. Hemen uygulamaya gir!',
      _nextInstanceOfTime(20, 0), // Saat 20:00
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Belirtilen saat için zaman dilimini hesaplayan akıllı fonksiyon
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // Eğer saat geçtiyse, alarmı yarınki aynı saate kurar
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
