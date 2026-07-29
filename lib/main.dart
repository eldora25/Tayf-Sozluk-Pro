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
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur')) return 'en-US';
  if (name.contains('ing') || name.contains('eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(wordText)) return 'tr-TR';
  return 'en-US'; 
}

String getSmartTargetLanguage(String libraryName, String meaningText) {
  String name = libraryName.toLowerCase();
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng')) return 'en-US';
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur')) return 'tr-TR';
  if (name.contains('wordnet') || name.contains('eng-eng')) return 'en-US'; 
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

List<String> parseLibraryDataInBackground(Map<String, dynamic> params) {
  String content = params['content'];
  String extension = params['extension'];
  String customLibraryName = params['libraryName'];
  List<String> parsedList = [];
  String lowerName = customLibraryName.toLowerCase();

  List<String> cleanMeanings(List<dynamic> raw) {
    List<String> result = [];
    for (var item in raw) {
      var str = item.toString().replaceAll('\x06', '');
      var parts = str.split(RegExp(r'\|\|\||\n'));
      for (var p in parts) {
        var clean = p.trim().replaceAll(RegExp(r'^(n\.|v\.|adj\.|adv\.|prep\.|conj\.|pron\.)\s*'), '').replaceAll(RegExp(r'\s+'), ' ');
        if (clean.isNotEmpty) result.add(clean);
      }
    }
    return result.toSet().toList();
  }

  try {
    if (lowerName.contains('wordnet')) {
      parsedList.add(json.encode({'error': "Yazılımcı üzerinde halen çalışıyor"}));
      return parsedList;
    } else if (extension == 'json') {
      var decoded = json.decode(content);
      List list = decoded is Map ? (decoded['words'] ?? decoded) : decoded;
      for (var e in list) {
        if (e is Map) {
          String w = e['word']?.toString() ?? '';
          if (w.isEmpty) continue;
          List<String> meanings = e['meanings'] is List ? (e['meanings'] as List).map((m) => m.toString()).toList() : (e['definition'] != null ? [e['definition'].toString()] : []);
          List<String> examples = e['examples'] is List ? (e['examples'] as List).map((ex) => ex.toString()).toList() : [];
          parsedList.add(json.encode({'word': w, 'meanings': meanings, 'examples': examples, 'level': e['level']?.toString() ?? 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
        }
      }
    } else if (lowerName.contains('babylon')) {
      List<String> lines = content.split('\n');
      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#') || line.toLowerCase().startsWith('word,')) continue;
        if ((line.contains('|') || line.contains('\t')) && !line.contains(',')) {
          var parts = line.split(line.contains('|') ? '|' : '\t');
          if (parts.length >= 2) parsedList.add(json.encode({'word': parts[0].trim(), 'meanings': cleanMeanings([parts[1].trim()]), 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
          continue;
        }
        try {
            List<List<dynamic>> parsedLine = const CsvToListConverter().convert(line + '\n');
            if (parsedLine.isEmpty || parsedLine[0].length < 2) continue;
            var row = parsedLine[0];
            String w = row[0].toString().trim(), mStr = row[1].toString().trim();
            if (w.isEmpty) continue;
            List<String> mList = mStr.contains('|||') ? mStr.split('|||').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList() : (mStr.contains(';') ? mStr.split(';').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList() : [mStr]);
            parsedList.add(json.encode({'word': w, 'meanings': cleanMeanings(mList), 'examples': row.length > 2 ? row[2].toString().split('|||').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList() : [], 'level': row.length > 3 && row[3].toString().trim().isNotEmpty ? row[3].toString().trim() : 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
        } catch(e) { continue; }
      }
    } else {
      var lines = content.split('\n');
      for (var line in lines) {
        if (!line.contains(':') && !line.contains(';') && !line.contains(',')) continue;
        String separator = line.contains(':') ? ':' : (line.contains(';') ? ';' : ',');
        int sepIdx = line.indexOf(separator);
        if (sepIdx != -1) {
          parsedList.add(json.encode({'word': line.substring(0, sepIdx).trim(), 'meanings': line.substring(sepIdx + 1).trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(), 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0}));
        }
      }
    }
  } catch (e, stacktrace) { parsedList.add(json.encode({'error': "Dosya Okuma Hatası: $e"})); }
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
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent));
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent));
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[400], scaffoldBackgroundColor: Colors.blue[50], cardColor: Colors.white);
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[400], scaffoldBackgroundColor: Colors.teal[50], cardColor: Colors.white);
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme));
    }
  }
  @override
  Widget build(BuildContext context) { return MaterialApp(title: 'Tayf Sözlük Pro', debugShowCheckedModeBanner: false, theme: _getTheme(), home: HomeScreen(themeIndex: themeIndex, onThemeChanged: _toggleTheme)); }
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
  List<WordModel> toSRSRepeatWords = []; // YENİ: Sadece SRS'den düşenler
  List<WordModel> wrongWords = []; 

  String selectedLibrary = 'Varsayılan';
  String selectedLevel = 'Genel';
  int dailyGoal = 10, quizThreshold = 10, quizQuestionCount = 10, currentCardIndex = 0;
  bool isFlipped = false;
  int totalCompletedQuizzes = 0, totalQuizTimeSeconds = 0, totalQuizQuestions = 0, totalQuizWrong = 0;
  List<String> learnedWordTimestamps = [], completedQuizTimestamps = [], viewedCardTimestamps = [], wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0, currentStreak = 0, bestStreak = 0, tayfPoints = 0, streakFreezes = 0;
  String lastActiveDateStr = "";

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
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
        tayfPoints = prefs.getInt('tayfPoints') ?? 0;
      });

      List<WordModel> fromIsar = await isar.wordModels.where().findAll();

      setState(() {
        allWords = fromIsar.where((w) => w.listType == 'all').toList();
        learningWords = fromIsar.where((w) => w.listType == 'learning').toList();
        learnedWords = fromIsar.where((w) => w.listType == 'learned').toList();
        
        // MİGRASYON VE YENİ LİSTE AYRIMI
        List<WordModel> tempToRepeat = fromIsar.where((w) => w.listType == 'toRepeat').toList();
        toRepeatWords = tempToRepeat.where((w) => w.srsLevel == 0).toList();
        toSRSRepeatWords = fromIsar.where((w) => w.listType == 'toSRSRepeat').toList()
          ..addAll(tempToRepeat.where((w) => w.srsLevel > 0)); // Eskiden kalan SRS ceza kelimelerini aktar

        int now = DateTime.now().millisecondsSinceEpoch;
        bool needsSave = false;
        
        // ZAMANI DOLANLARI (learning) GÖRÜNMEZ DURUMDAN toSRSRepeat'e AL
        for (var w in learningWords.toList()) {
          if (w.nextReviewDate <= now && w.nextReviewDate > 0) {
            w.listType = 'toSRSRepeat';
            learningWords.remove(w);
            toSRSRepeatWords.add(w);
            needsSave = true;
          }
        }

        if (needsSave) {
          isar.writeTxn(() async { await isar.wordModels.putAll(toSRSRepeatWords); });
        }

        wrongWords = [...allWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords, ...learnedWords].where((w) => w.wrongCount > 0).toList();
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

  // YENİ: ANA EKRAN KART HİYERARŞİSİ (Zamanı Gelen SRS -> Normal toRepeat -> Yeni All)
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

  int get currentLibraryToRepeatCount {
    if (selectedLibrary == 'Tekrarlanması Gerekenler') return toSRSRepeatWords.length + toRepeatWords.length;
    return toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary).length + toRepeatWords.where((w) => w.libraryName == selectedLibrary).length;
  }

  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
    try {
      await globalTts.stop();
      await Future.delayed(const Duration(milliseconds: 250)); 
      String rawText = isMeaning ? (word.meanings.isNotEmpty ? word.meanings.first : '') : word.word;
      if (rawText.isEmpty) return;
      String cleanText = rawText.replaceAll(RegExp(r'[\[\]\{\}\\|_]'), ' ').replaceAll('ANLAM:', '');
      globalTts.setLanguage(getSmartSourceLanguage(word.libraryName, cleanText));
      globalTts.speak(cleanText); 
    } catch (e) {}
  }

  void _nextCard() {
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
    });
    _saveData();
    if (activeDeck.isNotEmpty) _speakWord(activeDeck[0], isMeaning: false);
  }

  void _flipCard(WordModel word) {
    if (isFlipped) { _flipController.reverse(); _speakWord(word, isMeaning: false); } 
    else { _flipController.forward(); _speakWord(word, isMeaning: true); viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); }
    setState(() => isFlipped = !isFlipped);
  }

  // YENİ KART "BİLİYORUM" MANTIĞI
  void _markAsLearned(WordModel word) {
    _recordActivity(1); 
    setState(() {
      if (word.srsLevel == 0) {
        word.srsLevel = 1;
        word.listType = 'learning';
        word.nextReviewDate = DateTime.now().millisecondsSinceEpoch + getNextReviewOffset(1);
        learningWords.add(word);
        allWords.remove(word);
        toRepeatWords.remove(word);
      } else {
        word.srsLevel++;
        if (word.srsLevel > 5) {
          word.listType = 'learned';
          learnedWords.add(word);
        } else {
          word.listType = 'learning';
          word.nextReviewDate = DateTime.now().millisecondsSinceEpoch + getNextReviewOffset(word.srsLevel);
          learningWords.add(word);
        }
        toSRSRepeatWords.remove(word);
      }
      _nextCard();
    });
  }

  // YENİ KART "TEKRAR" (HATA) MANTIĞI
  void _markAsToRepeat(WordModel word) {
    _recordActivity(0); 
    setState(() {
      word.wrongCount++;
      if (!wrongWords.any((w) => w.word == word.word)) wrongWords.add(word);

      if (word.srsLevel > 0) {
        word.srsLevel = 1; 
        word.nextReviewDate = 0; 
        word.listType = 'toSRSRepeat';
        if (!toSRSRepeatWords.any((w) => w.word == word.word)) toSRSRepeatWords.add(word);
        learningWords.removeWhere((w) => w.word == word.word);
      } else {
        word.listType = 'toRepeat';
        if (!toRepeatWords.any((w) => w.word == word.word)) toRepeatWords.add(word);
        allWords.removeWhere((w) => w.word == word.word);
      }
      _nextCard();
    });
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'json', 'txt']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String? customLibraryName = await _showInputDialog("Kütüphane Adı", result.files.single.name.split('.').first);
      if (customLibraryName == null) return;
      
      showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName aktarılıyor..."))])));
      List<int> bytes = await file.readAsBytes();
      final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': utf8.decode(bytes), 'extension': result.files.single.extension ?? '', 'libraryName': customLibraryName});
      Navigator.pop(context); 

      if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(parsedJsons.first)['error']))); return;
      }
      setState(() { allWords.addAll(parsedJsons.map((e) => WordModel.fromJson(e)..listType = 'all').toList()); selectedLibrary = customLibraryName; });
      _saveData();
    }
  }

  Future<String?> _showInputDialog(String title, String defVal) {
    TextEditingController ctrl = TextEditingController(text: defVal);
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Kaydet"))]));
  }

  List<Color> _getPremiumGradientColors(int level) {
    switch (level) {
      case 1: return [Colors.blueGrey.shade300, Colors.lightBlue.shade400];
      case 2: return [Colors.teal.shade400, Colors.green.shade400];
      case 3: return [Colors.orange.shade400, Colors.amber.shade400];
      case 4: return [Colors.red.shade400, Colors.deepOrange.shade400];
      case 5: return [Colors.purple.shade500, Colors.pinkAccent.shade400];
      default: return [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary];
    }
  }

  @override
  Widget build(BuildContext context) {
    var deck = activeDeck;
    WordModel? currentWord = deck.isNotEmpty ? deck[0] : null;
    bool isSrsMode = currentWord != null && currentWord.listType == 'toSRSRepeat';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(isSrsMode ? "SRS Tekrar Modu" : "$selectedLibrary - $selectedLevel (${deck.length})", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
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
                            Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent, width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 8), Text("SRS Tekrar Zamanı!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))])),
                          const Spacer(),
                          Dismissible(
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
                          const SizedBox(height: 30),
                          if (isFlipped) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), icon: const Icon(Icons.repeat), label: const Text("Tekrar"), onPressed: () => _markAsToRepeat(currentWord)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), icon: const Icon(Icons.check), label: const Text("Biliyorum"), onPressed: () => _markAsLearned(currentWord))]),
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

  Widget _buildCardFront(WordModel word) {
    bool isPremium = word.srsLevel > 0;
    List<Color> gradientColors = _getPremiumGradientColors(word.srsLevel);
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 300, height: 320,
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), gradient: isPremium ? LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null, border: isPremium ? null : Border.all(color: Theme.of(context).primaryColor, width: 2), boxShadow: isPremium ? [BoxShadow(color: gradientColors.last.withOpacity(0.6 * _glowAnimation.value), blurRadius: 20 * _glowAnimation.value, spreadRadius: 3 * _glowAnimation.value)] : [const BoxShadow(color: Colors.black26, blurRadius: 10)]),
          child: Container(
            margin: EdgeInsets.all(isPremium ? 4.0 : 0), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                if (isPremium) Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))), child: Text("⭐ SRS Seviye: ${word.srsLevel} / 5", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                Expanded(child: Stack(children: [Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))))), Positioned(right: 5, top: 5, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: false)))])),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildCardBack(WordModel word) {
    bool isPremium = word.srsLevel > 0;
    List<Color> gradientColors = _getPremiumGradientColors(word.srsLevel);
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 300, height: 320,
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), gradient: isPremium ? LinearGradient(colors: gradientColors, begin: Alignment.bottomRight, end: Alignment.topLeft) : null, border: isPremium ? null : Border.all(color: Colors.green, width: 2), boxShadow: isPremium ? [BoxShadow(color: gradientColors.first.withOpacity(0.6 * _glowAnimation.value), blurRadius: 20 * _glowAnimation.value, spreadRadius: 3 * _glowAnimation.value)] : [const BoxShadow(color: Colors.black26, blurRadius: 10)]),
          child: Container(
            margin: EdgeInsets.all(isPremium ? 4.0 : 0), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                if (isPremium) Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))), child: Text("⭐ SRS Seviye: ${word.srsLevel} / 5", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                Expanded(child: Stack(children: [SingleChildScrollView(child: Padding(padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), const Divider(), ...word.meanings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: Text("• $m")))]))), Positioned(right: 5, top: 0, child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: true)))])),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(decoration: BoxDecoration(color: Theme.of(context).primaryColor), child: const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 24))),
            ListTile(leading: const Icon(Icons.add_box), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
            ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { 
              Navigator.pop(context); 
              // TÜM KÜTÜPHANEYİ QUİZ'E YOLLA (O KENDİ %40 - %60 AYIRACAK)
              List<WordModel> fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList();
              Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(words: fullPool, threshold: quizThreshold, questionCount: quizQuestionCount, onWordMastered: _markAsLearned, onWrongWord: _markAsToRepeat, onQuizFinished: (t, a, w) { _saveData(); }))); 
            }),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Ayarlar"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, availableLibraries: availableLibraries, onSaveSettings: (nG, nT, nQC, nTI, nL, nLv) { setState(() { quizThreshold = nT; widget.onThemeChanged(nTI); selectedLibrary = nL; }); _saveData(); }, onAddPackage: _loadPackageFromAssets))); }),
          ],
        ),
      ),
    );
  }
}
