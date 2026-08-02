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

// Firebase Kütüphaneleri ve Senkronizasyon Servisi
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_sync_service.dart';

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
              parsedList.add(json.encode({'word': sw, 'meanings': cleanM, 'examples': cleanE, 'level': item['level']?.toString() ?? 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
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
              parsedList.add(json.encode({'word': w, 'meanings': meanings, 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
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
              parsedList.add(json.encode({'word': w, 'meanings': mList, 'examples': eList, 'level': level, 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
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
    
    final PageTransitionsTheme smoothTransitions = const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
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
      themeAnimationDuration: const Duration(milliseconds: 600), 
      themeAnimationCurve: Curves.easeInOutCubic,
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

  List<WordModel> allWords = [];
  List<WordModel> learningWords = []; 
  List<WordModel> learnedWords = [];
  List<WordModel> toRepeatWords = [];
  List<WordModel> toSRSRepeatWords = []; 
  List<WordModel> wrongWords = []; 
  List<WordModel> reviewWordsPool = []; 

  String selectedLibrary = 'Varsayılan';
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

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        selectedLibrary = prefs.getString('selectedLibrary') ?? 'Varsayılan';
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

      // PERFORMANS OPTİMİZASYONU: Paralel Sorgu Altyapısı (Future.wait)
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

      setState(() {
        var deck = activeDeck;
        int urgentCount = deck.where((w) => w.listType == 'toSRSRepeat' || w.listType == 'toRepeat').length;
        
        if (urgentCount > 0 && currentCardIndex >= urgentCount) {
          currentCardIndex = 0;
          isFlipped = false;
        } else if (deck.isNotEmpty && currentCardIndex >= deck.length) {
          currentCardIndex = 0;
          isFlipped = false;
        }
      });
    } catch (e) {
      debugPrint("Load Data Error: $e");
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

  List<WordModel> get activeDeck {
    List<WordModel> deck = [];
    if (selectedLibrary == 'Tekrarlanması Gerekenler') {
      deck.addAll(toSRSRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
      deck.addAll(toRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
    } else {
      deck.addAll(toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      deck.addAll(toRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      deck.addAll(allWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
    }
    return deck;
  }

  List<String> get availableLibraries {
    var libs = allWords.map((e) => e.libraryName).toSet().toList()
      ..addAll(learnedWords.map((e) => e.libraryName))
      ..addAll(toRepeatWords.map((e) => e.libraryName))
      ..addAll(toSRSRepeatWords.map((e) => e.libraryName))
      ..addAll(learningWords.map((e) => e.libraryName)); 
    var uniqueLibs = libs.toSet().toList();
    uniqueLibs.add('Tekrarlanması Gerekenler'); 
    return uniqueLibs;
  }

  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
    try {
      await globalTts.stop(); 
      String rawText = "";

      if (isMeaning) {
        List<String> combinedList = [...word.meanings, ...word.examples];
        if (combinedList.isEmpty) return;
        rawText = combinedList.join('. '); 
      } else {
        rawText = word.word;
      }

      if (rawText.isEmpty) return;
      
      String cleanText = rawText.replaceAll(RegExp(r'[\[\]\{\}\\|_»•]'), ' ').replaceAll('ANLAM:', '');
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
    var deck = activeDeck;
    if (deck.isNotEmpty) {
      if (currentCardIndex >= deck.length) currentCardIndex = 0;
      _speakWord(deck[currentCardIndex], isMeaning: false);
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

  void _markAsLearned(WordModel word, {bool fromQuiz = false}) {
    if (!fromQuiz) { 
      HapticFeedback.heavyImpact(); 
      _recordActivity(1); 
    }
    learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    
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
    });

    isar.writeTxnSync(() { isar.wordModels.putSync(word); });

    if (!fromQuiz) _nextCard(increment: false); 
    else _savePreferencesOnly(); 
  }

  void _markAsToRepeat(WordModel word, {bool fromQuiz = false}) {
    if (!fromQuiz) { 
      HapticFeedback.mediumImpact(); 
      _recordActivity(0); 
    }
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
    });

    isar.writeTxnSync(() { isar.wordModels.putSync(word); });

    if (!fromQuiz) _nextCard(increment: true);
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
      
      reviewWordsPool.add(word);
    });

    isar.writeTxnSync(() { isar.wordModels.putSync(word); });
    
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

  void _renameLibrary(String oldName, String newName) {
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
    
    isar.writeTxn(() async {
      List<WordModel> toUpdate = await isar.wordModels.filter().libraryNameEqualTo(oldName).findAll();
      for (var w in toUpdate) { w.libraryName = newName; }
      await isar.wordModels.putAll(toUpdate);
    });
    _savePreferencesOnly();
  }

  void _deleteLibrary(String libName) {
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
      word: word, availableLibraries: availableLibraries,
      onAction: (action, updatedWord) {
        setState(() {
          if (action == EditAction.delete) {
            allWords.removeWhere((w) => w.id == word.id);
            toRepeatWords.removeWhere((w) => w.id == word.id);
            toSRSRepeatWords.removeWhere((w) => w.id == word.id);
            learningWords.removeWhere((w) => w.id == word.id);
            wrongWords.removeWhere((w) => w.id == word.id);
            learnedWords.removeWhere((w) => w.id == word.id);
            reviewWordsPool.removeWhere((w) => w.id == word.id);
            isar.writeTxn(() async { await isar.wordModels.delete(word.id); });
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
            isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          } else if (action == EditAction.copy) { 
            allWords.add(updatedWord); 
            isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          }
          currentCardIndex = 0;
        });
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

  Widget _buildCardFront(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isPremium = level > 0;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320, 
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                if (isPremium || isMitosis) 
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 8), 
                    decoration: BoxDecoration(
                      color: isPremium ? distinctColors[level - 1].withOpacity(0.15) : Colors.purpleAccent.withOpacity(0.15), 
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
                      border: Border(bottom: BorderSide(color: isPremium ? distinctColors[level - 1].withOpacity(0.5) : Colors.purpleAccent.withOpacity(0.5), width: 2))
                    ), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPremium) _buildCrown(level, isMitosis), 
                        if (isPremium) const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isMitosis) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.biotech, size: 16, color: isPremium ? distinctColors[level - 1] : Colors.purpleAccent)),
                            if (isPremium) Icon(Icons.stars, color: distinctColors[level - 1], size: 16),
                            if (isPremium) const SizedBox(width: 8),
                            Text(
                              isPremium ? (isMitosis ? "SRS: $level / 5 (Saf Kart)" : "SRS Seviye: $level / 5") : "Yeni Saf Kart (Mitoz)", 
                              style: TextStyle(
                                color: isPremium ? distinctColors[level - 1] : Colors.purpleAccent, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14, 
                                letterSpacing: 1.5,
                              )
                            ),
                          ],
                        ),
                      ],
                    )
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(word.word, textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _getTextColor(context, isDark, isMitosis)))))), 
                      Positioned(right: 5, top: 5, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => _speakWord(word, isMeaning: false))), 
                      Positioned(left: 5, top: 5, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => _openEditScreen(word))),
                      
                      if (isMitosis)
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
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white30, width: 1),
                                      boxShadow: [
                                        BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)),
                                        BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0)),
                                      ]
                                    ),
                                    child: Transform.rotate(
                                      angle: 0.5,
                                      child: const Text(
                                        "\u{1F9EC}", 
                                        style: TextStyle(
                                          fontSize: 16, 
                                          shadows: [
                                            Shadow(color: Colors.orangeAccent, blurRadius: 15),
                                            Shadow(color: Colors.purpleAccent, blurRadius: 15),
                                          ]
                                        )
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1),
                                    boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]
                                  ),
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
          if (isPremium) {
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
                 color: isMitosis ? Colors.purpleAccent : Theme.of(context).primaryColor,
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
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
    bool isPremium = level > 0;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320,
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                if (isPremium || isMitosis) 
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 8), 
                    decoration: BoxDecoration(
                      color: isPremium ? distinctColors[level - 1].withOpacity(0.15) : Colors.purpleAccent.withOpacity(0.15), 
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
                      border: Border(bottom: BorderSide(color: isPremium ? distinctColors[level - 1].withOpacity(0.5) : Colors.purpleAccent.withOpacity(0.5), width: 2))
                    ), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPremium) _buildCrown(level, isMitosis), 
                        if (isPremium) const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isMitosis) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.biotech, size: 16, color: isPremium ? distinctColors[level - 1] : Colors.purpleAccent)),
                            if (isPremium) Icon(Icons.stars, color: distinctColors[level - 1], size: 16),
                            if (isPremium) const SizedBox(width: 8),
                            Text(
                              isPremium ? (isMitosis ? "SRS: $level / 5 (Saf Kart)" : "SRS Seviye: $level / 5") : "Yeni Saf Kart (Mitoz)", 
                              style: TextStyle(
                                color: isPremium ? distinctColors[level - 1] : Colors.purpleAccent, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14, 
                                letterSpacing: 1.5,
                              )
                            ),
                          ],
                        ),
                      ],
                    )
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0, left: 20, right: 20, bottom: 40), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Text(word.word, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _getTextColor(context, isDark, isMitosis)))), 
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: (_getTextColor(context, isDark, isMitosis)).withOpacity(0.3))), 
                              ...word.meanings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text("• " + m, style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                              if (word.examples.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text("Örnekler:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isMitosis ? Colors.pinkAccent : Theme.of(context).colorScheme.secondary)),
                                const SizedBox(height: 6),
                                ...word.examples.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text("» " + e, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4, color: _getTextColor(context, isDark, isMitosis))))),
                              ]
                            ]
                          )
                        )
                      ), 
                      Positioned(right: 5, top: 0, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => _speakWord(word, isMeaning: true))), 
                      Positioned(left: 5, top: 0, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => _openEditScreen(word))),
                      
                      if (isMitosis)
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
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white30, width: 1),
                                      boxShadow: [
                                        BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)),
                                        BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0)),
                                      ]
                                    ),
                                    child: Transform.rotate(
                                      angle: 0.5,
                                      child: const Text(
                                        "\u{1F9EC}", 
                                        style: TextStyle(
                                          fontSize: 16, 
                                          shadows: [
                                            Shadow(color: Colors.orangeAccent, blurRadius: 15),
                                            Shadow(color: Colors.purpleAccent, blurRadius: 15),
                                          ]
                                        )
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1),
                                    boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]
                                  ),
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
          if (isPremium) {
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
                 color: isMitosis ? Colors.purpleAccent : Colors.green, 
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Colors.green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
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
                      leading: const Icon(Icons.language, color: Colors.indigo), 
                      title: const Text("WordNet Kütüphanesi", style: TextStyle(fontWeight: FontWeight.bold)), 
                      subtitle: const Text("Detaylı İng-İng Sözlük"), 
                      onTap: () { 
                        HapticFeedback.lightImpact(); 
                        Navigator.pop(context); 
                        _showCenteredDialog(title: "WordNet Kütüphanesi", message: "Yazılımcı halen çalışıyor... 😅\n\nÇok yakında harika bir İngilizce-İngilizce sözlük deneyimiyle karşınızda olacak!", icon: Icons.code, color: Colors.indigo);
                      }
                    ),
                    
                    ListTile(leading: const Icon(Icons.add_box), title: const Text("Kelime Ekle"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(availableLibraries: availableLibraries, onSave: (w) { setState(() => allWords.add(w)); _savePreferencesOnly(); }))); }),
                    ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: activeDeck, onDelete: (w) { setState(() { allWords.remove(w); toRepeatWords.remove(w); toSRSRepeatWords.remove(w); }); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); _savePreferencesOnly(); }, onLearned: _markAsLearned))); }),
                    
                    ListTile(
                      leading: const Icon(Icons.settings), 
                      title: const Text("Ayarlar, Temalar, Seçimler"), 
                      onTap: () { 
                        HapticFeedback.lightImpact();
                        Navigator.pop(context); 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                          currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, availableLibraries: availableLibraries, 
                          onSaveSettings: (nG, nT, nQC, nTI, nL, nLv) { 
                            setState(() { dailyGoal = nG; quizThreshold = nT; quizQuestionCount = nQC; widget.onThemeChanged(nTI); selectedLibrary = nL; selectedLevel = nLv; }); 
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
                    ListTile(leading: const Icon(Icons.my_library_books), title: const Text("Kütüphane Yönetimi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(allWords: allWords, learningWords: learningWords, learnedWords: learnedWords, toRepeatWords: [...toRepeatWords, ...toSRSRepeatWords], wrongWords: wrongWords, onRename: _renameLibrary, onDelete: _deleteLibrary, onExport: _exportLibrary))); }),
                    ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: activeDeck, onGameFinished: (points) { _recordActivity(points); _savePreferencesOnly(); }))); }),
                    ListTile(leading: const Icon(Icons.mic, color: Colors.teal), title: const Text("Telaffuz Sınavı"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => PronunciationScreen(words: activeDeck, onGameFinished: (points) { _recordActivity(points); _savePreferencesOnly(); }))); }),
                    
                    ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { 
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); 
                      List<WordModel> fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList();
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
                    
                    ListTile(leading: const Icon(Icons.analytics), title: const Text("İstatistikler & Rozetler"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(allWords: allWords, learningWords: learningWords, toRepeatWords: toRepeatWords, toSRSRepeatWords: toSRSRepeatWords, learnedWords: learnedWords, wrongWords: wrongWords, availableLibraries: availableLibraries, totalCompletedQuizzes: totalCompletedQuizzes, totalQuizTimeSeconds: totalQuizTimeSeconds, totalQuizQuestions: totalQuizQuestions, totalQuizWrong: totalQuizWrong, learnedWordTimestamps: learnedWordTimestamps, completedQuizTimestamps: completedQuizTimestamps, viewedCardTimestamps: viewedCardTimestamps, wrongAnswerTimestamps: wrongAnswerTimestamps, firstUseTimestamp: firstUseTimestamp, bestStreak: bestStreak, tayfPoints: tayfPoints))); }), 
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
    );
  }
}
