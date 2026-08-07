import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:home_widget/home_widget.dart'; 

import 'firebase_options.dart';
import 'models.dart';
import 'core/db_helper.dart'; 
import 'core/locator.dart'; 
import 'theme/theme_manager.dart'; 
import 'notification_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  setupLocator(); 
  HomeWidget.setAppGroupId('com.eldora.tayfsozlukpro'); 

  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([WordModelSchema], directory: dir.path);
  
  runApp(
    const ProviderScope( 
      child: TayfSozlukApp(),
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
      theme: AppThemeManager.getTheme(themeIndex),
      themeAnimationDuration: const Duration(milliseconds: 300), 
      home: HomeScreen(themeIndex: themeIndex, onThemeChanged: _toggleTheme),
    );
  }
}
