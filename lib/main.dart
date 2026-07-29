import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
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
  String name = libraryName.toLowerCase();
  
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng')) return 'tr-TR';
  if (name.contains('tr-alm') || name.contains('tr-deu') || name.contains('tur-ger')) return 'tr-TR';
  if (name.contains('tr-fra') || name.contains('tr-fre')) return 'tr-TR';
  if (name.contains('tr-isp') || name.contains('tr-spa')) return 'tr-TR';
  if (name.contains('tr-rus')) return 'tr-TR';

  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur')) return 'en-US';
  if (name.contains('alm-tr') || name.contains('deu-tr') || name.contains('ger-tr')) return 'de-DE';
  if (name.contains('fra-tr') || name.contains('fre-tr')) return 'fr-FR';
  if (name.contains('isp-tr') || name.contains('spa-tr')) return 'es-ES';
  if (name.contains('rus-tr')) return 'ru-RU';
  
  if (name.contains('ing') || name.contains('eng') || name.contains('wordnet')) return 'en-US';
  if (name.contains('alm') || name.contains('deu') || name.contains('ger')) return 'de-DE';
  if (name.contains('fra') || name.contains('fre')) return 'fr-FR';
  if (name.contains('isp') || name.contains('spa')) return 'es-ES';
  if (name.contains('rus')) return 'ru-RU';
  
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(wordText)) return 'tr-TR';
  
  return 'en-US'; 
}

String getSmartTargetLanguage(String libraryName, String meaningText) {
  String name = libraryName.toLowerCase();
  
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng')) return 'en-US';
  if (name.contains('tr-alm') || name.contains('tr-deu') || name.contains('tur-ger')) return 'de-DE';
  if (name.contains('tr-fra') || name.contains('tr-fre')) return 'fr-FR';
  if (name.contains('tr-isp') || name.contains('tr-spa')) return 'es-ES';
  if (name.contains('tr-rus')) return 'ru-RU';

  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur')) return 'tr-TR';
  if (name.contains('alm-tr') || name.contains('deu-tr') || name.contains('ger-tr')) return 'tr-TR';
  if (name.contains('fra-tr') || name.contains('fre-tr')) return 'tr-TR';
  if (name.contains('isp-tr') || name.contains('spa-tr')) return 'tr-TR';
  if (name.contains('rus-tr')) return 'tr-TR';

  if (name.contains('wordnet') || name.contains('eng-eng')) return 'en-US'; 
  
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(meaningText)) return 'tr-TR';
  if (RegExp(r'[qwxQWX]').hasMatch(meaningText)) return 'en-US';
  
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

List<String> parseLibraryDataInBackground(Map<String, dynamic> params) {
  String content = params['content'];
  String extension = params['extension'];
  String customLibraryName = params['libraryName'];

  List<String> parsedList = [];
  String lowerName = customLibraryName.toLowerCase();

  try {
    // 1. ÖZEL AYRIŞTIRICI: WORDNET (JSON)
    if (lowerName.contains('wordnet') || extension == 'json') {
      var decoded = json.decode(content);
      List list = decoded is Map ? (decoded['words'] ?? decoded) : decoded;
      
      for (var e in list) {
        if (e is Map) {
          String actualWord = e['word']?.toString() ?? '';
          bool isId = RegExp(r'^[0-9]{8}-[a-zA-Z]$').hasMatch(actualWord);
          
          List<dynamic> synsList = e['synonyms'] is List ? e['synonyms'] : [];
          List<dynamic> antsList = e['antonyms'] is List ? e['antonyms'] : [];
          
          if (isId || actualWord.isEmpty || actualWord == 'null') {
            if (synsList.isNotEmpty) {
              actualWord = synsList[0].toString();
            } else {
              actualWord = "WordNet Terimi"; 
            }
          }

          List<String> combinedMeanings = [];
          if (e['definition'] != null && e['definition'].toString().trim().isNotEmpty) {
            combinedMeanings.add("ANLAM: " + e['definition'].toString().trim());
          }
          for (var syn in synsList) {
            if (syn.toString().trim() != actualWord.trim()) combinedMeanings.add("EŞ ANLAMLI: ${syn.toString().trim()}");
          }
          for (var ant in antsList) {
            combinedMeanings.add("ZIT ANLAMLI: ${ant.toString().trim()}");
          }

          parsedList.add(json.encode({
            'word': actualWord, 'meanings': combinedMeanings, 'examples': [],
            'level': 'WordNet', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all',
            'srsLevel': 0, 'nextReviewDate': 0
          }));
        }
      }
    } 
    // 2. ÖZEL AYRIŞTIRICI: EN-TR_TAYF (2000+ Kelime)
    else if (lowerName.contains('en-tr_tayf')) {
      var lines = content.split('\n');
      for (var line in lines) {
        if (!line.contains(':')) continue;
        int colonIdx = line.indexOf(':');
        String w = line.substring(0, colonIdx).trim();
        String mStr = line.substring(colonIdx + 1).trim();
        List<String> meanings = mStr.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        parsedList.add(json.encode({
          'word': w, 'meanings': meanings, 'examples': [],
          'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all',
          'srsLevel': 0, 'nextReviewDate': 0
        }));
      }
    } 
    // 3. ÖZEL AYRIŞTIRICI: FREEDICT (Free-KH)
    else if (lowerName.contains('freedict') || lowerName.contains('free-kh')) {
      List<List<dynamic>> rows = const CsvToListConverter().convert(content);
      for (var row in rows) {
        if (row.isEmpty || row.length < 2) continue;
        String w = row[0].toString().trim();
        if (w.isEmpty || w.startsWith('#') || w.toLowerCase() == 'word') continue;
        
        List<String> meanings = row[1].toString().split('|||').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        List<String> examples = row.length > 2 ? row[2].toString().split('|||').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [];

        parsedList.add(json.encode({
          'word': w, 'meanings': meanings, 'examples': examples,
          'level': row.length > 3 ? row[3].toString().trim() : 'Genel',
          'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all',
          'srsLevel': 0, 'nextReviewDate': 0
        }));
      }
    } 
    // 4. GENEL AYRIŞTIRICI (Kullanıcı Yüklemeleri)
    else {
      var lines = content.split('\n');
      for (var line in lines) {
        if (!line.contains(':') && !line.contains(';')) continue;
        String separator = line.contains(':') ? ':' : ';';
        int sepIdx = line.indexOf(separator);
        String w = line.substring(0, sepIdx).trim();
        String mStr = line.substring(sepIdx + 1).trim();
        List<String> meanings = mStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        parsedList.add(json.encode({
          'word': w, 'meanings': meanings, 'examples': [],
          'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all',
          'srsLevel': 0, 'nextReviewDate': 0
        }));
      }
    }
  } catch (e, stacktrace) {
    parsedList.add(json.encode({'error': "$e\n$stacktrace"}));
  }
  return parsedList;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [WordModelSchema],
    directory: dir.path,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("FLUTTER ERROR: ${details.exception}\n${details.stack}");
  };
  
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
    setState(() => themeIndex = value);
    prefs.setInt('themeIndex', value);
  }

  ThemeData _getTheme() {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();
    
    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent));
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent));
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[400], scaffoldBackgroundColor: Colors.blue[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: const AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white));
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[400], scaffoldBackgroundColor: Colors.teal[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: const AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white));
      case 4: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: Colors.purple[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white));
      case 5: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: Colors.orange[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white));
      case 6: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.pink, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: Colors.pink[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.pink), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white));
      case 7: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.cyan, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: Colors.amber[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.cyan), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white));
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      themeAnimationDuration: const Duration(milliseconds: 1000),
      themeAnimationCurve: Curves.easeInOut,
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const String buildNo = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'Dev');

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  List<WordModel> allWords = [];
  List<WordModel> learningWords = []; 
  List<WordModel> learnedWords = [];
  List<WordModel> toRepeatWords = [];
  List<WordModel> wrongWords = []; 

  String selectedLibrary = 'Varsayılan';
  String selectedLevel = 'Genel';
  int dailyGoal = 10;
  int quizThreshold = 10;
  int quizQuestionCount = 10;
  int currentCardIndex = 0;
  bool isFlipped = false;

  int totalCompletedQuizzes = 0;
  int totalQuizTimeSeconds = 0;
  int totalQuizQuestions = 0;
  int totalQuizWrong = 0;

  List<String> learnedWordTimestamps = [];
  List<String> completedQuizTimestamps = [];
  List<String> viewedCardTimestamps = [];
  List<String> wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0;

  int currentStreak = 0;
  int bestStreak = 0;
  String lastActiveDateStr = "";
  int tayfPoints = 0;
  int streakFreezes = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    NotificationService.requestPermission();
    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    globalTts.stop();
    super.dispose();
  }

  void _updateNotifications() {
    int wordsLearnedToday = learnedWordTimestamps.where((ts) {
      try {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
        DateTime now = DateTime.now();
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } catch (e) { return false; }
    }).length;

    bool isStreakInDanger = false;
    if (lastActiveDateStr.isNotEmpty) {
      DateTime lastActive = DateTime.parse(lastActiveDateStr);
      DateTime now = DateTime.now();
      int diff = DateTime(now.year, now.month, now.day).difference(DateTime(lastActive.year, lastActive.month, lastActive.day)).inDays;
      if (diff >= 1 && currentStreak > 0) isStreakInDanger = true;
    } else {
      isStreakInDanger = true;
    }

    int pendingSrsCount = toRepeatWords.where((w) => w.nextReviewDate <= DateTime.now().millisecondsSinceEpoch).length;

    NotificationService.scheduleDailyNotifications(
      srsCount: pendingSrsCount,
      wordsLearnedToday: wordsLearnedToday,
      dailyGoal: dailyGoal,
      isStreakInDanger: isStreakInDanger,
    );
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

        learnedWordTimestamps = prefs.getStringList('learnedWordTimestamps') ?? [];
        completedQuizTimestamps = prefs.getStringList('completedQuizTimestamps') ?? [];
        viewedCardTimestamps = prefs.getStringList('viewedCardTimestamps') ?? [];
        wrongAnswerTimestamps = prefs.getStringList('wrongAnswerTimestamps') ?? [];
        
        currentStreak = prefs.getInt('currentStreak') ?? 0;
        bestStreak = prefs.getInt('bestStreak') ?? 0;
        lastActiveDateStr = prefs.getString('lastActiveDateStr') ?? "";
        tayfPoints = prefs.getInt('tayfPoints') ?? 0;
        streakFreezes = prefs.getInt('streakFreezes') ?? 0;
      });

      List<WordModel> fromIsar = await isar.wordModels.where().findAll();

      setState(() {
        allWords = fromIsar.where((w) => w.listType == 'all').toList();
        learningWords = fromIsar.where((w) => w.listType == 'learning').toList();
        toRepeatWords = fromIsar.where((w) => w.listType == 'toRepeat').toList();
        learnedWords = fromIsar.where((w) => w.listType == 'learned').toList();

        int now = DateTime.now().millisecondsSinceEpoch;
        bool needsSave = false;
        for (var w in learningWords.toList()) {
          if (w.nextReviewDate <= now && w.nextReviewDate > 0) {
            w.listType = 'toRepeat';
            learningWords.remove(w);
            toRepeatWords.add(w);
            needsSave = true;
          }
        }
        if (needsSave) {
          isar.writeTxn(() async { await isar.wordModels.putAll(toRepeatWords); });
        }
        wrongWords = [...allWords, ...learningWords, ...toRepeatWords, ...learnedWords].where((w) => w.wrongCount > 0).toList();
      });

      _updateNotifications();
    } catch (e, stack) {
      debugPrint("Veri Yükleme Hatası (_loadData): $e\n$stack");
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedLibrary', selectedLibrary);
      prefs.setString('selectedLevel', selectedLevel);
      prefs.setInt('currentCardIndex', currentCardIndex);
      //... (diğer prefs kayıtları korunur)

      List<WordModel> allToSave = [...allWords, ...learningWords, ...toRepeatWords, ...learnedWords];
      await isar.writeTxn(() async {
        await isar.wordModels.clear();
        await isar.wordModels.putAll(allToSave);
      });
      _updateNotifications();
    } catch (e, stack) {}
  }

  void _recordActivity(int pointsEarned) {
    setState(() => tayfPoints += pointsEarned);
    _saveData();
  }

  void _buyFreeze() {
    if (tayfPoints >= 50) {
      setState(() { tayfPoints -= 50; streakFreezes++; });
      _saveData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buz Kalkanı başarıyla satın alındı! ❄️"), backgroundColor: Colors.green));
    }
  }

  // YENİ: Filtreleme Düzeltmesi (WordNet kelimeleri için seviye takıntısı kaldırıldı)
  List<WordModel> get filteredWords {
    if (selectedLibrary == 'Tekrarlanması Gerekenler') {
      return toRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel || w.level == 'WordNet').toList();
    }
    return allWords.where((w) => 
      w.libraryName == selectedLibrary && 
      (w.level == selectedLevel || w.level == 'WordNet')
    ).toList();
  }

  List<String> get availableLibraries {
    var libs = allWords.map((e) => e.libraryName).toSet().toList();
    libs.addAll(learnedWords.map((e) => e.libraryName));
    libs.addAll(toRepeatWords.map((e) => e.libraryName));
    libs.addAll(learningWords.map((e) => e.libraryName)); 
    var uniqueLibs = libs.toSet().toList();
    uniqueLibs.add('Tekrarlanması Gerekenler'); 
    return uniqueLibs;
  }

  int get currentLibraryToRepeatCount {
    if (selectedLibrary == 'Tekrarlanması Gerekenler') return toRepeatWords.length;
    return toRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel || w.level == 'WordNet')).length;
  }

  // YENİ: TTS Ses Artıklarını (Residual) Temizleme Tamponu eklendi
  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
    try {
      await globalTts.stop();
      await Future.delayed(const Duration(milliseconds: 150)); // Kilit: Önceki sesin motoru tamamen terk etmesi için bekleme payı

      String rawText = isMeaning ? (word.meanings.isNotEmpty ? word.meanings.first : '') : word.word;
      if (rawText.isEmpty) return;

      String cleanText = rawText.replaceAll(RegExp(r'[\[\]\{\}\\|_]'), ' ')
                                .replaceAll('ANLAM:', '')
                                .replaceAll('EŞ ANLAMLI:', '')
                                .replaceAll('ZIT ANLAMLI:', '');

      String lang = isMeaning ? getSmartTargetLanguage(word.libraryName, cleanText) : getSmartSourceLanguage(word.libraryName, cleanText);
      if (word.level == 'WordNet' || word.libraryName.toLowerCase().contains('wordnet')) lang = 'en-US';

      globalTts.setLanguage(lang);
      globalTts.setSpeechRate(0.45); 
      globalTts.speak(cleanText); 
    } catch (e) {
      debugPrint("TTS Hatası: $e");
    }
  }

  void _nextCard(List<WordModel> activeList) {
    if (activeList.isEmpty) return;
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
      currentCardIndex = (currentCardIndex + 1) % activeList.length;
    });
    _saveData();
    if (activeList.isNotEmpty) _speakWord(activeList[currentCardIndex], isMeaning: false);
  }

  void _flipCard(WordModel word) {
    if (isFlipped) {
      _flipController.reverse();
      _speakWord(word, isMeaning: false); 
    } else {
      _flipController.forward();
      _speakWord(word, isMeaning: true); 
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _markAsLearned(WordModel word, List<WordModel> activeList) {
    _recordActivity(1); 
    setState(() {
      if (word.nextReviewDate == 0) word.srsLevel = 1; else word.srsLevel++;
      if (word.srsLevel > 5) {
        word.listType = 'learned';
        if (!learnedWords.any((w) => w.word == word.word)) learnedWords.add(word);
      } else {
        word.listType = 'learning';
        word.nextReviewDate = DateTime.now().millisecondsSinceEpoch + getNextReviewOffset(word.srsLevel);
        if (!learningWords.any((w) => w.word == word.word)) learningWords.add(word);
      }
      allWords.removeWhere((w) => w.word == word.word);
      toRepeatWords.removeWhere((w) => w.word == word.word);
      _nextCard(activeList);
    });
    _saveData();
  }

  void _markAsToRepeat(WordModel word, List<WordModel> activeList) {
    _recordActivity(0); 
    setState(() {
      word.srsLevel = 1; 
      word.nextReviewDate = 0; 
      word.listType = 'toRepeat';
      if (!toRepeatWords.any((w) => w.word == word.word)) toRepeatWords.add(word);
      word.wrongCount++;
      if (!wrongWords.any((w) => w.word == word.word)) wrongWords.add(word);
      allWords.removeWhere((w) => w.word == word.word);
      learningWords.removeWhere((w) => w.word == word.word); 
      _nextCard(activeList);
    });
    _saveData();
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'json', 'txt']);
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name.split('.').first;
        String extension = result.files.single.extension ?? '';

        String? customLibraryName = await _showInputDialog("Kütüphane Adı", fileName);
        if (customLibraryName == null || customLibraryName.isEmpty) return;

        showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName içe aktarılıyor.\nLütfen bekleyin..."))])));

        List<int> bytes = await file.readAsBytes();
        String content;
        try { content = utf8.decode(bytes); } catch (e) { content = latin1.decode(bytes); }

        final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': content, 'extension': extension, 'libraryName': customLibraryName});

        Navigator.pop(context); 
        if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) return;

        List<WordModel> newWords = parsedJsons.map((e) => WordModel.fromJson(e)..listType = 'all').toList();
        setState(() {
          allWords.addAll(newWords);
          selectedLibrary = customLibraryName;
          currentCardIndex = 0;
        });
        _saveData();
      }
    } catch (e) {}
  }

  Future<String?> _showInputDialog(String title, String defaultValue) {
    TextEditingController ctrl = TextEditingController(text: defaultValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text("Kaydet")),
        ],
      ),
    );
  }

  void _openEditScreen(WordModel word) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditWordScreen(
      word: word, availableLibraries: availableLibraries,
      onAction: (action, updatedWord) {
        setState(() {
          if (action == EditAction.delete) {
            allWords.removeWhere((w) => w.word == word.word);
            toRepeatWords.removeWhere((w) => w.word == word.word);
            learningWords.removeWhere((w) => w.word == word.word);
          } else if (action == EditAction.update || action == EditAction.move) {
            allWords.removeWhere((w) => w.word == word.word);
            toRepeatWords.removeWhere((w) => w.word == word.word);
            learningWords.removeWhere((w) => w.word == word.word);
            if (selectedLibrary == 'Tekrarlanması Gerekenler') toRepeatWords.add(updatedWord); else allWords.add(updatedWord);
          } else if (action == EditAction.copy) {
            allWords.add(updatedWord);
          }
        });
        _saveData();
      },
    )));
  }

  // YENİ: Seviyeye göre renk döndüren fonksiyon
  Color _getSrsBorderColor(int level) {
    switch (level) {
      case 1: return Colors.blueGrey;
      case 2: return Colors.green.shade600;
      case 3: return Colors.amber.shade700;
      case 4: return Colors.deepOrange;
      case 5: return Colors.redAccent.shade700;
      default: return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<WordModel> pendingSrsWords = toRepeatWords.where((w) => w.nextReviewDate <= DateTime.now().millisecondsSinceEpoch && w.nextReviewDate > 0).toList();
    bool isSrsMode = pendingSrsWords.isNotEmpty;
    var activeList = isSrsMode ? pendingSrsWords : filteredWords;
    WordModel? currentWord;
    if (activeList.isNotEmpty) {
      if (currentCardIndex >= activeList.length) currentCardIndex = 0;
      currentWord = activeList[currentCardIndex];
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(isSrsMode ? "Aralıklı Tekrar Modu" : "$selectedLibrary - $selectedLevel ($currentLibraryToRepeatCount/${filteredWords.length})", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.local_fire_department, color: Colors.orange, size: 20), const SizedBox(width: 4), Text("$currentStreak", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.diamond, color: Colors.blue, size: 18), const SizedBox(width: 4), Text("$tayfPoints", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))])),
        ],
      ),
      drawer: _buildDrawer(),
      body: currentWord == null 
        ? Center(child: Text(isSrsMode ? "Tekrar edilecek kelime kalmadı!" : "Bu filtreye uygun kelime kalmadı."))
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
                            Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent, width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent), const SizedBox(width: 8), Text("Tekrar Zamanı! (Kalan: ${pendingSrsWords.length})", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))]))
                          else
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Column(children: [Text("Öğrenilen: ${learnedWords.length} / Hedef: $dailyGoal", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), LinearProgressIndicator(value: dailyGoal > 0 ? (learnedWords.length / dailyGoal) : 0)])),
                            
                          const Spacer(),
                          
                          Dismissible(
                            key: ValueKey('${currentWord!.word}_$currentCardIndex'), 
                            direction: isFlipped ? DismissDirection.horizontal : DismissDirection.none,
                            background: Row(mainAxisAlignment: MainAxisAlignment.start, children: [const SizedBox(width: 30), Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle, color: Colors.green, size: 50), Text("BİLİYORUM", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))])]),
                            secondaryBackground: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.repeat, color: Colors.redAccent, size: 50), Text("TEKRAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(width: 30)]),
                            onDismissed: (direction) { if (direction == DismissDirection.startToEnd) _markAsLearned(currentWord!, activeList); else if (direction == DismissDirection.endToStart) _markAsToRepeat(currentWord!, activeList); },
                            child: GestureDetector(
                              onTap: () => _flipCard(currentWord!), 
                              child: AnimatedBuilder(
                                animation: _flipAnimation,
                                builder: (context, child) {
                                  final angle = _flipAnimation.value * pi;
                                  bool isFront = angle < (pi / 2);
                                  return Transform(
                                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle),
                                    alignment: Alignment.center,
                                    // YENİ: Kartla beraber dönen sanatsal Çerçeveli kart tasarımı
                                    child: isFront ? _buildCardFront(currentWord!) : Transform(transform: Matrix4.identity()..rotateX(pi), alignment: Alignment.center, child: _buildCardBack(currentWord!)), 
                                  );
                                }
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          if (isFlipped)
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), icon: const Icon(Icons.repeat), label: const Text("Tekrar"), onPressed: () => _markAsToRepeat(currentWord!, activeList)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), icon: const Icon(Icons.check), label: const Text("Biliyorum"), onPressed: () => _markAsLearned(currentWord!, activeList))]),
                          const Spacer(),
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

  // YENİ: Seviyeye Göre Sanatsal ve Kalın Çerçeve Eklenen Ön Yüz
  Widget _buildCardFront(WordModel word) {
    String displayWord = word.word == "WordNet Terimi" ? "Kayıt (WordNet)" : word.word;
    Color bColor = _getSrsBorderColor(word.srsLevel);
    double bWidth = word.srsLevel > 0 ? 5.0 : 2.0;

    return Container(
      width: 300, height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: bColor, width: bWidth), 
        boxShadow: [BoxShadow(color: bColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 3)]
      ),
      child: Column(
        children: [
          if (word.srsLevel > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: bColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
              child: Text("⭐ SRS Seviye: ${word.srsLevel} / 5", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          Expanded(
            child: Stack(
              children: [
                Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(displayWord, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))))),
                Positioned(right: 5, top: 5, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: false))),
                Positioned(left: 5, top: 5, child: IconButton(icon: const Icon(Icons.settings, size: 28, color: Colors.grey), tooltip: 'Kelimeyi Düzenle', onPressed: () => _openEditScreen(word)))
              ],
            ),
          ),
        ],
      ),
    );
  }

  // YENİ: Seviyeye Göre Sanatsal ve Kalın Çerçeve Eklenen Arka Yüz
  Widget _buildCardBack(WordModel word) {
    String displayWord = word.word == "WordNet Terimi" ? "Kayıt (WordNet)" : word.word;
    Color bColor = _getSrsBorderColor(word.srsLevel);
    double bWidth = word.srsLevel > 0 ? 5.0 : 2.0;

    return Container(
      width: 300, height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.green, width: bWidth), 
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 15, spreadRadius: 3)]
      ),
      child: Column(
        children: [
          if (word.srsLevel > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.green, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
              child: Text("⭐ SRS Seviye: ${word.srsLevel} / 5", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text(displayWord, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                        const Divider(),
                        const Text("Detaylar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ...word.meanings.map((m) {
                          Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;
                          if (m.startsWith("ANLAM:")) textColor = Colors.blueAccent;
                          if (m.startsWith("EŞ ANLAMLI:")) textColor = Colors.green;
                          if (m.startsWith("ZIT ANLAMLI:")) textColor = Colors.redAccent;
                          return Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: Text("• $m", style: TextStyle(color: textColor)));
                        }),
                      ],
                    ),
                  ),
                ),
                Positioned(right: 5, top: 0, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: true))),
                Positioned(left: 5, top: 0, child: IconButton(icon: const Icon(Icons.settings, size: 28, color: Colors.grey), tooltip: 'Kelimeyi Düzenle', onPressed: () => _openEditScreen(word)))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            DrawerHeader(decoration: BoxDecoration(color: Theme.of(context).primaryColor), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text("Build: v1.0.$buildNo", style: const TextStyle(color: Colors.white70)), const Text("Tayfun Yamak ©", style: TextStyle(color: Colors.white54, fontSize: 12))])),
            ListTile(leading: const Icon(Icons.language, color: Colors.indigo), title: const Text("WordNet Kütüphanesi", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordNetSearchScreen(words: allWords))); }),
            ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: filteredWords, onDelete: (w) {}, onLearned: (w) => _markAsLearned(w, filteredWords)))); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Ayarlar, Temalar, Seçimler"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, availableLibraries: availableLibraries, onSaveSettings: (nG, nT, nQC, nTI, nL, nLv) { setState(() { dailyGoal = nG; quizThreshold = nT; quizQuestionCount = nQC; widget.onThemeChanged(nTI); selectedLibrary = nL; selectedLevel = nLv; currentCardIndex = 0; }); _saveData(); }, onAddPackage: (p, e, n) => _loadPackageFromAssets(p, e, n)))); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.schedule, color: Colors.blue), title: const Text("SRS Havuzu"), onTap: () { Navigator.pop(context); List<WordModel> srsPool = [...learningWords, ...toRepeatWords.where((w) => w.srsLevel > 0)]; Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "SRS Havuzu", words: srsPool, showSrsLevel: true, onDelete: (w) {}, onClearAll: () {}))); }),
            ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: filteredWords, onGameFinished: (p) => _recordActivity(p)))); }),
            ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(words: filteredWords, threshold: quizThreshold, questionCount: quizQuestionCount, onWordMastered: (w) => _markAsLearned(w, filteredWords), onWrongWord: (w) => _markAsToRepeat(w, filteredWords), onQuizFinished: (t, a, w) { _recordActivity(a); setState(() { totalCompletedQuizzes++; totalQuizTimeSeconds += t; totalQuizQuestions += a; totalQuizWrong += w; completedQuizTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); }); _saveData(); }))); }),
            ListTile(leading: const Icon(Icons.analytics), title: const Text("İstatistikler & Rozetler"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(allWords: allWords, learningWords: learningWords, toRepeatWords: toRepeatWords, learnedWords: learnedWords, wrongWords: wrongWords, availableLibraries: availableLibraries, totalCompletedQuizzes: totalCompletedQuizzes, totalQuizTimeSeconds: totalQuizTimeSeconds, totalQuizQuestions: totalQuizQuestions, totalQuizWrong: totalQuizWrong, learnedWordTimestamps: learnedWordTimestamps, completedQuizTimestamps: completedQuizTimestamps, viewedCardTimestamps: viewedCardTimestamps, wrongAnswerTimestamps: wrongAnswerTimestamps, firstUseTimestamp: firstUseTimestamp, bestStreak: bestStreak, tayfPoints: tayfPoints))); }), 
            const Divider(),
            ListTile(leading: const Icon(Icons.science, color: Colors.purple), title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const DemoScreen())).then((_) => _loadData()); }),
            ListTile(leading: const Icon(Icons.bug_report, color: Colors.orange), title: const Text("Hata Kayıtları (Log)"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LoggerScreen())); }),
            ListTile(leading: const Icon(Icons.info_outline, color: Colors.indigo), title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen())); }),
            ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
          ],
        ),
      ),
    );
  }
}
