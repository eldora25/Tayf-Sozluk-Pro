import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart'; // YENİ: Sentry Gerçek Zamanlı Hata Takibi
import 'package:easy_localization/easy_localization.dart'; // YENİ: Çoklu Dil (i18n)
import 'package:flutter_riverpod/flutter_riverpod.dart'; // YENİ: State Management
import 'package:home_widget/home_widget.dart'; // YENİ: Günün Kelimesi Widget'ı

import 'firebase_options.dart';
import 'models.dart';
import 'core/db_helper.dart'; 
import 'core/locator.dart'; // YENİ: GetIt Dependency Injection
import 'theme/theme_manager.dart'; 
import 'notification_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized(); // i18n Başlatma

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  setupLocator(); // GetIt Bağımlılık Enjeksiyonu Başlatma
  HomeWidget.setAppGroupId('com.eldora.tayfsozlukpro'); // Widget Grubu Başlatma

  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([WordModelSchema], directory: dir.path);
  
  // Sentry Entegrasyonu
  await SentryFlutter.init(
    (options) {
      // DİKKAT: sentry.io üzerinden kendi projenizi oluşturup DSN kodunuzu buraya yapıştırın.
      options.dsn = 'https://ornek_dsn_kodunuz@sentry.io/projeniz'; 
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      ProviderScope( // Riverpod State Yönetimi Kapsamı
        child: EasyLocalization(
          supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
          path: 'assets/translations', // Çeviri dosyalarının yolu (Klasörü oluşturmanız gerekecek)
          fallbackLocale: const Locale('tr', 'TR'),
          child: const TayfSozlukApp(),
        ),
      ),
    ),
  );
}

class TayfSozlukApp extends StatefulWidget {
  const TayfSozlukApp({super.key});
  @override
  State<TayfSozlukApp> createState() => _TayfSozlukAppState();
}

class _TayfSozlukAppState extends State<TayfSozlukApp> {
  int themeIndex = 0;
  
  @override
  void initState() { 
    super.initState(); 
    _loadTheme(); 
  }
  
  void _loadTheme() async { 
    final prefs = await SharedPreferences.getInstance(); 
    setState(() => themeIndex = prefs.getInt('themeIndex') ?? 0); 
  }
  
  void _toggleTheme(int value) async { 
    final prefs = await SharedPreferences.getInstance(); 
    prefs.setInt('themeIndex', value);
    setState(() => themeIndex = value); 
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexis Eldora',
      debugShowCheckedModeBanner: false,
      // YENİ: Çoklu Dil Delegeleri
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppThemeManager.getTheme(themeIndex),
      themeAnimationDuration: const Duration(milliseconds: 300), 
      home: HomeScreen(themeIndex: themeIndex, onThemeChanged: _toggleTheme),
    );
  }
}
