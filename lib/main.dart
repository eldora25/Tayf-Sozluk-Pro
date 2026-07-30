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
    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent), appBarTheme: const AppBarTheme(elevation: 0));
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(elevation: 0));
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[600], scaffoldBackgroundColor: const Color(0xFFF3F8FF), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: AppBarTheme(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, elevation: 0));
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[600], scaffoldBackgroundColor: const Color(0xFFF2FAF9), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: AppBarTheme(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, elevation: 0));
      case 4: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: const Color(0xFFF8F3FF), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, elevation: 0));
      case 5: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: const Color(0xFFFFF6F0), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, elevation: 0));
      case 6: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.pink, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: const Color(0xFFFFF0F5), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.pink), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, elevation: 0));
      case 7: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.cyan, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: const Color(0xFFFFFDF5), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.cyan), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, elevation: 0));
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
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

  List<WordModel> allWords = [];
  List<WordModel> learningWords = []; 
  List<WordModel> learnedWords = [];
  List<WordModel> toRepeatWords = [];
  List<WordModel> toSRSRepeatWords = []; 
  List<WordModel> wrongWords = []; 

  String selectedLibrary = 'Varsayılan';
  String selectedLevel = 'Genel';
  int dailyGoal = 10, quizThreshold = 10, quizQuestionCount = 10, currentCardIndex = 0;
  bool isFlipped = false;
  int totalCompletedQuizzes = 0, totalQuizTimeSeconds = 0, totalQuizQuestions = 0, totalQuizWrong = 0;
  List<String> learnedWordTimestamps = [], completedQuizTimestamps = [], viewedCardTimestamps = [], wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0, currentStreak = 0, bestStreak = 0, tayfPoints = 0, streakFreezes = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    NotificationService.requestPermission();
    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
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
        totalCompletedQuizzes = prefs.getInt('totalCompletedQuizzes') ?? 0;
        totalQuizTimeSeconds = prefs.getInt('totalQuizTimeSeconds') ?? 0;
        totalQuizQuestions = prefs.getInt('totalQuizQuestions') ?? 0;
        totalQuizWrong = prefs.getInt('totalQuizWrong') ?? 0;
        tayfPoints = prefs.getInt('tayfPoints') ?? 0;
      });

      List<WordModel> fromIsar = await isar.wordModels.where().findAll();

      setState(() {
        allWords = fromIsar.where((w) => w.listType == 'all').toList();
        learningWords = fromIsar.where((w) => w.listType == 'learning').toList();
        learnedWords = fromIsar.where((w) => w.listType == 'learned').toList();
        
        List<WordModel> tempToRepeat = fromIsar.where((w) => w.listType == 'toRepeat').toList();
        toRepeatWords = tempToRepeat.where((w) => w.srsLevel == 0).toList();
        toSRSRepeatWords = fromIsar.where((w) => w.listType == 'toSRSRepeat').toList()
          ..addAll(tempToRepeat.where((w) => w.srsLevel > 0)); 

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
          isar.writeTxn(() async { await isar.wordModels.putAll(toSRSRepeatWords); });
        }

        wrongWords = [...allWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords, ...learnedWords].where((w) => w.wrongCount > 0).toList();
        if (allWords.isEmpty && learnedWords.isEmpty && toRepeatWords.isEmpty && toSRSRepeatWords.isEmpty && learningWords.isEmpty) {
          _createDefaultLibrary();
        }

        // -------------------------------------------------------------
        // YENİ: SRS VE DEMO ÖNCELİK (PRIORITY) ZIRHI
        // Eğer destede acil (günü gelmiş SRS veya Demo) kartlar varsa 
        // ve index bunları ES GEÇMİŞSE (ileride kalmışsa), zorla başa (0) sar!
        // -------------------------------------------------------------
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
    } catch (e) {}
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedLibrary', selectedLibrary);
      prefs.setString('selectedLevel', selectedLevel);
      prefs.setInt('quizThreshold', quizThreshold);
      prefs.setInt('tayfPoints', tayfPoints);
      prefs.setInt('currentCardIndex', currentCardIndex);
      prefs.setInt('totalCompletedQuizzes', totalCompletedQuizzes);
      prefs.setInt('totalQuizTimeSeconds', totalQuizTimeSeconds);
      prefs.setInt('totalQuizQuestions', totalQuizQuestions);
      prefs.setInt('totalQuizWrong', totalQuizWrong);

      for (var w in allWords) { w.listType = 'all'; }
      for (var w in learningWords) { w.listType = 'learning'; }
      for (var w in toRepeatWords) { w.listType = 'toRepeat'; }
      for (var w in toSRSRepeatWords) { w.listType = 'toSRSRepeat'; }
      for (var w in learnedWords) { w.listType = 'learned'; }

      List<WordModel> allToSave = [...allWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords, ...learnedWords];
      await isar.writeTxn(() async { await isar.wordModels.putAll(allToSave); });
    } catch (e) {}
  }

  void _recordActivity(int pointsEarned) {
    setState(() => tayfPoints += pointsEarned);
    _saveData();
  }

  void _buyFreeze() {
    HapticFeedback.mediumImpact(); 
    if (tayfPoints >= 50) {
      setState(() { tayfPoints -= 50; streakFreezes++; });
      _saveData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buz Kalkanı satın alındı! ❄️"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz Tayf Puanı (TP)."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  void _createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
    ];
    _saveData();
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

  void _nextCard() {
    HapticFeedback.lightImpact(); 
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
      currentCardIndex++;
    });
    _saveData();
    var deck = activeDeck;
    if (deck.isNotEmpty) {
      if (currentCardIndex >= deck.length) currentCardIndex = 0;
      _speakWord(deck[currentCardIndex], isMeaning: false);
    }
  }

  void _flipCard(WordModel word) {
    HapticFeedback.selectionClick(); 
    if (isFlipped) { _flipController.reverse(); _speakWord(word, isMeaning: false); } 
    else { _flipController.forward(); _speakWord(word, isMeaning: true); viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); }
    setState(() => isFlipped = !isFlipped);
  }

  void _markAsLearned(WordModel word, {bool fromQuiz = false}) {
    if (!fromQuiz) { HapticFeedback.heavyImpact(); _recordActivity(1); }
    
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
      
      if (!fromQuiz) _nextCard(); 
      else _saveData(); 
    });
  }

  void _markAsToRepeat(WordModel word, {bool fromQuiz = false}) {
    if (!fromQuiz) { HapticFeedback.mediumImpact(); _recordActivity(0); }
    
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
      
      if (!fromQuiz) _nextCard();
      else _saveData();
    });
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
          _saveData();
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
        _saveData();
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
      if (selectedLibrary == oldName) selectedLibrary = newName;
    });
    _saveData();
  }

  void _deleteLibrary(String libName) {
    setState(() {
      allWords.removeWhere((w) => w.libraryName == libName);
      learnedWords.removeWhere((w) => w.libraryName == libName);
      toRepeatWords.removeWhere((w) => w.libraryName == libName);
      toSRSRepeatWords.removeWhere((w) => w.libraryName == libName);
      learningWords.removeWhere((w) => w.libraryName == libName);
      wrongWords.removeWhere((w) => w.libraryName == libName);
      if (selectedLibrary == libName) selectedLibrary = 'Varsayılan';
    });
    _saveData();
  }

  Future<void> _exportLibrary(String libName) async {
    if (libName == 'Tekrarlanması Gerekenler') return;
    List<WordModel> exportList = allWords.where((w) => w.libraryName == libName).toList()
                               ..addAll(learnedWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(toRepeatWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(toSRSRepeatWords.where((w) => w.libraryName == libName).toList())
                               ..addAll(learningWords.where((w) => w.libraryName == libName).toList());
    if (exportList.isEmpty) return;
    List<List<dynamic>> rows = exportList.map((w) => [w.word, w.meanings.join('|||'), w.examples.join('|||'), w.level]).toList();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$libName.csv');
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    await Share.shareXFiles([XFile(file.path)], text: '$libName Yedeği');
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
          } else if (action == EditAction.update || action == EditAction.move) {
            allWords.removeWhere((w) => w.id == word.id);
            toRepeatWords.removeWhere((w) => w.id == word.id);
            toSRSRepeatWords.removeWhere((w) => w.id == word.id);
            learningWords.removeWhere((w) => w.id == word.id);
            wrongWords.removeWhere((w) => w.id == word.id);
            learnedWords.removeWhere((w) => w.id == word.id);
            
            if (selectedLibrary == 'Tekrarlanması Gerekenler') {
              if (updatedWord.srsLevel > 0) toSRSRepeatWords.add(updatedWord); 
              else toRepeatWords.add(updatedWord);
            } else { allWords.add(updatedWord); }
          } else if (action == EditAction.copy) { allWords.add(updatedWord); }
          currentCardIndex = 0;
        });
        _saveData();
      },
    )));
  }

  Widget _buildCardFront(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isPremium = level > 0;
    
    List<Color> neonColors = const [
      Color(0xFF00E5FF), 
      Color(0xFF00E676), 
      Color(0xFFFFEA00), 
      Color(0xFFFF3D00), 
      Color(0xFFFF0055), 
    ];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          
          Widget cardContent = Container(
            width: 300, height: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16)
            ),
            child: Column(
              children: [
                if (isPremium) 
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 12), 
                    decoration: BoxDecoration(
                      color: neonColors[level - 1].withOpacity(0.15), 
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: neonColors[level - 1].withOpacity(0.5), width: 2))
                    ), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: neonColors[level - 1], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "SRS Seviye: $level / 5", 
                          style: TextStyle(color: neonColors[level - 1], fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)
                        ),
                      ],
                    )
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))))), 
                      Positioned(right: 5, top: 5, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: false))), 
                      Positioned(left: 5, top: 5, child: IconButton(icon: const Icon(Icons.settings, size: 28, color: Colors.grey), onPressed: () => _openEditScreen(word)))
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;

          if (isPremium) {
            for (int i = 0; i < level; i++) {
              current = Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 + ((i + 1) * 4.0)),
                  border: Border.all(color: Colors.black.withOpacity(0.3), width: 1.5), 
                  gradient: LinearGradient(
                    colors: [neonColors[i].withOpacity(0.9), neonColors[i]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: (i == level - 1) ? [
                    BoxShadow(
                      color: neonColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)),
                      blurRadius: 25 * _glowAnimation.value,
                      spreadRadius: 6 * _glowAnimation.value,
                    )
                  ] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(2),
               decoration: BoxDecoration(
                 color: Theme.of(context).primaryColor,
                 borderRadius: BorderRadius.circular(18),
                 boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
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
    
    List<Color> neonColors = const [
      Color(0xFF00E5FF), 
      Color(0xFF00E676), 
      Color(0xFFFFEA00), 
      Color(0xFFFF3D00), 
      Color(0xFFFF0055), 
    ];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          
          Widget cardContent = Container(
            width: 300, height: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16)
            ),
            child: Column(
              children: [
                if (isPremium) 
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 12), 
                    decoration: BoxDecoration(
                      color: neonColors[level - 1].withOpacity(0.15), 
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: neonColors[level - 1].withOpacity(0.5), width: 2))
                    ), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: neonColors[level - 1], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "SRS Seviye: $level / 5", 
                          style: TextStyle(color: neonColors[level - 1], fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)
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
                          padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), 
                              const Divider(), 
                              ...word.meanings.map((m) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0), 
                                child: Text("• $m", style: const TextStyle(fontSize: 16, height: 1.4))
                              )),
                              if (word.examples.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text("Örnekler:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                const SizedBox(height: 4),
                                ...word.examples.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text("» $e", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.4))
                                )),
                              ]
                            ]
                          )
                        )
                      ), 
                      Positioned(right: 5, top: 0, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: true))), 
                      Positioned(left: 5, top: 0, child: IconButton(icon: const Icon(Icons.settings, size: 28, color: Colors.grey), onPressed: () => _openEditScreen(word)))
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;

          if (isPremium) {
            for (int i = 0; i < level; i++) {
              current = Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 + ((i + 1) * 4.0)),
                  border: Border.all(color: Colors.black.withOpacity(0.3), width: 1.5),
                  gradient: LinearGradient(
                    colors: [neonColors[i].withOpacity(0.9), neonColors[i]],
                    begin: Alignment.bottomRight, 
                    end: Alignment.topLeft,
                  ),
                  boxShadow: (i == level - 1) ? [
                    BoxShadow(
                      color: neonColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)),
                      blurRadius: 25 * _glowAnimation.value,
                      spreadRadius: 6 * _glowAnimation.value,
                    )
                  ] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(2),
               decoration: BoxDecoration(
                 color: Colors.green,
                 borderRadius: BorderRadius.circular(18),
                 boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Icon(Icons.language, color: Colors.white, size: 40),
                          const SizedBox(height: 10),
                          const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("Build v1.0.$buildNo", style: const TextStyle(color: Colors.white70))
                        ],
                      ),
                    ),
                    ListTile(tileColor: Colors.blue.withOpacity(0.1), leading: const Icon(Icons.ac_unit, color: Colors.blue), title: const Text("Buz Kalkanı Al (50 💎)", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Mevcut Kalkan: $streakFreezes ❄️\nSerinin bozulmasını engeller."), onTap: () { Navigator.pop(context); _buyFreeze(); }),
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.indigo), 
                      title: const Text("WordNet Kütüphanesi", style: TextStyle(fontWeight: FontWeight.bold)), 
                      subtitle: const Text("Detaylı İng-İng Sözlük"), 
                      onTap: () { 
                        HapticFeedback.lightImpact(); 
                        Navigator.pop(context); 
                        _showCenteredDialog(
                          title: "WordNet Kütüphanesi", 
                          message: "Yazılımcı halen çalışıyor... 😅\n\nÇok yakında harika bir İngilizce-İngilizce sözlük deneyimiyle karşınızda olacak!", 
                          icon: Icons.code, 
                          color: Colors.indigo
                        );
                      }
                    ),
                    
                    ListTile(leading: const Icon(Icons.add_box), title: const Text("Kelime Ekle"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(availableLibraries: availableLibraries, onSave: (w) { setState(() => allWords.add(w)); _saveData(); }))); }),
                    ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: activeDeck, onDelete: (w) { setState(() { allWords.remove(w); toRepeatWords.remove(w); toSRSRepeatWords.remove(w); }); _saveData(); }, onLearned: _markAsLearned))); }),
                    
                    ListTile(
                      leading: const Icon(Icons.settings), 
                      title: const Text("Ayarlar, Temalar, Seçimler"), 
                      onTap: () { 
                        HapticFeedback.lightImpact();
                        Navigator.pop(context); 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                          currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, availableLibraries: availableLibraries, 
                          onSaveSettings: (nG, nT, nQC, nTI, nL, nLv) { 
                            setState(() { quizThreshold = nT; widget.onThemeChanged(nTI); selectedLibrary = nL; selectedLevel = nLv; }); 
                            _saveData(); 
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
                    ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: const Text("Öğrenilen Kelimeler"), subtitle: Text("${learnedWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Öğrenilen Kelimeler", words: learnedWords, onDelete: (w) { setState(() => learnedWords.remove(w)); _saveData(); }, onClearAll: () { setState(() => learnedWords.clear()); _saveData(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                    ListTile(leading: const Icon(Icons.repeat, color: Colors.orange), title: const Text("Tekrar Listesi (Normal)"), subtitle: Text("${toRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Tekrar Listesi", words: toRepeatWords, onDelete: (w) { setState(() => toRepeatWords.remove(w)); _saveData(); }, onClearAll: () { setState(() => toRepeatWords.clear()); _saveData(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                    ListTile(leading: const Icon(Icons.schedule, color: Colors.blue), title: const Text("SRS Tekrar Listesi"), subtitle: Text("${toSRSRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "SRS Tekrar Listesi", words: toSRSRepeatWords, showSrsLevel: true, onDelete: (w) { setState(() => toSRSRepeatWords.remove(w)); _saveData(); }, onClearAll: () { setState(() => toSRSRepeatWords.clear()); _saveData(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                    ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text("Yanlış Kelimeler"), subtitle: Text("${wrongWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Yanlış Kelimeler", words: wrongWords, showWrongCount: true, onDelete: (w) { setState(() => wrongWords.remove(w)); _saveData(); }, onClearAll: () { setState(() => wrongWords.clear()); _saveData(); }, onEdit: _openEditScreen))).then((_) => setState((){})); }),
                    
                    const Divider(),
                    ListTile(leading: const Icon(Icons.my_library_books), title: const Text("Kütüphane Yönetimi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(allWords: allWords, learningWords: learningWords, learnedWords: learnedWords, toRepeatWords: [...toRepeatWords, ...toSRSRepeatWords], wrongWords: wrongWords, onRename: _renameLibrary, onDelete: _deleteLibrary, onExport: _exportLibrary))); }),
                    ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: activeDeck, onGameFinished: (points) { _recordActivity(points); _saveData(); }))); }),
                    ListTile(leading: const Icon(Icons.mic, color: Colors.teal), title: const Text("Telaffuz Sınavı"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => PronunciationScreen(words: activeDeck, onGameFinished: (points) { _recordActivity(points); _saveData(); }))); }),
                    
                    ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { 
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); 
                      List<WordModel> fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                        words: fullPool, threshold: quizThreshold, questionCount: quizQuestionCount, 
                        onWordMastered: (w) => _markAsLearned(w, fromQuiz: true), 
                        onWrongWord: (w) => _markAsToRepeat(w, fromQuiz: true), 
                        onQuizFinished: (t, a, w) { 
                          setState(() {
                            totalCompletedQuizzes++;
                            totalQuizTimeSeconds += t;
                            totalQuizQuestions += a;
                            totalQuizWrong += w;
                          });
                          _saveData(); 
                        }
                      ))); 
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
                      
                      setState(() {
                        selectedLibrary = 'Tekrarlanması Gerekenler';
                        currentCardIndex = 0;
                        isFlipped = false;
                      });
                      
                      _loadData();
                    }),
                    ListTile(leading: const Icon(Icons.bug_report, color: Colors.orange), title: const Text("Hata Kayıtları (Log)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LoggerScreen())); }),
                    const Divider(),
                    ListTile(leading: const Icon(Icons.info_outline, color: Colors.indigo), title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen())); }),
                    ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); _importFile(); }),
                    ListTile(leading: const Icon(Icons.share), title: const Text("Paylaş / Dışa Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); _exportLibrary(selectedLibrary); }),
                  ],
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 16 + MediaQuery.of(context).padding.bottom), 
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1))
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("V1.0.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.purpleAccent.shade400, Colors.deepPurple]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                      ),
                      child: const Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var deck = activeDeck;
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
      // YENİ APPBAR TASARIMI (Taşmaları Engelleyen Ortalanmış Düzen)
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(isSrsMode ? "SRS Tekrar Modu" : "$selectedLibrary - $selectedLevel (${deck.length})", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8), 
                      borderRadius: BorderRadius.circular(30), 
                      border: Border.all(color: Colors.orangeAccent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                    ), 
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Kapsül taşmasını engeller
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24), 
                        const SizedBox(width: 6), 
                        Text("$currentStreak", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white))
                      ]
                    )
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8), 
                      borderRadius: BorderRadius.circular(30), 
                      border: Border.all(color: Colors.lightBlueAccent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                    ), 
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Kapsül taşmasını engeller
                      children: [
                        const Icon(Icons.diamond, color: Colors.lightBlueAccent, size: 24), 
                        const SizedBox(width: 6), 
                        Text("$tayfPoints", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white))
                      ]
                    )
                  ),
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
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          minHeight: 4,
                        )
                      )
                    ]
                  )
                )
            ]
          )
        ),
      ),
      drawer: _buildDrawer(),
      body: currentWord == null 
        ? const Center(child: Text("Harika! Bu filtrede çalışılacak kelime kalmadı."))
        : SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
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
                              background: Row(mainAxisAlignment: MainAxisAlignment.start, children: const [SizedBox(width: 30), Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green, size: 50), Text("BİLİYORUM", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))])]),
                              secondaryBackground: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.repeat, color: Colors.redAccent, size: 50), Text("TEKRAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))]), SizedBox(width: 30)]),
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
                          if (isFlipped) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 5, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), icon: const Icon(Icons.repeat), label: const Text("Tekrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), onPressed: () => _markAsToRepeat(currentWord)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 5, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), icon: const Icon(Icons.check), label: const Text("Biliyorum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), onPressed: () => _markAsLearned(currentWord))]),
                          const Spacer(),
                          
                          Container(
                            padding: EdgeInsets.only(top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
                            width: double.infinity,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("V1.0.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                    const SizedBox(width: 16),
                                    Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor.withOpacity(0.5))),
                              ],
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
    );
  }
}
