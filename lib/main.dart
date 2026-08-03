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

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_sync_service.dart';

import 'models.dart';
import 'wordnet.dart'; 
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

String getSmartSourceLanguage(String libraryName, String wordText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'en-US';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'tr-TR';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(wordText)) return 'tr-TR';
  return 'en-US'; 
}

String getSmartTargetLanguage(String libraryName, String meaningText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'tr-TR';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'en-US';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(meaningText)) return 'tr-TR';
  return 'tr-TR'; 
}

int getNextReviewOffset(int level) {
  const int oneDay = 24 * 60 * 60 * 1000;
  switch (level) {
    case 1: return 1 * oneDay;
    case 2: return 2 * oneDay;
    case 3: return 4 * oneDay; 
    case 4: return 9 * oneDay;
    case 5: return 14 * oneDay;
    default: return 0;
  }
}

List<String> cleanAndSplit(String rawText) {
  List<String> results = [];
  String text = rawText.replaceAll('-III', '').replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').replaceAll('\"', '');
  var parts = text.split(RegExp(r'\|\|\||;|\n|,|\.\s+'));
  for (var p in parts) {
    String clean = p.trim();
    clean = clean.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ(]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length > 1 && !['n', 'v', 'adj', 'adv', 'prep', 'conj', 'pron'].contains(clean.toLowerCase())) {
      results.add(clean);
    }
  }
  return results.toSet().toList(); 
}

List<List<String>> parseCsvMultiline(String text) {
  List<List<String>> rows = [];
  List<String> currentRow = [];
  StringBuffer currentCell = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < text.length; i++) {
    String c = text[i];
    if (c == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') { currentCell.write('"'); i++; } 
      else { inQuotes = !inQuotes; }
    } else if (c == ',' && !inQuotes) {
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
    } else if ((c == '\n' || c == '\r') && !inQuotes) {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++; 
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
      if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
      currentRow = [];
    } else { currentCell.write(c); }
  }
  if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(currentCell.toString().trim());
    if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
  }
  return rows;
}

List<String> parseLibraryDataInBackground(Map<String, dynamic> params) {
  String content = params['content'];
  String extension = params['extension'];
  String customLibraryName = params['libraryName'];
  String originalFileName = (params['originalFileName'] ?? '').toLowerCase();
  List<String> parsedList = [];

  if (content.startsWith('\uFEFF')) content = content.substring(1);

  try {
    if (extension == 'json') {
      var decoded = json.decode(content);
      List list = decoded is Map ? (decoded['words'] ?? decoded) : decoded;
      for (var item in list) {
        if (item is Map) {
          bool isWordNet = item.containsKey('pos') || item.containsKey('antonyms') || item.containsKey('lemmas') || item.containsKey('synonyms');
          
          if (isWordNet) {
             String wordStr = item['word']?.toString().trim() ?? '';
             String posStr = item['pos']?.toString().trim() ?? '';
             String defStr = item['definition']?.toString().trim() ?? '';
             
             List<String> examplesList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             
             List<String> synonymsList = [];
             if (item['synonyms'] is List) synonymsList.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) synonymsList.addAll((item['lemmas'] as List).map((e) => e.toString()));
             synonymsList = synonymsList.toSet().toList(); 
             
             List<String> antonymsList = item['antonyms'] is List ? (item['antonyms'] as List).map((e) => e.toString()).toList() : [];

             if (wordStr.isEmpty || RegExp(r'^\d{8}-').hasMatch(wordStr) || wordStr.contains('[ID:')) {
                 if (synonymsList.isNotEmpty) {
                     wordStr = synonymsList.first;
                 } else {
                     wordStr = "WordNet Term";
                 }
             }

             if (wordStr.isNotEmpty && defStr.isNotEmpty) {
                parsedList.add(json.encode({
                  'word': wordStr,
                  'meanings': [defStr], 
                  'examples': examplesList,
                  'level': 'Genel', 
                  'libraryName': customLibraryName,
                  'correctCount': 0,
                  'wrongCount': 0,
                  'listType': 'all',
                  'srsLevel': 0,
                  'nextReviewDate': 0,
                  'pos': posStr,
                  'synonyms': synonymsList,
                  'antonyms': antonymsList
                }));
             }
          } else {
             List<String> subWords = [];
             String w = item['word']?.toString().trim() ?? '';
             if (!RegExp(r'^\d{8}-').hasMatch(w) && w.isNotEmpty) subWords.add(w);
             if (item['synonyms'] is List) subWords.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) subWords.addAll((item['lemmas'] as List).map((e) => e.toString()));
             String def = item['definition']?.toString() ?? '';
             List<String> mList = item['meanings'] is List ? (item['meanings'] as List).map((e) => e.toString()).toList() : (def.isNotEmpty ? [def] : []);
             List<String> eList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             List<String> cleanM = cleanAndSplit(mList.join('|||'));
             List<String> cleanE = cleanAndSplit(eList.join('|||'));

             for (String sw in subWords) {
               sw = sw.replaceAll('_', ' ').trim(); 
               if (sw.length > 1 && cleanM.isNotEmpty) {
                 parsedList.add(json.encode({
                    'word': sw, 
                    'meanings': cleanM, 
                    'examples': cleanE, 
                    'level': item['level']?.toString() ?? 'Genel', 
                    'libraryName': customLibraryName, 
                    'correctCount': 0, 
                    'wrongCount': 0, 
                    'listType': 'all', 
                    'srsLevel': 0, 
                    'nextReviewDate': 0,
                    'pos': '',
                    'synonyms': [],
                    'antonyms': []
                 }));
               }
             }
          }
        }
      }
      return parsedList;
    }

    if (originalFileName.contains('tayf') && extension == 'txt') {
      List<String> lines = const LineSplitter().convert(content);
      for (String line in lines) {
        int colonIdx = line.indexOf(':');
        if (colonIdx != -1) {
          List<String> subWords = line.substring(0, colonIdx).split(RegExp(r'[,/]'));
          List<String> meanings = cleanAndSplit(line.substring(colonIdx + 1));
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            if (w.length > 1 && meanings.isNotEmpty) {
              parsedList.add(json.encode({'word': w, 'meanings': meanings, 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
      return parsedList;
    }

    List<List<String>> rows = parseCsvMultiline(content);
    for (List<String> row in rows) {
      if (row.length >= 2) {
        List<String> subWords = row[0].split(RegExp(r'[,/|]'));
        List<String> mList = cleanAndSplit(row[1]);
        List<String> eList = row.length > 2 ? cleanAndSplit(row[2]) : [];
        String level = row.length > 3 ? row[3].replaceAll('"', '').trim() : 'Genel';
        if (level.isEmpty) level = 'Genel';

        if (mList.isNotEmpty) {
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            w = w.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
            if (w.length > 1) {
              parsedList.add(json.encode({'word': w, 'meanings': mList, 'examples': eList, 'level': level, 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
    }
  } catch (e) {
    parsedList.add(json.encode({'error': "Dosya Okuma Hatası:\n$e"}));
  }
  return parsedList;
}

// YENİ: M3 120 FPS Akıcı Sayfa Geçiş Motoru
class Premium120FPSPageTransitionsBuilder extends PageTransitionsBuilder {
  const Premium120FPSPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 120 FPS için M3 standart esneme eğrisi ve donanım hızlandırmalı (GPU) Slide+Fade kombinasyonu
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.fastLinearToSlowEaseIn),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([WordModelSchema], directory: dir.path);
  runApp(const TayfSozlukApp());
}

class TayfSozlukApp extends StatefulWidget {
  const TayfSozlukApp({super.key});
  @override
  State<TayfSozlukApp> createState() => _TayfSozlukAppState();
}

class _TayfSozlukAppState extends State<TayfSozlukApp> {
  int themeIndex = 0;
  @override
  void initState() { super.initState(); _loadTheme(); }
  void _loadTheme() async { final prefs = await SharedPreferences.getInstance(); setState(() => themeIndex = prefs.getInt('themeIndex') ?? 0); }
  void _toggleTheme(int value) async { final prefs = await SharedPreferences.getInstance(); setState(() => themeIndex = value); prefs.setInt('themeIndex', value); }

  ThemeData _getTheme() {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();
    
    // YENİ: Akıcılığı artıran Global Geçiş Teması (Android: M3 120FPS, iOS: Native Cupertino)
    final PageTransitionsTheme smoothTransitions = const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: Premium120FPSPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );

    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, scaffoldBackgroundColor: const Color(0xFFF8F9FA), colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[600], scaffoldBackgroundColor: const Color(0xFFE3F2FD), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: AppBarTheme(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[600], scaffoldBackgroundColor: const Color(0xFFE0F2F1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: AppBarTheme(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 4: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: const Color(0xFFEDE7F6), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 5: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: const Color(0xFFFBE9E7), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 6: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.pink, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: const Color(0xFFFCE4EC), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.pink), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 7: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.cyan, primaryColor: Colors.cyan[700], scaffoldBackgroundColor: const Color(0xFFE0F7FA), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.cyan, secondary: Colors.cyanAccent), appBarTheme: AppBarTheme(backgroundColor: Colors.cyan[700], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 8: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF2C3E50), scaffoldBackgroundColor: const Color(0xFF1E272E), colorScheme: const ColorScheme.dark(primary: Color(0xFF2C3E50), secondary: Color(0xFF546E7A)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 9: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF607D8B), scaffoldBackgroundColor: const Color(0xFFECEFF1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF607D8B), secondary: Color(0xFF90A4AE)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF607D8B), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 10: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF8D6E63), scaffoldBackgroundColor: const Color(0xFFF4ECD8), cardColor: const Color(0xFFFDFBF7), colorScheme: const ColorScheme.light(primary: Color(0xFF8D6E63), secondary: Color(0xFFA1887F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF8D6E63), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 11: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF5C6BC0), scaffoldBackgroundColor: const Color(0xFFE8F4F8), cardColor: const Color(0xFFF5FAFD), colorScheme: const ColorScheme.light(primary: Color(0xFF5C6BC0), secondary: Color(0xFF7986CB)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF5C6BC0), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 12: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF9E9D24), scaffoldBackgroundColor: const Color(0xFFF5F5DC), cardColor: const Color(0xFFFCFDF2), colorScheme: const ColorScheme.light(primary: Color(0xFF9E9D24), secondary: Color(0xFFAED581)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF9E9D24), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 13: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF4E342E), scaffoldBackgroundColor: const Color(0xFF3E2723), colorScheme: const ColorScheme.dark(primary: Color(0xFF4E342E), secondary: Color(0xFF8D6E63)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 14: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF263238), scaffoldBackgroundColor: const Color(0xFF101416), colorScheme: const ColorScheme.dark(primary: Color(0xFF263238), secondary: Color(0xFF455A64)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 15: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF33691E), scaffoldBackgroundColor: const Color(0xFFF1F8E9), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF33691E), secondary: Color(0xFF558B2F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF33691E), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), pageTransitionsTheme: smoothTransitions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexis Eldora',
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      themeAnimationDuration: Duration.zero, 
      home: HomeScreen(themeIndex: themeIndex, onThemeChanged: _toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;
  const HomeScreen({super.key, required this.themeIndex, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String buildNo = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'Dev');
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _bgGradientController; 
  late AnimationController _auroraController; 
  late AnimationController _neonPulseController;
  late Animation<double> _neonPulseAnim;
  late AnimationController _tpFlashController;
  late AnimationController _freezeFlashController;
  late AnimationController _streakFlashController;
  late AnimationController _warningPulseController;

  bool _isAppLoading = true;
  String _loadingText = "Uygulama Hazırlanıyor...";

  List<WordModel> allWords = [];
  List<WordModel> learningWords = []; 
  List<WordModel> learnedWords = [];
  List<WordModel> toRepeatWords = [];
  List<WordModel> toSRSRepeatWords = []; 
  List<WordModel> wrongWords = []; 
  List<WordModel> reviewWordsPool = []; 
  
  List<WordModel> _cachedWordNetDeck = [];
  List<WordModel> _activeDeck = [];
  Map<String, int> _cardMistakes = {};

  String selectedLibrary = 'Test Paketi'; 
  String selectedLevel = 'Genel';
  int dailyGoal = 10, quizThreshold = 10, quizQuestionCount = 10, currentCardIndex = 0;
  bool isFlipped = false;
  
  int totalCompletedQuizzes = 0, totalQuizTimeSeconds = 0, totalQuizQuestions = 0, totalQuizWrong = 0;
  List<String> learnedWordTimestamps = [], completedQuizTimestamps = [], viewedCardTimestamps = [], wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0, currentStreak = 0, bestStreak = 0, tayfPoints = 0, streakFreezes = 0;

  final List<Color> distinctColors = const [
    Color(0xFFFFEA00), Color(0xFFD500F9), Color(0xFF00E5FF), Color(0xFFFF3D00), Color(0xFF00E676)
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _bgGradientController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true); 
    _auroraController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true); 
    _neonPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _neonPulseAnim = Tween<double>(begin: 0.6, end: 1.4).animate(CurvedAnimation(parent: _neonPulseController, curve: Curves.easeInOutCubic));
    _tpFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _freezeFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _streakFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _warningPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    NotificationService.requestPermission();
    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _bgGradientController.dispose(); 
    _auroraController.dispose(); 
    _neonPulseController.dispose();
    _tpFlashController.dispose();
    _freezeFlashController.dispose();
    _streakFlashController.dispose();
    _warningPulseController.dispose();
    globalTts.stop();
    super.dispose();
  }

  Future<void> _buildActiveDeck() async {
    _activeDeck.clear();
    _cardMistakes.clear(); 

    if (selectedLibrary == 'Tekrarlanması Gerekenler') {
      _activeDeck.addAll(toSRSRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
      _activeDeck.addAll(toRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
    } else if (selectedLibrary == 'WordNet Veritabanı') {
      List<int> allWordNetIds = await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').idProperty().findAll();
      
      if (allWordNetIds.isNotEmpty) {
        final random = Random();
        Set<int> selectedIds = {};
        int targetCount = min(200, allWordNetIds.length);
        
        while(selectedIds.length < targetCount) {
           selectedIds.add(allWordNetIds[random.nextInt(allWordNetIds.length)]);
        }
        
        List<WordModel?> fetchedWords = await isar.wordModels.getAll(selectedIds.toList());
        _cachedWordNetDeck = fetchedWords.whereType<WordModel>().toList();
        _activeDeck.addAll(_cachedWordNetDeck);
      }
    } else {
      _activeDeck.addAll(toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      _activeDeck.addAll(toRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      _activeDeck.addAll(allWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      _activeDeck.shuffle(); 
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int wordNetCount = await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').count();
      
      if (wordNetCount < 50000) {
         setState(() { 
           _loadingText = "WordNet İlk Kurulumu Yapılıyor...\n(Bu işlem sadece 1 kez yapılır\nve cihaz hızına göre 1-2 dk sürebilir)"; 
         });
         
         await isar.writeTxn(() async {
            await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').deleteAll();
         });
         
         List<WordModel> wnList = await WordNetInstaller.getWordNetModels();
         
         if (wnList.isNotEmpty) {
             setState(() { 
               _loadingText = "Veritabanına Gömülüyor...\n(${wnList.length} Kelime)\nLütfen uygulamayı kapatmayın..."; 
             });
             
             int batchSize = 5000;
             for (int i = 0; i < wnList.length; i += batchSize) {
                int end = (i + batchSize < wnList.length) ? i + batchSize : wnList.length;
                await isar.writeTxn(() async {
                   await isar.wordModels.putAll(wnList.sublist(i, end));
                });
                await Future.delayed(const Duration(milliseconds: 10)); 
             }
             GlobalLogger.addLog("WordNet Isar'a başarıyla kuruldu.");
         } else {
             GlobalLogger.addLog("HATA: WordNet verileri çıkarılamadı.");
         }
      }

      setState(() { _loadingText = "Kullanıcı Verileri Yükleniyor..."; });

      String savedLib = prefs.getString('selectedLibrary') ?? '';
      if (savedLib.isEmpty || savedLib == 'Varsayılan') {
        int testPackCount = await isar.wordModels.filter().libraryNameEqualTo('Test Paketi').count();
        if (testPackCount == 0) {
           try {
             final ByteData data = await rootBundle.load('assets/test_paket.json');
             final List<int> bytes = data.buffer.asUint8List();
             final String content = utf8.decode(bytes);
             final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {
               'content': content,
               'extension': 'json',
               'libraryName': 'Test Paketi',
               'originalFileName': 'test_paket.json'
             });
             
             List<WordModel> newWords = [];
             for (var jsonStr in parsedJsons) {
               try { newWords.add(WordModel.fromJson(jsonStr)..listType = 'all'); } catch(e) {}
             }
             await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
           } catch(e) { debugPrint("Test paketi yüklenemedi: $e"); }
        }
        selectedLibrary = 'Test Paketi';
        prefs.setString('selectedLibrary', 'Test Paketi');
      } else {
        selectedLibrary = savedLib;
      }

      setState(() {
        selectedLevel = prefs.getString('selectedLevel') ?? 'Genel';
        dailyGoal = prefs.getInt('dailyGoal') ?? 10;
        quizThreshold = prefs.getInt('quizThreshold') ?? 10;
        quizQuestionCount = prefs.getInt('quizQuestionCount') ?? 10;
        currentCardIndex = prefs.getInt('currentCardIndex') ?? 0;
        
        firstUseTimestamp = prefs.getInt('firstUseTimestamp') ?? 0;
        if (firstUseTimestamp < 1600000000000) { 
          firstUseTimestamp = DateTime.now().millisecondsSinceEpoch;
          prefs.setInt('firstUseTimestamp', firstUseTimestamp);
        }

        currentStreak = prefs.getInt('currentStreak') ?? 0;
        bestStreak = prefs.getInt('bestStreak') ?? 0;
        streakFreezes = prefs.getInt('streakFreezes') ?? 0;
        tayfPoints = prefs.getInt('tayfPoints') ?? 0;

        totalCompletedQuizzes = prefs.getInt('totalCompletedQuizzes') ?? 0;
        totalQuizTimeSeconds = prefs.getInt('totalQuizTimeSeconds') ?? 0;
        totalQuizQuestions = prefs.getInt('totalQuizQuestions') ?? 0;
        totalQuizWrong = prefs.getInt('totalQuizWrong') ?? 0;
        
        learnedWordTimestamps = prefs.getStringList('learnedWordTimestamps') ?? [];
        completedQuizTimestamps = prefs.getStringList('completedQuizTimestamps') ?? [];
        viewedCardTimestamps = prefs.getStringList('viewedCardTimestamps') ?? [];
        wrongAnswerTimestamps = prefs.getStringList('wrongAnswerTimestamps') ?? [];
      });

      final results = await Future.wait([
        isar.wordModels.filter().listTypeEqualTo('all').findAll(),
        isar.wordModels.filter().listTypeEqualTo('learning').findAll(),
        isar.wordModels.filter().listTypeEqualTo('learned').findAll(),
        isar.wordModels.filter().listTypeEqualTo('toRepeat').findAll(),
        isar.wordModels.filter().listTypeEqualTo('toSRSRepeat').findAll(),
        isar.wordModels.filter().wrongCountGreaterThan(0).findAll(),
        isar.wordModels.filter().libraryNameEqualTo('İncelenecek Kelimeler').findAll(),
      ]);

      allWords = results[0];
      learningWords = results[1];
      learnedWords = results[2];
      
      List<WordModel> tempToRepeat = results[3];
      toRepeatWords = tempToRepeat.where((w) => w.srsLevel == 0).toList();
      
      List<WordModel> directSrs = results[4];
      toSRSRepeatWords = [...directSrs, ...tempToRepeat.where((w) => w.srsLevel > 0)]; 

      wrongWords = results[5];
      reviewWordsPool = results[6];

      allWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');
      learningWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');
      learnedWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');
      toRepeatWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');
      toSRSRepeatWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');
      wrongWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler');

      int now = DateTime.now().millisecondsSinceEpoch;
      bool needsSave = false;
      
      for (var w in learningWords.toList()) {
        if (w.nextReviewDate <= now && w.nextReviewDate > 0) {
          w.listType = 'toSRSRepeat';
          learningWords.removeWhere((item) => item.id == w.id);
          toSRSRepeatWords.add(w);
          needsSave = true;
        }
      }

      if (needsSave) {
        await isar.writeTxn(() async { await isar.wordModels.putAll(toSRSRepeatWords); });
      }

      if (allWords.isEmpty && learnedWords.isEmpty && toRepeatWords.isEmpty && toSRSRepeatWords.isEmpty && learningWords.isEmpty) {
        _createDefaultLibrary();
      }

      await _buildActiveDeck(); 

      setState(() {
        int urgentCount = _activeDeck.where((w) => w.listType == 'toSRSRepeat' || w.listType == 'toRepeat').length;
        
        if (urgentCount > 0 && currentCardIndex >= urgentCount) {
          currentCardIndex = 0;
          isFlipped = false;
        } else if (_activeDeck.isNotEmpty && currentCardIndex >= _activeDeck.length) {
          currentCardIndex = 0;
          isFlipped = false;
        }
        
        _isAppLoading = false;
      });

    } catch (e) {
      debugPrint("Load Data Error: $e");
      GlobalLogger.addLog("Load Data Error: $e");
      setState(() { _isAppLoading = false; });
    }
  }

  Future<void> _savePreferencesOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (learnedWordTimestamps.length > 5000) learnedWordTimestamps.removeRange(0, learnedWordTimestamps.length - 5000);
      if (completedQuizTimestamps.length > 5000) completedQuizTimestamps.removeRange(0, completedQuizTimestamps.length - 5000);
      if (viewedCardTimestamps.length > 5000) viewedCardTimestamps.removeRange(0, viewedCardTimestamps.length - 5000);
      if (wrongAnswerTimestamps.length > 5000) wrongAnswerTimestamps.removeRange(0, wrongAnswerTimestamps.length - 5000);

      prefs.setString('selectedLibrary', selectedLibrary);
      prefs.setString('selectedLevel', selectedLevel);
      prefs.setInt('quizThreshold', quizThreshold);
      prefs.setInt('tayfPoints', tayfPoints);
      prefs.setInt('currentCardIndex', currentCardIndex);
      prefs.setInt('firstUseTimestamp', firstUseTimestamp);
      prefs.setInt('currentStreak', currentStreak);
      prefs.setInt('bestStreak', bestStreak);
      prefs.setInt('streakFreezes', streakFreezes);
      prefs.setInt('totalCompletedQuizzes', totalCompletedQuizzes);
      prefs.setInt('totalQuizTimeSeconds', totalQuizTimeSeconds);
      prefs.setInt('totalQuizQuestions', totalQuizQuestions);
      prefs.setInt('totalQuizWrong', totalQuizWrong);
      
      prefs.setStringList('learnedWordTimestamps', learnedWordTimestamps);
      prefs.setStringList('completedQuizTimestamps', completedQuizTimestamps);
      prefs.setStringList('viewedCardTimestamps', viewedCardTimestamps);
      prefs.setStringList('wrongAnswerTimestamps', wrongAnswerTimestamps);
    } catch (e) {}
  }

  void _triggerLevel5Celebration() {
    for (int i = 0; i < 40; i++) { 
      Future.delayed(Duration(milliseconds: i * 50), () {
        List<Color> confettiColors = [Colors.redAccent, Colors.greenAccent, Colors.blueAccent, Colors.yellowAccent, Colors.purpleAccent, Colors.pinkAccent, Colors.orangeAccent];
        Color randomColor = confettiColors[Random().nextInt(confettiColors.length)];
        
        _showFlyingParticle(Icons.star, randomColor, () {
          HapticFeedback.lightImpact();
        }, targetIndex: Random().nextInt(3), isConfetti: true);
      });
    }
  }

  void _showFlyingParticle(IconData icon, Color color, VoidCallback onArrived, {int targetIndex = 2, bool isConfetti = false}) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: isConfetti ? 1200 + Random().nextInt(600) : 1000), 
          curve: isConfetti ? Curves.easeOutCirc : Curves.easeInOutCubic,
          onEnd: () {
            overlayEntry?.remove();
            onArrived(); 
          },
          builder: (context, value, child) {
            double startX = MediaQuery.of(context).size.width / 2 - 20 + (isConfetti ? (Random().nextDouble() * 150 - 75) : 0);
            double startY = MediaQuery.of(context).size.height / 2 + (isConfetti ? (Random().nextDouble() * 150 - 75) : 0);
            
            double endX;
            if (isConfetti) {
              endX = startX + (Random().nextDouble() * 300 - 150);
            } else {
              if (targetIndex == 0) endX = MediaQuery.of(context).size.width * 0.2;
              else if (targetIndex == 1) endX = MediaQuery.of(context).size.width * 0.5 - 20;
              else endX = MediaQuery.of(context).size.width * 0.8;
            }
            
            double endY = isConfetti ? MediaQuery.of(context).size.height + 50 : (MediaQuery.of(context).padding.top + 40.0); 

            double currentX = startX + (endX - startX) * value;
            double currentY = startY + (endY - startY) * value;

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: isConfetti ? (1.0 - value).clamp(0.0, 1.0) : (value < 0.8 ? 1.0 : (1.0 - ((value - 0.8) * 5)).clamp(0.0, 1.0)), 
                child: Transform.scale(
                  scale: isConfetti ? (1.0 - (value * 0.5)) : (1.0 + (sin(value * pi) * 1.5)), 
                  child: Transform.rotate(
                    angle: isConfetti ? value * pi * 4 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.9), blurRadius: 25, spreadRadius: 5)]
                      ),
                      child: Icon(icon, color: color, size: isConfetti ? 20 : 30)
                    ),
                  )
                )
              ),
            );
          }
        );
      }
    );
    Overlay.of(context).insert(overlayEntry);
  }

  void _recordActivity(int pointsEarned) {
    if (pointsEarned > 0) {
      int particles = pointsEarned > 5 ? 5 : pointsEarned;
      int pointsPerParticle = pointsEarned ~/ particles;
      int remainder = pointsEarned % particles;

      for (int i = 0; i < particles; i++) {
        Future.delayed(Duration(milliseconds: i * 250), () {
          _showFlyingParticle(Icons.diamond, Colors.lightBlueAccent, () {
            if (mounted) {
              setState(() => tayfPoints += pointsPerParticle + (i == particles - 1 ? remainder : 0));
              _savePreferencesOnly();
              _tpFlashController.forward(from: 0.0).then((_) => _tpFlashController.reverse());
            }
          }, targetIndex: 2); 
        });
      }
    } else {
      _savePreferencesOnly();
    }
  }

  void _buyFreeze() {
    HapticFeedback.heavyImpact(); 
    if (tayfPoints >= 100) {
      setState(() { tayfPoints -= 100; });
      _savePreferencesOnly();
      
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Kapat",
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, a1, a2) => const SizedBox(),
        transitionBuilder: (context, a1, a2, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(a1.value),
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 50, spreadRadius: 20)]),
                  ),
                  const Icon(Icons.ac_unit, size: 100, color: Colors.white),
                  const Positioned(
                    bottom: 0, 
                    child: Text("KALKAN ALINDI!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.cyanAccent)]))
                  )
                ],
              )
            ),
          );
        }
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        _showFlyingParticle(Icons.ac_unit, Colors.cyanAccent, () {
          if (mounted) {
            setState(() { streakFreezes++; });
            _savePreferencesOnly();
            _freezeFlashController.forward(from: 0.0).then((_) => _freezeFlashController.reverse());
          }
        }, targetIndex: 1); 
      });

    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Kapat",
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, a1, a2) => const SizedBox(),
        transitionBuilder: (context, a1, a2, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(a1.value),
            child: AlertDialog(
              backgroundColor: Colors.redAccent.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Icon(Icons.warning, color: Colors.white, size: 50)),
              content: const Text("Yetersiz Tayf Puanı (TP). Kalkan için 100 TP gereklidir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        }
      );
    }
  }

  void _createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
    ];
    isar.writeTxnSync(() { isar.wordModels.putAllSync(allWords); });
    _savePreferencesOnly();
  }

  List<String> _safeLibraries() {
    var libs = allWords.map((e) => e.libraryName).toSet()
      ..addAll(learnedWords.map((e) => e.libraryName))
      ..addAll(toRepeatWords.map((e) => e.libraryName))
      ..addAll(toSRSRepeatWords.map((e) => e.libraryName))
      ..addAll(learningWords.map((e) => e.libraryName)); 
    var uniqueLibs = libs.toSet();
    uniqueLibs.add('Tekrarlanması Gerekenler'); 
    uniqueLibs.add('WordNet Veritabanı');
    return uniqueLibs.toList();
  }

  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
    try {
      await globalTts.stop(); 
      String rawText = "";

      if (isMeaning) {
        List<String> combinedList = [...word.meanings, ...word.examples];
        
        bool isWordNet = word.libraryName == 'WordNet Veritabanı' || word.pos.isNotEmpty || word.synonyms.isNotEmpty || word.antonyms.isNotEmpty;
        if (isWordNet) {
          if (word.synonyms.isNotEmpty) {
            combinedList.add("synonym: " + word.synonyms.take(4).join(', '));
          }
          if (word.antonyms.isNotEmpty) {
            combinedList.add("antonym: " + word.antonyms.take(4).join(', '));
          }
        }

        if (combinedList.isEmpty) return;
        rawText = combinedList.join('. '); 
      } else {
        String wText = word.word;
        if (RegExp(r'^\d{8}-').hasMatch(wText) || wText.contains('[ID:')) {
            wText = word.synonyms.isNotEmpty ? word.synonyms.first : (word.meanings.isNotEmpty ? word.meanings.first : wText);
        }
        rawText = wText;
      }

      if (rawText.isEmpty) return;
      
      String cleanText = rawText
          .replaceAll(RegExp(r'\[.*?\]'), ' ') 
          .replaceAll(RegExp(r'\(.*?\)'), ' ') 
          .replaceAll(RegExp(r'[\[\]\{\}\\|_»•:;*+><=~]'), ' ') 
          .replaceAll('ANLAM:', '')
          .replaceAll(RegExp(r'\s+'), ' ') 
          .trim();

      String detectText = isMeaning ? (word.meanings.isNotEmpty ? word.meanings.first : cleanText) : cleanText;
      
      String targetLang = isMeaning 
          ? getSmartTargetLanguage(word.libraryName, detectText) 
          : getSmartSourceLanguage(word.libraryName, detectText);
          
      globalTts.setLanguage(targetLang);
      globalTts.setSpeechRate(0.45); 
      globalTts.speak(cleanText); 
    } catch (e) {}
  }

  void _nextCard({bool increment = false}) {
    HapticFeedback.lightImpact(); 
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
      if (increment) {
        currentCardIndex++;
      }
    });
    
    _savePreferencesOnly();
    if (_activeDeck.isNotEmpty) {
      if (currentCardIndex >= _activeDeck.length) currentCardIndex = 0;
      _speakWord(_activeDeck[currentCardIndex], isMeaning: false);
    }
  }

  void _flipCard(WordModel word) {
    HapticFeedback.selectionClick(); 
    if (isFlipped) { 
      _flipController.reverse(); 
      _speakWord(word, isMeaning: false); 
    } else { 
      _flipController.forward(); 
      _speakWord(word, isMeaning: true); 
      viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); 
      _savePreferencesOnly();
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _checkDailyGoalBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final lastClaimedDate = prefs.getString('daily_goal_bonus_date') ?? '';

    if (lastClaimedDate == todayStr) return;

    int learnedToday = learnedWordTimestamps.where((ts) {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      final dtStr = dt.toIso8601String().split('T').first;
      return dtStr == todayStr;
    }).length;

    if (learnedToday >= dailyGoal) {
      prefs.setString('daily_goal_bonus_date', todayStr);
      
      setState(() {
        tayfPoints += 30; 
      });
      _savePreferencesOnly();

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Kapat",
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, a1, a2) => const SizedBox(),
          transitionBuilder: (context, a1, a2, child) {
            return Transform.scale(
              scale: Curves.easeOutBack.transform(a1.value),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.deepOrange.shade600, Colors.orangeAccent.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 70),
                      const SizedBox(height: 16),
                      const Text("GÜNLÜK HEDEF TAMAMLANDI! 🔥", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      const Text("Harika bir iş çıkardın! Günlük hedefini tamamladığın için cömert bir alev bonusu kazandın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.diamond, color: Colors.lightBlueAccent, size: 20),
                            SizedBox(width: 8),
                            Text("+30 Alev Bonusu TP", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Süper!", style: TextStyle(fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    }
  }

  void _markAsLearned(WordModel word, {bool fromQuiz = false}) {
    HapticFeedback.heavyImpact(); 
    learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    
    _checkDailyGoalBonus();

    setState(() {
      if (word.srsLevel == 0) {
        word.srsLevel = 1;
        word.listType = 'learning';
        word.nextReviewDate = DateTime.now().millisecondsSinceEpoch + getNextReviewOffset(1);
        if (!learningWords.any((w) => w.id == word.id)) learningWords.add(word);
        allWords.removeWhere((w) => w.id == word.id);
        toRepeatWords.removeWhere((w) => w.id == word.id);
      } else {
        word.srsLevel++;
        
        if (word.srsLevel == 5 && !fromQuiz) {
          _triggerLevel5Celebration();
          _recordActivity(10); 
        }

        if (word.srsLevel > 5) {
          word.listType = 'learned';
          if (!learnedWords.any((w) => w.id == word.id)) learnedWords.add(word);
        } else {
          word.listType = 'learning';
          word.nextReviewDate = DateTime.now().millisecondsSinceEpoch + getNextReviewOffset(word.srsLevel);
          if (!learningWords.any((w) => w.id == word.id)) learningWords.add(word);
        }
        toSRSRepeatWords.removeWhere((w) => w.id == word.id);
      }
      
      int mistakes = _cardMistakes[word.word] ?? 0;
      if (mistakes == 0) {
         _recordActivity(1); 
      } else {
         _recordActivity(0); 
      }

      _activeDeck.removeWhere((w) => w.id == word.id);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
       Future.microtask(() async {
         await isar.writeTxn(() async { await isar.wordModels.put(word); });
       });
    }

    if (!fromQuiz) _nextCard(increment: false); 
    else _savePreferencesOnly(); 
  }

  void _markAsToRepeat(WordModel word, {bool fromQuiz = false}) {
    HapticFeedback.mediumImpact(); 
    wrongAnswerTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    
    setState(() {
      word.wrongCount++;
      if (!wrongWords.any((w) => w.id == word.id)) wrongWords.add(word);

      if (word.srsLevel > 0) {
        word.srsLevel = 1; 
        word.nextReviewDate = 0; 
        word.listType = 'toSRSRepeat';
        if (!toSRSRepeatWords.any((w) => w.id == word.id)) toSRSRepeatWords.add(word);
        learningWords.removeWhere((w) => w.id == word.id);
      } else {
        word.listType = 'toRepeat';
        if (!toRepeatWords.any((w) => w.id == word.id)) toRepeatWords.add(word);
        allWords.removeWhere((w) => w.id == word.id);
      }

      int currentMistakeCount = (_cardMistakes[word.word] ?? 0) + 1;
      _cardMistakes[word.word] = currentMistakeCount;
      int penalty = currentMistakeCount * 2; 
      
      tayfPoints -= penalty;
      if (tayfPoints < 0) tayfPoints = 0;
      
      _tpFlashController.forward(from: 0.0).then((_) => _tpFlashController.reverse());

      _activeDeck.removeWhere((w) => w.id == word.id);
      _activeDeck.add(word);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
       Future.microtask(() async {
         await isar.writeTxn(() async { await isar.wordModels.put(word); });
       });
    }

    if (!fromQuiz) _nextCard(increment: false); 
    else _savePreferencesOnly();
  }

  void _moveToReview(WordModel word) {
    HapticFeedback.heavyImpact();
    
    FirebaseSyncService.reportCardErrorInCloud(word);

    setState(() {
      word.libraryName = 'İncelenecek Kelimeler';
      word.listType = 'all';

      allWords.removeWhere((w) => w.id == word.id);
      learningWords.removeWhere((w) => w.id == word.id);
      toRepeatWords.removeWhere((w) => w.id == word.id);
      toSRSRepeatWords.removeWhere((w) => w.id == word.id);
      wrongWords.removeWhere((w) => w.id == word.id);
      learnedWords.removeWhere((w) => w.id == word.id);
      
      _activeDeck.removeWhere((w) => w.id == word.id);
      
      reviewWordsPool.add(word);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
      Future.microtask(() async {
         await isar.writeTxn(() async { await isar.wordModels.put(word); });
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Kelime karantinaya alındı! Bulut güven skoru düşürüldü.", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange)
    );
    
    _nextCard(increment: false);
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'json', 'txt']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String? customLibraryName = await _showInputDialog("Kütüphane Adı", fileName);
      if (customLibraryName == null) return;
      
      showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName aktarılıyor..."))])));
      
      String? dialogMessage;
      bool isSuccess = false;

      try {
        List<int> bytes = await file.readAsBytes();
        String content;
        try { content = utf8.decode(bytes); } catch (e) { content = String.fromCharCodes(bytes); }
        
        final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': content, 'extension': result.files.single.extension ?? '', 'libraryName': customLibraryName, 'originalFileName': fileName});
        
        if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
          dialogMessage = json.decode(parsedJsons.first)['error'];
        } else {
          Set<String> existingWords = {
            ...allWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...learnedWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...toRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...toSRSRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...learningWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          };

          List<WordModel> newWords = [];
          for (var jsonStr in parsedJsons) {
            try {
              var w = WordModel.fromJson(jsonStr)..listType = 'all';
              if (!existingWords.contains(w.word)) {
                 newWords.add(w);
                 existingWords.add(w.word); 
              }
            } catch(e) { continue; }
          }

          setState(() { allWords.addAll(newWords); selectedLibrary = customLibraryName; currentCardIndex = 0; });
          await _buildActiveDeck();
          
          await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
          _savePreferencesOnly();
          dialogMessage = "$customLibraryName başarıyla yüklendi!\n\n(${newWords.length} yeni kelime eklendi)";
          isSuccess = true;
        }
      } catch (e) {
        dialogMessage = "Sistem Hatası:\n$e";
      } finally {
        Navigator.pop(context); 
        if (dialogMessage != null) {
          Future.delayed(const Duration(milliseconds: 150), () {
            _showCenteredDialog(
              title: isSuccess ? "Tebrikler" : "Uyarı",
              message: dialogMessage!,
              icon: isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isSuccess ? Colors.green : Colors.orange
            );
          });
        }
      }
    }
  }

  Future<void> _loadPackageFromAssets(String assetPath, String extension, String customLibraryName) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName yükleniyor..."))])));
    
    String? dialogMessage;
    bool isSuccess = false;

    try {
      ByteData data = await rootBundle.load(assetPath);
      List<int> bytes = data.buffer.asUint8List();
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (e) {
        content = String.fromCharCodes(bytes); 
      }
      
      final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': content, 'extension': extension, 'libraryName': customLibraryName, 'originalFileName': assetPath.split('/').last});
      
      if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
          dialogMessage = json.decode(parsedJsons.first)['error'];
      } else {
        Set<String> existingWords = {
          ...allWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...learnedWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...toRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...toSRSRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...learningWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
        };

        List<WordModel> newWords = [];
        for (var jsonStr in parsedJsons) {
          try {
            var w = WordModel.fromJson(jsonStr)..listType = 'all';
            if (!existingWords.contains(w.word)) {
               newWords.add(w);
               existingWords.add(w.word);
            }
          } catch(e) { continue; }
        }

        setState(() { allWords.addAll(newWords); selectedLibrary = customLibraryName; currentCardIndex = 0; });
        await _buildActiveDeck();
        await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
        _savePreferencesOnly();
        dialogMessage = "$customLibraryName başarıyla yüklendi!\n\n(${newWords.length} yeni kelime eklendi)";
        isSuccess = true;
      }
    } catch (e) {
      dialogMessage = "Sistem Hatası:\n$e";
    } finally {
      Navigator.pop(context); 
      if (dialogMessage != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _showCenteredDialog(
            title: isSuccess ? "Tebrikler" : "Uyarı",
            message: dialogMessage!,
            icon: isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isSuccess ? Colors.green : Colors.orange
          );
        });
      }
    }
  }

  void _showCenteredDialog({required String title, required String message, required IconData icon, required Color color}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 70),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ]
        )
      )
    );
  }

  void _renameLibrary(String oldName, String newName) async {
    setState(() {
      for (var w in allWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in learnedWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in toRepeatWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in toSRSRepeatWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in learningWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in wrongWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in reviewWordsPool) { if (w.libraryName == oldName) w.libraryName = newName; } 
      if (selectedLibrary == oldName) selectedLibrary = newName;
    });
    
    await _buildActiveDeck();
    isar.writeTxn(() async {
      List<WordModel> toUpdate = await isar.wordModels.filter().libraryNameEqualTo(oldName).findAll();
      for (var w in toUpdate) { w.libraryName = newName; }
      await isar.wordModels.putAll(toUpdate);
    });
    _savePreferencesOnly();
  }

  void _deleteLibrary(String libName) async {
    setState(() {
      allWords.removeWhere((w) => w.libraryName == libName);
      learnedWords.removeWhere((w) => w.libraryName == libName);
      toRepeatWords.removeWhere((w) => w.libraryName == libName);
      toSRSRepeatWords.removeWhere((w) => w.libraryName == libName);
      learningWords.removeWhere((w) => w.libraryName == libName);
      wrongWords.removeWhere((w) => w.libraryName == libName);
      reviewWordsPool.removeWhere((w) => w.libraryName == libName);
      if (selectedLibrary == libName) selectedLibrary = 'Varsayılan';
    });
    
    await _buildActiveDeck();
    isar.writeTxn(() async {
      await isar.wordModels.filter().libraryNameEqualTo(libName).deleteAll();
    });
    _savePreferencesOnly();
  }

  Future<void> _exportLibrary(String libName) async {
    if (libName == 'Tekrarlanması Gerekenler') return;
    List<WordModel> exportList = allWords.where((w) => w.libraryName == libName).toList()
                               ..addAll(learnedWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(toRepeatWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(toSRSRepeatWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(learningWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(reviewWordsPool.where((w) => w.libraryName == libName).toList());
    if (exportList.isEmpty) return;
    List<List<dynamic>> rows = exportList.map((w) => [w.word, w.meanings.join('|||'), w.examples.join('|||'), w.level]).toList();
    
    try {
      final dir = await getTemporaryDirectory();
      String safeName = libName.replaceAll(RegExp(r'[<>:"/\\|?*\u{1F9EC} ]'), '_');
      final file = File('${dir.path}/$safeName.csv');
      await file.writeAsString(const ListToCsvConverter().convert(rows));
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], subject: '$libName Yedeği');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dışa aktarma hatası: $e")));
    }
  }

  Future<String?> _showInputDialog(String title, String defVal) {
    TextEditingController ctrl = TextEditingController(text: defVal);
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Kaydet"))]));
  }

  Future<void> _openEditScreen(WordModel word) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => EditWordScreen(
      word: word, availableLibraries: _safeLibraries(), 
      onAction: (action, updatedWord) async {
        setState(() {
          if (action == EditAction.delete) {
            allWords.removeWhere((w) => w.id == word.id);
            toRepeatWords.removeWhere((w) => w.id == word.id);
            toSRSRepeatWords.removeWhere((w) => w.id == word.id);
            learningWords.removeWhere((w) => w.id == word.id);
            wrongWords.removeWhere((w) => w.id == word.id);
            learnedWords.removeWhere((w) => w.id == word.id);
            reviewWordsPool.removeWhere((w) => w.id == word.id);
            if (word.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.delete(word.id); });
          } else if (action == EditAction.update || action == EditAction.move) {
            allWords.removeWhere((w) => w.id == word.id);
            toRepeatWords.removeWhere((w) => w.id == word.id);
            toSRSRepeatWords.removeWhere((w) => w.id == word.id);
            learningWords.removeWhere((w) => w.id == word.id);
            wrongWords.removeWhere((w) => w.id == word.id);
            learnedWords.removeWhere((w) => w.id == word.id);
            reviewWordsPool.removeWhere((w) => w.id == word.id);
            
            if (selectedLibrary == 'Tekrarlanması Gerekenler') {
              if (updatedWord.srsLevel > 0) toSRSRepeatWords.add(updatedWord); 
              else toRepeatWords.add(updatedWord);
            } else if (updatedWord.libraryName == 'İncelenecek Kelimeler') {
              reviewWordsPool.add(updatedWord);
            } else { 
              allWords.add(updatedWord); 
            }
            if (updatedWord.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          } else if (action == EditAction.copy) { 
            allWords.add(updatedWord); 
            if (updatedWord.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          }
          currentCardIndex = 0;
        });
        await _buildActiveDeck();
        _savePreferencesOnly();
      },
    )));
  }

  Widget _buildCrown(int level, bool isMitosis) {
    if (level == 0) return const SizedBox.shrink();
    List<Widget> pieces = [];

    if (level == 1) {
      pieces = [const Icon(Icons.change_history, size: 16, color: Color(0xFFFFEA00))]; 
    } else if (level == 2) {
      pieces = [
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
        const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFFD500F9)),
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
      ];
    } else if (level == 3) {
      pieces = [
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.workspace_premium, size: 24, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
      ];
    } else if (level == 4) {
      pieces = [
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.military_tech, size: 28, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
      ];
    } else if (level == 5) {
      pieces = [
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.diamond, size: 32, color: Colors.white),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
      ];
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: pieces);
  }

  BoxDecoration _getPremiumCardDecoration(BuildContext context, bool isDark, {bool isMitosis = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
            ? [
                isMitosis ? Colors.purpleAccent.shade400.withOpacity(0.15) : Theme.of(context).cardColor, 
                Theme.of(context).cardColor.withOpacity(0.8)
              ]
            : [
                isMitosis ? Colors.purpleAccent.shade100.withOpacity(0.1) : Colors.white, 
                Theme.of(context).scaffoldBackgroundColor
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))
      ]
    );
  }

  Color _getTextColor(BuildContext context, bool isDark, bool isMitosis) {
    if (isMitosis) {
      return isDark ? Colors.white : Colors.purple.shade900;
    }
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Widget _buildTopBadge(int level, bool isMitosis, bool isWordNet, String pos) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(vertical: 8), 
      decoration: BoxDecoration(
        color: isWordNet ? Colors.indigo.withOpacity(0.15) : (isMitosis ? Colors.purpleAccent.withOpacity(0.15) : (level > 0 ? distinctColors[level - 1].withOpacity(0.15) : Colors.blueGrey.withOpacity(0.15))), 
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: isWordNet ? Colors.indigo.withOpacity(0.5) : (isMitosis ? Colors.purpleAccent.withOpacity(0.5) : (level > 0 ? distinctColors[level - 1].withOpacity(0.5) : Colors.blueGrey.withOpacity(0.5))), width: 2))
      ), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (level > 0 && !isWordNet) _buildCrown(level, isMitosis), 
          if (level > 0 && !isWordNet) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWordNet) ...[
                const Icon(Icons.language, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Text("WORDNET SÖZLÜK ${pos.isNotEmpty ? '[${pos.toUpperCase()}]' : ''}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else if (isMitosis) ...[
                const Icon(Icons.biotech, size: 16, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(level > 0 ? "MİTOZ (SAF KART) • SRS: $level/5" : "YENİ MİTOZ (SAF KART)", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else ...[
                Icon(Icons.menu_book, size: 16, color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey),
                const SizedBox(width: 8),
                Text(level > 0 ? "STANDART KART • SRS: $level/5" : "YENİ STANDART KART", style: TextStyle(color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ]
            ],
          ),
        ],
      )
    );
  }

  Widget _buildCardFront(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 
    bool isWordNet = word.libraryName == 'WordNet Veritabanı';

    String displayWord = word.word;
    if (RegExp(r'^\d{8}-').hasMatch(displayWord) || displayWord.contains('[ID:')) {
        displayWord = word.synonyms.isNotEmpty ? word.synonyms.first : "WordNet Terimi";
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320, 
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                _buildTopBadge(level, isMitosis, isWordNet, word.pos),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80, top: 40, left: 16, right: 16),
                        child: Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(displayWord, textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _getTextColor(context, isDark, isMitosis)))))), 
                      ),
                      Positioned(right: 5, top: 5, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => _speakWord(word, isMeaning: false))), 
                      Positioned(left: 5, top: 5, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => _openEditScreen(word))),
                      
                      if (isMitosis && !isWordNet)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: -0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white30, width: 1), boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)), BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0))]),
                                    child: Transform.rotate(angle: 0.5, child: const Text("\u{1F9EC}", style: TextStyle(fontSize: 16, shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15), Shadow(color: Colors.purpleAccent, blurRadius: 15)]))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text("DNA-" + word.id.toString().padLeft(6, '0'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;
          if (level > 0 && !isWordNet) {
            for (int i = 0; i < level; i++) {
              double thickness = 2.0 + (i * 1.5); 
              current = Container(
                padding: EdgeInsets.all(thickness), 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 + ((i + 1) * thickness)),
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.0 + (i * 0.5)), 
                  gradient: LinearGradient(colors: [distinctColors[i].withOpacity(0.9), distinctColors[i]], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: (i == level - 1) ? [BoxShadow(color: distinctColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)), blurRadius: 25 * _glowAnimation.value, spreadRadius: 6 * _glowAnimation.value)] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(3),
               decoration: BoxDecoration(
                 color: isWordNet ? Colors.indigo : (isMitosis ? Colors.purpleAccent : Theme.of(context).primaryColor),
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isWordNet ? Colors.indigo.withOpacity(0.4) : (isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.4)), blurRadius: 15, offset: const Offset(0, 5))]
               ),
               child: current,
             );
          }
          return current;
        }
      ),
    );
  }

  Widget _buildCardBack(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 
    bool isWordNet = word.libraryName == 'WordNet Veritabanı';

    String displayWord = word.word;
    if (RegExp(r'^\d{8}-').hasMatch(displayWord) || displayWord.contains('[ID:')) {
        displayWord = word.synonyms.isNotEmpty ? word.synonyms.first : "WordNet Terimi";
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320,
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                _buildTopBadge(level, isMitosis, isWordNet, word.pos),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0, left: 20, right: 20, bottom: 100), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Text(displayWord, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _getTextColor(context, isDark, isMitosis)))), 
                              // DÜZELTİLDİ: Fazla parantezler ve hatalı kapanış kaldırıldı
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: _getTextColor(context, isDark, isMitosis).withOpacity(0.3))), 
                              
                              if (isWordNet) ...[
                                Row(children: [const Icon(Icons.menu_book, size: 14, color: Colors.indigo), const SizedBox(width: 6), Text("Definition:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo.shade300))]),
                                ...word.meanings.map((m) => Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 6), child: Text(m, style: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                
                                if (word.synonyms.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.link, size: 14, color: Colors.teal), const SizedBox(width: 6), Text("Synonyms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade300))]),
                                  Padding(padding: const EdgeInsets.only(top: 4.0, left: 6), child: Wrap(spacing: 6, runSpacing: 6, children: word.synonyms.take(6).map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.withOpacity(0.3))), child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)))).toList())),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (word.antonyms.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.link_off, size: 14, color: Colors.redAccent), const SizedBox(width: 6), Text("Antonyms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent.shade200))]),
                                  Padding(padding: const EdgeInsets.only(top: 4.0, left: 6), child: Wrap(spacing: 6, runSpacing: 6, children: word.antonyms.take(6).map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: Text(a, style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)))).toList())),
                                  const SizedBox(height: 8),
                                ],

                                if (word.examples.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.format_quote, size: 14, color: Colors.orange), const SizedBox(width: 6), Text("Examples:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orange.shade300))]),
                                  ...word.examples.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                                    child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)),
                                  )),
                                ]
                              ] else ...[
                                ...word.meanings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text("• " + m, style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                if (word.examples.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text("Örnekler:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isMitosis ? Colors.pinkAccent : Theme.of(context).colorScheme.secondary)),
                                  const SizedBox(height: 6),
                                  ...word.examples.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text("» " + e, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4, color: _getTextColor(context, isDark, isMitosis))))),
                                ]
                              ]
                            ]
                          )
                        )
                      ), 
                      Positioned(right: 5, top: 0, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => _speakWord(word, isMeaning: true))), 
                      Positioned(left: 5, top: 0, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => _openEditScreen(word))),
                      
                      if (isMitosis && !isWordNet)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: -0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white30, width: 1), boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)), BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0))]),
                                    child: Transform.rotate(angle: 0.5, child: const Text("\u{1F9EC}", style: TextStyle(fontSize: 16, shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15), Shadow(color: Colors.purpleAccent, blurRadius: 15)]))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text("DNA-" + word.id.toString().padLeft(6, '0'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;
          if (level > 0 && !isWordNet) {
            for (int i = 0; i < level; i++) {
              double thickness = 2.0 + (i * 1.5);
              current = Container(
                padding: EdgeInsets.all(thickness),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 + ((i + 1) * thickness)),
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.0 + (i * 0.5)),
                  gradient: LinearGradient(colors: [distinctColors[i].withOpacity(0.9), distinctColors[i]], begin: Alignment.bottomRight, end: Alignment.topLeft),
                  boxShadow: (i == level - 1) ? [BoxShadow(color: distinctColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)), blurRadius: 25 * _glowAnimation.value, spreadRadius: 6 * _glowAnimation.value)] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(3),
               decoration: BoxDecoration(
                 color: isWordNet ? Colors.indigo : (isMitosis ? Colors.purpleAccent : Colors.green), 
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isWordNet ? Colors.indigo.withOpacity(0.4) : (isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Colors.green.withOpacity(0.4)), blurRadius: 15, offset: const Offset(0, 5))]
               ),
               child: current,
             );
          }
          return current;
        }
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      elevation: 10,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), 
      child: RepaintBoundary( 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      AnimatedBuilder(
                        animation: _bgGradientController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor, 
                                  Theme.of(context).colorScheme.secondary,
                                  Colors.indigoAccent
                                ],
                                stops: [
                                  0.0,
                                  _bgGradientController.value,
                                  1.0
                                ],
                                begin: Alignment.topLeft, 
                                end: Alignment.bottomRight
                              )
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                    image: const DecorationImage(image: AssetImage('assets/ic_launcher.png'), fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text("Lexis Eldora", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                Text("Build v2.0.$buildNo", style: const TextStyle(color: Colors.white70, fontSize: 13))
                              ],
                            ),
                          );
                        }
                      ),
                      ListTile(tileColor: Colors.blue.withOpacity(0.1), leading: const Icon(Icons.ac_unit, color: Colors.blue), title: const Text("Buz Kalkanı Al (100 💎)", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Mevcut Kalkan: $streakFreezes ❄️\nSerinin bozulmasını engeller."), onTap: () { Navigator.pop(context); _buyFreeze(); }),
                      const Divider(),
                      
                      ListTile(
                        leading: const Icon(Icons.travel_explore, color: Colors.indigoAccent), 
                        title: const Text("WordNet Browser", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)), 
                        subtitle: const Text("Gelişmiş İng-İng Sözlük Arama"), 
                        onTap: () { 
                          HapticFeedback.lightImpact(); 
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WordNetSearchScreen(words: [...allWords, ...learnedWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords])));
                        }
                      ),
                      
                      ListTile(leading: const Icon(Icons.add_box), title: const Text("Kelime Ekle"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(availableLibraries: _safeLibraries(), onSave: (w) { setState(() => allWords.add(w)); _buildActiveDeck(); _savePreferencesOnly(); }))); }),
                      ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: _activeDeck, onDelete: (w) { setState(() { allWords.remove(w); toRepeatWords.remove(w); toSRSRepeatWords.remove(w); _activeDeck.remove(w); }); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onLearned: _markAsLearned))); }),
                      
                      ListTile(
                        leading: const Icon(Icons.settings), 
                        title: const Text("Ayarlar, Temalar, Seçimler"), 
                        onTap: () { 
                          HapticFeedback.lightImpact();
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                            currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, availableLibraries: _safeLibraries(), 
                            onSaveSettings: (nG, nT, nQC, nTI, nL, nLv) async { 
                              setState(() { dailyGoal = nG; quizThreshold = nT; quizQuestionCount = nQC; widget.onThemeChanged(nTI); selectedLibrary = nL; selectedLevel = nLv; }); 
                              await _buildActiveDeck(); 
                              _savePreferencesOnly(); 
                              Future.delayed(const Duration(milliseconds: 150), () {
                                _showCenteredDialog(
                                  title: "Harika!", 
                                  message: "Ayarlar başarıyla kalıcı olarak kaydedildi.", 
                                  icon: Icons.verified_user, 
                                  color: Colors.green
                                );
                              });
                            }, 
                            onAddPackage: _loadPackageFromAssets
                          ))); 
                        }
                      ),
                      
                      const Divider(),
                      ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: const Text("Öğrenilen Kelimeler"), subtitle: Text("${learnedWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Öğrenilen Kelimeler", words: learnedWords, onDelete: (w) { setState(() => learnedWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onClearAll: () { setState(() => learnedWords.clear()); _savePreferencesOnly(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                      ListTile(leading: const Icon(Icons.repeat, color: Colors.orange), title: const Text("Tekrar Listesi (Normal)"), subtitle: Text("${toRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Tekrar Listesi", words: toRepeatWords, onDelete: (w) { setState(() => toRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onClearAll: () { setState(() => toRepeatWords.clear()); _savePreferencesOnly(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                      ListTile(leading: const Icon(Icons.schedule, color: Colors.blue), title: const Text("SRS Tekrar Listesi"), subtitle: Text("${toSRSRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "SRS Tekrar Listesi", words: toSRSRepeatWords, showSrsLevel: true, onDelete: (w) { setState(() => toSRSRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onClearAll: () { setState(() => toSRSRepeatWords.clear()); _savePreferencesOnly(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                      ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text("Yanlış Kelimeler"), subtitle: Text("${wrongWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Yanlış Kelimeler", words: wrongWords, showWrongCount: true, onDelete: (w) { setState(() => wrongWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onClearAll: () { setState(() => wrongWords.clear()); _savePreferencesOnly(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                      
                      ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber), 
                        title: const Text("Karantina & Hata Havuzu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)), 
                        subtitle: Text("${reviewWordsPool.length} kelime (İncelenecek)"), 
                        onTap: () { 
                          HapticFeedback.lightImpact(); 
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Karantina & Hata Havuzu", words: reviewWordsPool, onDelete: (w) { setState(() => reviewWordsPool.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onClearAll: () { setState(() => reviewWordsPool.clear()); _savePreferencesOnly(); }, onEdit: _openEditScreen))).then((_) => setState((){})); 
                        }
                      ),

                      const Divider(),
                      ListTile(leading: const Icon(Icons.my_library_books), title: const Text("Kütüphane Yönetimi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(allWords: allWords, learningWords: learningWords, learnedWords: learnedWords, toRepeatWords: [...toRepeatWords, ...toSRSRepeatWords], wrongWords: wrongWords, onRename: _renameLibrary, onDelete: _deleteLibrary, onExport: _exportLibrary, onPointsEarned: (points) => _recordActivity(points)))); }),
                      ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: _activeDeck, onGameFinished: (points) { _recordActivity(points); _savePreferencesOnly(); }))); }),
                      ListTile(leading: const Icon(Icons.mic, color: Colors.teal), title: const Text("Telaffuz Sınavı"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => PronunciationScreen(words: _activeDeck, onGameFinished: (points) { _recordActivity(points); _savePreferencesOnly(); }))); }),
                      
                      ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { 
                        HapticFeedback.lightImpact();
                        Navigator.pop(context); 
                        List<WordModel> fullPool = [];
                        if (selectedLibrary == 'WordNet Veritabanı') {
                          var wnList = allWords.where((w) => w.libraryName == 'WordNet Veritabanı').toList();
                          wnList.shuffle();
                          fullPool = wnList.take(200).toList();
                        } else {
                          fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList();
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                          words: fullPool, threshold: quizThreshold, questionCount: quizQuestionCount, 
                          onWordMastered: (w) => _markAsLearned(w, fromQuiz: true), 
                          onWrongWord: (w) => _markAsToRepeat(w, fromQuiz: true), 
                          onQuizFinished: (t, a, w, tp) { 
                            setState(() { 
                              totalCompletedQuizzes++; 
                              totalQuizTimeSeconds += t; 
                              totalQuizQuestions += a; 
                              totalQuizWrong += w; 
                              tayfPoints += tp; 
                              completedQuizTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); 
                            });
                            _savePreferencesOnly(); 
                          }
                        ))).then((_) => _loadData()); 
                      }),
                      
                      ListTile(leading: const Icon(Icons.analytics), title: const Text("İstatistikler & Rozetler"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(allWords: allWords, learningWords: learningWords, toRepeatWords: toRepeatWords, toSRSRepeatWords: toSRSRepeatWords, learnedWords: learnedWords, wrongWords: wrongWords, availableLibraries: _safeLibraries(), totalCompletedQuizzes: totalCompletedQuizzes, totalQuizTimeSeconds: totalQuizTimeSeconds, totalQuizQuestions: totalQuizQuestions, totalQuizWrong: totalQuizWrong, learnedWordTimestamps: learnedWordTimestamps, completedQuizTimestamps: completedQuizTimestamps, viewedCardTimestamps: viewedCardTimestamps, wrongAnswerTimestamps: wrongAnswerTimestamps, firstUseTimestamp: firstUseTimestamp, bestStreak: bestStreak, tayfPoints: tayfPoints))); }), 
                      const Divider(),
                      ListTile(leading: const Icon(Icons.science, color: Colors.purple), title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)), subtitle: const Text("Görünüm ve fonksiyon testleri", style: TextStyle(fontSize: 12)), onTap: () async { 
                        HapticFeedback.lightImpact(); 
                        Navigator.pop(context); 
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const DemoScreen()));
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selectedLibrary', 'Tekrarlanması Gerekenler');
                        await prefs.setInt('currentCardIndex', 0);
                        setState(() { selectedLibrary = 'Tekrarlanması Gerekenler'; currentCardIndex = 0; isFlipped = false; });
                        _loadData();
                      }),
                      ListTile(leading: const Icon(Icons.bug_report, color: Colors.orange), title: const Text("Hata Kayıtları (Log)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LoggerScreen())); }),
                      const Divider(),
                      ListTile(leading: const Icon(Icons.info_outline, color: Colors.indigo), title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen())); }),
                      ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); _importFile(); }),
                      ListTile(leading: const Icon(Icons.share), title: const Text("Paylaş / Dışa Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); _exportLibrary(selectedLibrary); }),
                      ListTile(leading: const Icon(Icons.bug_report_outlined, color: Colors.redAccent), title: const Text("İstek / Hata Bildir", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())); }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 16 + MediaQuery.of(context).padding.bottom), 
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.08), border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("V2.0.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purpleAccent.shade400, Colors.deepPurple]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]),
                            child: const Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonBadge(IconData icon, String value, Color color, int count, AnimationController? flashController) {
    return AnimatedBuilder(
      animation: Listenable.merge([_neonPulseController, if (flashController != null) flashController]),
      builder: (context, child) {
        double baseSpread = (count * 0.3).clamp(2.0, 20.0); 
        double pulseSpread = baseSpread * _neonPulseAnim.value;
        double flashValue = flashController?.value ?? 0.0;
        double flashSpread = flashValue * 30.0; 
        double flashOpacity = (0.6 + (flashValue * 0.4)).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity((0.8 + (flashValue * 0.2)).clamp(0.0, 1.0)), width: 2 + (flashValue * 2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(flashOpacity),
                blurRadius: max(0.0, (baseSpread * 1.5) + flashSpread), 
                spreadRadius: max(0.0, pulseSpread + flashSpread),       
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20 + (flashValue * 8)),
              const SizedBox(width: 6),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16 + (flashValue * 4), color: Colors.white, shadows: [Shadow(color: color, blurRadius: max(0.0, flashValue * 15))])), 
            ]
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              Text(
                _loadingText, 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).primaryColor,
                  height: 1.5
                )
              ),
            ]
          )
        )
      );
    }

    var deck = _activeDeck; 
    if (currentCardIndex >= deck.length) currentCardIndex = 0;
    WordModel? currentWord = deck.isNotEmpty ? deck[currentCardIndex] : null;
    bool isSrsMode = currentWord != null && currentWord.listType == 'toSRSRepeat';

    int totalLibWords = allWords.where((w) => w.libraryName == selectedLibrary).length +
                        learningWords.where((w) => w.libraryName == selectedLibrary).length +
                        toRepeatWords.where((w) => w.libraryName == selectedLibrary).length +
                        toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary).length +
                        learnedWords.where((w) => w.libraryName == selectedLibrary).length;
    int learnedLibWords = learnedWords.where((w) => w.libraryName == selectedLibrary).length;
    double progress = totalLibWords > 0 ? (learnedLibWords / totalLibWords) : 0.0;
    double bottomHeight = selectedLibrary != 'Tekrarlanması Gerekenler' ? 90.0 : 60.0;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: false,
        backgroundColor: Colors.transparent, 
        elevation: 0,
        flexibleSpace: RepaintBoundary( 
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.7), Theme.of(context).colorScheme.secondary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lexis Eldora", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(isSrsMode ? "SRS Tekrar Modu" : "$selectedLibrary - $selectedLevel (${deck.length})", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children: [
                  _buildNeonBadge(Icons.local_fire_department, "$currentStreak", Colors.orangeAccent, currentStreak, _streakFlashController),
                  _buildNeonBadge(Icons.ac_unit, "$streakFreezes", Colors.cyanAccent, streakFreezes * 10, _freezeFlashController),
                  _buildNeonBadge(Icons.diamond, "$tayfPoints", Colors.lightBlueAccent, tayfPoints, _tpFlashController),
                ],
              ),
              const SizedBox(height: 12),
              if (selectedLibrary != 'Tekrarlanması Gerekenler') 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("İlerleme:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$learnedLibWords / $totalLibWords Öğrenildi", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent), minHeight: 4),
                      )
                    ]
                  )
                )
            ]
          )
        ),
      ),
      drawer: _buildDrawer(),
      body: AnimatedBuilder(
        animation: _auroraController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.01)], 
                begin: Alignment(-1.0 + (_auroraController.value * 2), -1.0), 
                end: Alignment(1.0 - (_auroraController.value * 2), 1.0)
              )
            ),
            child: child,
          );
        },
        child: currentWord == null 
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amberAccent.withOpacity((0.3 * _glowAnimation.value).clamp(0.0, 1.0)), 
                                blurRadius: 30 * _glowAnimation.value, 
                                spreadRadius: 10 * _glowAnimation.value
                              )
                            ]
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.amberAccent.withOpacity(0.3), size: 100 * _glowAnimation.value),
                                  const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 70),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text("Mükemmel İş Çıkardın!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              const Text("Bu filtredeki tüm kelimelerle çalıştın.\nGünün hedefini başarıyla tamamladın! 🎉", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            )
          : SafeArea(
              bottom: false, 
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            if (isSrsMode)
                              Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.redAccent.shade100.withOpacity(0.2), Colors.orangeAccent.shade100.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 8), Text("SRS Tekrar Zamanı!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))])),
                            const Spacer(),
                            Center(
                              child: Dismissible(
                                key: ValueKey('${currentWord.word}_${DateTime.now()}'), 
                                direction: isFlipped ? DismissDirection.horizontal : DismissDirection.none,
                                background: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color: Colors.green.withOpacity(0.8),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 30),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle, color: Colors.white, size: 50), Text("BİLİYORUM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                                    ),
                                  ),
                                ),
                                secondaryBackground: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 30),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.repeat, color: Colors.white, size: 50), Text("TEKRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                                    ),
                                  ),
                                ),
                                onDismissed: (direction) { if (direction == DismissDirection.startToEnd) _markAsLearned(currentWord); else if (direction == DismissDirection.endToStart) _markAsToRepeat(currentWord); },
                                child: GestureDetector(
                                  onTap: () => _flipCard(currentWord), 
                                  child: AnimatedBuilder(
                                    animation: _flipAnimation,
                                    builder: (context, child) {
                                      final angle = _flipAnimation.value * pi;
                                      return Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle), alignment: Alignment.center, child: angle < (pi / 2) ? _buildCardFront(currentWord) : Transform(transform: Matrix4.identity()..rotateX(pi), alignment: Alignment.center, child: _buildCardBack(currentWord)));
                                    }
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            if (isFlipped) 
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          gradient: const LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]),
                                          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent, 
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white, 
                                            padding: const EdgeInsets.symmetric(vertical: 14), 
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                          ), 
                                          icon: const Icon(Icons.repeat), 
                                          label: const Text("Tekrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                                          onPressed: () => _markAsToRepeat(currentWord)
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    AnimatedBuilder(
                                      animation: _warningPulseController,
                                      builder: (context, child) {
                                        return GestureDetector(
                                          onTap: () => _moveToReview(currentWord),
                                          child: Container(
                                            width: 55, height: 55,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                              border: Border.all(color: Colors.redAccent, width: 3.5),
                                              boxShadow: [
                                                BoxShadow(color: Colors.yellowAccent.withOpacity(0.7 * _warningPulseController.value), blurRadius: 15, spreadRadius: 3)
                                              ]
                                            ),
                                            child: const Center(
                                              child: Text(
                                                "!", 
                                                style: TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 10)])
                                              )
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.teal]),
                                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent, 
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white, 
                                            padding: const EdgeInsets.symmetric(vertical: 14), 
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                          ), 
                                          icon: const Icon(Icons.check), 
                                          label: const Text("Biliyorum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                                          onPressed: () => _markAsLearned(currentWord)
                                        ),
                                      ),
                                    )
                                  ]
                                ),
                              ),
                            const Spacer(),
                            
                            ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.only(top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
                                  width: double.infinity,
                                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("V2.0.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                          const SizedBox(width: 16),
                                          Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor.withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}
