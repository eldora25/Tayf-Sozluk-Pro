import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

// YENİ: Firebase importları eklendi
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models.dart';
import 'quiz_screen.dart';
import 'add_word_screen.dart';
import 'word_list_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'edit_word_screen.dart';
import 'library_manager_screen.dart';
import 'manage_list_screen.dart';
import 'logger_screen.dart';
import 'notification_service.dart';
import 'match_game_screen.dart';
import 'pronunciation_screen.dart';
import 'info_screen.dart'; 
import 'wordnet_search_screen.dart'; 
import 'demo_screen.dart'; 
import 'report_screen.dart'; 

late Isar isar;
final FlutterTts globalTts = FlutterTts();

// ... (Buradaki diğer fonksiyonlarınız aynı kalacak) ...

void main() async {
  // 1. Flutter Core'u başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. YENİ: Firebase'i yapılandırılmış ayarlar ile ayağa kaldır
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Mevcut servislerinizi başlatın
  await NotificationService.init();
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([WordModelSchema], directory: dir.path);
  
  // 4. Uygulamayı çalıştır
  runApp(const TayfSozlukApp());
}

// ... (Uygulamanızın geri kalanı) ...
