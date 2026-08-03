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
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // GERÇEK SİSTEM BİLDİRİMİ (Push Notification) TESTİ
  static Future<void> showInstantTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tayf_sozluk_smart',
      'Akıllı Hatırlatıcılar',
      channelDescription: 'Uygulama bildirim izinlerini test etmek içindir.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _notificationsPlugin.show(
      999, // Rastgele ID
      'Tayf Sözlük - Sistem Testi 🚀',
      'Tebrikler! Cihazınız uygulamanız kapalıyken bile arka planda bildirim almaya tamamen hazır.',
      platformChannelSpecifics,
    );
  }

  static Future<void> scheduleDailyNotifications({
    required int srsCount, 
    required int wordsLearnedToday, 
    required int dailyGoal,
    required bool isStreakInDanger,
    required int streakFreezes // YENİ: Kalan buz kalkanı bilgisini alıyoruz
  }) async {
    await _notificationsPlugin.cancelAll(); 

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tayf_sozluk_smart',
      'Akıllı Hatırlatıcılar',
      channelDescription: 'Kelime tekrarları, günlük hedef ve seri koruma bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // 1. Sabah / Gündüz Seri Tehlike Uyarısı
    if (isStreakInDanger) {
      await _notificationsPlugin.zonedSchedule(
        1,
        'Serin Kırılmak Üzere! ⚠️',
        'Ateşini söndürme! Serini korumak için bugün birkaç kelimeye göz atman gerekiyor.',
        _nextInstanceOfTime(9, 0), 
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, 
      );
    }

    // 2. Akşam Akıllı Seri & Buz Kalkanı Uyarısı (YENİ EKLENDİ)
    if (isStreakInDanger) {
      String shieldText = streakFreezes > 0 
          ? "Merak etme, envanterinde $streakFreezes adet Buz Kalkanın (❄️) var ama serinin sıfırlanmaması için hemen bir kelime çalış ya da kalkanını aktif et!"
          : "Serin tehlikede ve hiç Buz Kalkanın kalmamış! Hemen uygulamaya girip serini kurtar!";

      await _notificationsPlugin.zonedSchedule(
        6,
        'Serin Sönüyor & Buz Kalkanı! ❄️🔥',
        shieldText,
        _nextInstanceOfTime(21, 0), // Akşam saat 21:00 uyarısı
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 3. SRS (Aralıklı Tekrar) Akıllı Hatırlatıcısı
    if (srsCount > 0) {
      await _notificationsPlugin.zonedSchedule(
        2,
        'Tekrar Zamanı Geldi! 🧠',
        'Seni bekleyen $srsCount SRS kelimen var. Unutma curve eğrisini yenmek için şimdi tam zamanı!',
        _nextInstanceOfTime(9, 30), 
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 4. Günlük Hedef Takibi
    int remainingGoal = dailyGoal - wordsLearnedToday;
    if (remainingGoal > 0) {
       await _notificationsPlugin.zonedSchedule(
        3,
        'Hedefine Çok Yakınsın! 🎯',
        'Bugünkü hedefine ulaşmak için sadece $remainingGoal kelime kaldı. Başarabilirsin!',
        _nextInstanceOfTime(10, 30), 
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 5. Öğle Molası Hatırlatıcısı
    String noonMessage = srsCount > 0 
        ? "Öğle arası boş durma! $srsCount tekrar kelimen seni bekliyor."
        : "Yeni bir kütüphane keşfetmek veya birkaç kelime ezberlemek için harika bir zaman.";
        
    await _notificationsPlugin.zonedSchedule(
      4,
      'Kısa Bir Mola? ☕',
      noonMessage,
      _nextInstanceOfTime(12, 30), 
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 6. Gece Kapanış / Özet Hatırlatıcısı
    if (srsCount > 0 || remainingGoal > 0) {
       await _notificationsPlugin.zonedSchedule(
        5,
        'Günü Kapatmadan Önce! 🌙',
        'Zihnini uykuya hazırlarken son bir pratik yap. Eksik görevlerin var!',
        _nextInstanceOfTime(20, 0), 
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
