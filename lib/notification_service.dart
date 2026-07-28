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
    // Android 13+ izinleri
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // Artık parametreleri ayırdık: SRS bekleyenler, Öğrenilen Sayısı ve Günlük Hedef
  static Future<void> scheduleDailyNotifications({
    required int srsCount, 
    required int wordsLearnedToday, 
    required int dailyGoal,
    required bool isStreakInDanger
  }) async {
    // Eski bildirimleri sil (veriler her güncellendiğinde sıfırlanıp baştan kurulmalı)
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

    // 1. SABAH 09:00 - SADECE SERİ (STREAK) TEHLİKEDEYSE (Kullanıcı dün hiç girmemişse veya kalkanı yoksa)
    if (isStreakInDanger) {
      await _notificationsPlugin.zonedSchedule(
        1,
        'Serin Kırılmak Üzere! ⚠️',
        'Ateşini söndürme! Serini korumak için bugün birkaç kelimeye göz atman gerekiyor.',
        _nextInstanceOfTime(9, 0), // Saat 09:00
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, 
      );
    }

    // 2. SABAH 09:30 - SRS TEKRAR HATIRLATMASI (Sadece tekrar edecek kelime varsa)
    if (srsCount > 0) {
      await _notificationsPlugin.zonedSchedule(
        2,
        'Tekrar Zamanı Geldi! 🧠',
        'Seni bekleyen $srsCount SRS kelimen var. Hafızanı tazelemek için hemen başla!',
        _nextInstanceOfTime(9, 30), // Saat 09:30
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 3. SABAH 10:30 - GÜNLÜK HEDEF HATIRLATMASI (Sadece hedefe ulaşılamamışsa)
    int remainingGoal = dailyGoal - wordsLearnedToday;
    if (remainingGoal > 0) {
       await _notificationsPlugin.zonedSchedule(
        3,
        'Hedefine Çok Yakınsın! 🎯',
        'Bugünkü hedefine ulaşmak için sadece $remainingGoal kelime kaldı.',
        _nextInstanceOfTime(10, 30), // Saat 10:30
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 4. ÖĞLE 12:30 - GENEL HATIRLATMA (SRS varsa öncelikli söyler)
    String noonMessage = srsCount > 0 
        ? "Öğle arası boş durma! $srsCount tekrar kelimen seni bekliyor."
        : "Yeni bir kütüphane keşfetmek veya birkaç kelime ezberlemek için harika bir zaman.";
        
    await _notificationsPlugin.zonedSchedule(
      4,
      'Kısa Bir Mola? ☕',
      noonMessage,
      _nextInstanceOfTime(12, 30), // Saat 12:30
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 5. AKŞAM 20:00 - GÜN SONU KONTROLÜ (Hala hedef tamamlanmamış veya SRS kalmışsa)
    if (srsCount > 0 || remainingGoal > 0) {
       await _notificationsPlugin.zonedSchedule(
        5,
        'Günü Kapatmadan Önce! 🌙',
        'Zihnini uykuya hazırlarken son bir pratik yap. Eksik görevlerin var!',
        _nextInstanceOfTime(20, 0), // Saat 20:00
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // Belirtilen saat için zaman dilimini hesaplayan akıllı fonksiyon
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // Eğer o günün saati geçtiyse, alarmı yarınki aynı saate kurar
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
