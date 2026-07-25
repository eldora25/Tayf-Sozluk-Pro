import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'quiz_screen.dart';
import 'add_word_screen.dart';
import 'word_list_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'edit_word_screen.dart';
import 'library_manager_screen.dart';
import 'manage_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent));
      case 1: return ThemeData.light().copyWith(primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent));
      case 2: return ThemeData(primarySwatch: Colors.blue, primaryColor: Colors.blue[400], scaffoldBackgroundColor: Colors.blue[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: const AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white));
      case 3: return ThemeData(primarySwatch: Colors.teal, primaryColor: Colors.teal[400], scaffoldBackgroundColor: Colors.teal[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: const AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white));
      case 4: return ThemeData(primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: Colors.purple[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white));
      case 5: return ThemeData(primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: Colors.orange[50], cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white));
      default: return ThemeData.dark();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      home: HomeScreen(
        themeIndex: themeIndex,
        onThemeChanged: _toggleTheme,
      ),
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

  final FlutterTts flutterTts = FlutterTts();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  List<WordModel> allWords = [];
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

  // Global İstatistikler
  int totalCompletedQuizzes = 0;
  int totalQuizTimeSeconds = 0;
  int totalQuizQuestions = 0;
  int totalQuizWrong = 0;

  // Öğrenme Hızı Zaman Damgaları (Timestamps)
  List<String> learnedWordTimestamps = [];
  List<String> completedQuizTimestamps = [];
  List<String> viewedCardTimestamps = [];
  List<String> wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadData() async {
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
      
      firstUseTimestamp = prefs.getInt('firstUseTimestamp') ?? 0;
      if (firstUseTimestamp == 0) {
        firstUseTimestamp = DateTime.now().millisecondsSinceEpoch;
        prefs.setInt('firstUseTimestamp', firstUseTimestamp);
      }

      allWords = _parseWordList(prefs.getStringList('allWords'));
      learnedWords = _parseWordList(prefs.getStringList('learnedWords'));
      toRepeatWords = _parseWordList(prefs.getStringList('toRepeatWords'));
      wrongWords = _parseWordList(prefs.getStringList('wrongWords'));

      if (allWords.isEmpty && learnedWords.isEmpty) {
        _createDefaultLibrary();
      }
    });
  }

  List<WordModel> _parseWordList(List<String>? list) {
    if (list == null) return [];
    return list.map((e) => WordModel.fromJson(e)).toList();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedLibrary', selectedLibrary);
    prefs.setString('selectedLevel', selectedLevel);
    prefs.setInt('dailyGoal', dailyGoal);
    prefs.setInt('quizThreshold', quizThreshold);
    prefs.setInt('quizQuestionCount', quizQuestionCount);
    prefs.setInt('currentCardIndex', currentCardIndex);

    prefs.setInt('totalCompletedQuizzes', totalCompletedQuizzes);
    prefs.setInt('totalQuizTimeSeconds', totalQuizTimeSeconds);
    prefs.setInt('totalQuizQuestions', totalQuizQuestions);
    prefs.setInt('totalQuizWrong', totalQuizWrong);

    prefs.setStringList('learnedWordTimestamps', learnedWordTimestamps);
    prefs.setStringList('completedQuizTimestamps', completedQuizTimestamps);
    prefs.setStringList('viewedCardTimestamps', viewedCardTimestamps);
    prefs.setStringList('wrongAnswerTimestamps', wrongAnswerTimestamps);

    prefs.setStringList('allWords', allWords.map((e) => e.toJson()).toList());
    prefs.setStringList('learnedWords', learnedWords.map((e) => e.toJson()).toList());
    prefs.setStringList('toRepeatWords', toRepeatWords.map((e) => e.toJson()).toList());
    prefs.setStringList('wrongWords', wrongWords.map((e) => e.toJson()).toList());
  }

  void _createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan (İng-Tr)'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.', 'Book a flight.'], libraryName: 'Varsayılan (İng-Tr)'),
    ];
    _saveData();
  }

  List<WordModel> get filteredWords {
    if (selectedLibrary == 'Tekrarlanması Gerekenler') {
      return toRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel).toList();
    }
    return allWords.where((w) => w.libraryName == selectedLibrary && w.level == selectedLevel).toList();
  }

  List<String> get availableLibraries {
    var libs = allWords.map((e) => e.libraryName).toSet().toList();
    libs.addAll(learnedWords.map((e) => e.libraryName));
    libs.addAll(toRepeatWords.map((e) => e.libraryName));
    var uniqueLibs = libs.toSet().toList();
    uniqueLibs.add('Tekrarlanması Gerekenler'); 
    return uniqueLibs;
  }

  int get currentLibraryToRepeatCount {
    if (selectedLibrary == 'Tekrarlanması Gerekenler') return toRepeatWords.length;
    return toRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)).length;
  }

  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
    String text = isMeaning ? word.meanings.first : word.word;
    String lang = getLanguageForWord(text, word.libraryName, isMeaning: isMeaning);
    await flutterTts.setLanguage(lang);
    await flutterTts.speak(text);
  }

  void _nextCard() {
    var list = filteredWords;
    if (list.isEmpty) return;
    setState(() {
      isFlipped = false;
      _flipController.reset();
      currentCardIndex = (currentCardIndex + 1) % list.length;
    });
    _saveData();
  }

  void _flipCard(WordModel word) {
    if (isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
      _speakWord(word, isMeaning: true); 
      // Bakılan Kart Logu
      viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _markAsLearned(WordModel word) {
    setState(() {
      if (!learnedWords.any((w) => w.word == word.word)) {
        learnedWords.add(word);
        // Öğrenilen Kelime Logu
        learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
      }
      allWords.removeWhere((w) => w.word == word.word);
      toRepeatWords.removeWhere((w) => w.word == word.word);
      _nextCard();
    });
    _saveData();
  }

  void _markAsToRepeat(WordModel word) {
    setState(() {
      if (!toRepeatWords.any((w) => w.word == word.word)) {
        toRepeatWords.add(word);
      }
      var existingWrong = wrongWords.where((w) => w.word == word.word).toList();
      if (existingWrong.isNotEmpty) {
        existingWrong.first.wrongCount++;
      } else {
        word.wrongCount = 1;
        wrongWords.add(word);
      }
      // Yanlış / Tekrar Logu
      wrongAnswerTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
      _nextCard();
    });
    _saveData();
  }

  List<String> _cleanMeanings(List<dynamic> raw) {
    List<String> result = [];
    for (var item in raw) {
      var str = item.toString().replaceAll('\x06', '');
      var parts = str.split(RegExp(r';|\|\|\||,|\n'));
      for (var p in parts) {
        var clean = p.trim();
        clean = clean.replaceAll(RegExp(r'^(n\.|v\.|adj\.|adv\.|prep\.|conj\.|pron\.)\s*'), '');
        clean = clean.replaceAll(RegExp(r'\s+'), ' ');
        if (clean.isNotEmpty && clean.length < 60) {
          result.add(clean);
        } else if (clean.length >= 60 && clean.length < 150) {
          result.add(clean); 
        }
      }
    }
    return result.toSet().toList();
  }

  Future<void> _parseDataAndAdd(String content, String extension, String customLibraryName) async {
    List<WordModel> newWords = [];
    try {
      if (extension == 'json') {
        var decoded = json.decode(content);
        List list = decoded is Map ? decoded['words'] : decoded;
        newWords = list.map((e) => WordModel(
          word: e['word'] ?? '', meanings: _cleanMeanings(e['meanings'] ?? []), examples: _cleanMeanings(e['examples'] ?? []),
          level: e['level'] ?? 'Genel', libraryName: customLibraryName,
        )).toList();
      } else if (extension == 'txt') {
        var lines = content.split('\n');
        for (var line in lines) {
          if (!line.contains(':')) continue;
          var parts = line.split(':');
          newWords.add(WordModel(word: parts[0].trim(), meanings: _cleanMeanings([parts[1].trim()]), examples: [], level: 'Genel', libraryName: customLibraryName));
        }
      } else {
        List<List<dynamic>> rows = const CsvToListConverter().convert(content);
        for (var row in rows) {
          if (row.isEmpty || row.length < 2) continue;
          String wordStr = row[0].toString().trim();
          if (wordStr.isEmpty || wordStr.startsWith('#') || wordStr.toLowerCase() == 'word' || wordStr.startsWith('00database')) continue;

          newWords.add(WordModel(
            word: wordStr, meanings: _cleanMeanings([row[1]]), examples: row.length > 2 ? _cleanMeanings([row[2]]) : [],
            level: row.length > 3 && row[3].toString().trim().isNotEmpty ? row[3].toString().trim() : 'Genel', libraryName: customLibraryName,
          ));
        }
      }

      setState(() {
        allWords.addAll(newWords);
        selectedLibrary = customLibraryName;
        currentCardIndex = 0;
      });
      _saveData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dosya formatı hatalı: $e")));
    }
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'json', 'txt']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String content = await file.readAsString(encoding: utf8);
      String extension = result.files.single.extension ?? '';

      String? customLibraryName = await _showInputDialog("Kütüphane Adı", fileName);
      if (customLibraryName == null || customLibraryName.isEmpty) return;

      await _parseDataAndAdd(content, extension, customLibraryName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İçe aktarım başarılı!")));
    }
  }

  Future<void> _loadPackageFromAssets(String assetPath, String extension, String customLibraryName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$customLibraryName yükleniyor, lütfen bekleyin...")));
      String content = await rootBundle.loadString(assetPath);
      await _parseDataAndAdd(content, extension, customLibraryName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$customLibraryName başarıyla eklendi!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paket yüklenirken hata oluştu: $e")));
    }
  }

  void _renameLibrary(String oldName, String newName) {
    setState(() {
      for (var w in allWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in learnedWords) { if (w.libraryName == oldName) w.libraryName = newName; }
      for (var w in toRepeatWords) { if (w.libraryName == oldName) w.libraryName = newName; }
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
      wrongWords.removeWhere((w) => w.libraryName == libName);
      if (selectedLibrary == libName) selectedLibrary = 'Varsayılan';
    });
    _saveData();
  }

  Future<void> _exportLibrary(String libName) async {
    if (libName == 'Tekrarlanması Gerekenler') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sanal kütüphane dışa aktarılamaz!")));
      return;
    }
    List<WordModel> exportList = allWords.where((w) => w.libraryName == libName).toList()
                               ..addAll(learnedWords.where((w) => w.libraryName == libName).toList());
    
    if (exportList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktarılacak kelime bulunamadı.")));
      return;
    }

    List<List<dynamic>> rows = [];
    for (var w in exportList) {
      rows.add([w.word, w.meanings.join('|||'), w.examples.join('|||'), w.level]);
    }
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$libName.csv');
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: '$libName Kütüphanesi Yedeği');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
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
      word: word,
      availableLibraries: availableLibraries,
      onAction: (action, updatedWord) {
        setState(() {
          if (action == EditAction.delete) {
            allWords.removeWhere((w) => w.word == word.word);
            toRepeatWords.removeWhere((w) => w.word == word.word);
          } else if (action == EditAction.update || action == EditAction.move) {
            allWords.removeWhere((w) => w.word == word.word);
            toRepeatWords.removeWhere((w) => w.word == word.word);
            if (selectedLibrary == 'Tekrarlanması Gerekenler') {
              toRepeatWords.add(updatedWord);
            } else {
              allWords.add(updatedWord);
            }
          } else if (action == EditAction.copy) {
            allWords.add(updatedWord);
          }
          if (currentCardIndex >= filteredWords.length) currentCardIndex = 0;
        });
        _saveData();
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    var activeList = filteredWords;
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
            Text("$selectedLibrary - $selectedLevel ($currentLibraryToRepeatCount/${activeList.length})", 
              style: const TextStyle(fontSize: 12, color: Colors.white70)
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: currentWord == null 
        ? const Center(child: Text("Bu filtreye uygun kelime kalmadı."))
        : Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text("Öğrenilen: ${learnedWords.length} / Hedef: $dailyGoal", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: dailyGoal > 0 ? (learnedWords.length / dailyGoal) : 0),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _flipCard(currentWord!),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    bool isFront = angle < (pi / 2);
                    return Transform(
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle),
                      alignment: Alignment.center,
                      child: isFront 
                          ? _buildCardFront(currentWord!)
                          : Transform(
                              transform: Matrix4.identity()..rotateX(pi),
                              alignment: Alignment.center,
                              child: _buildCardBack(currentWord!),
                            ),
                    );
                  }
                ),
              ),
              const Spacer(),
              if (isFlipped)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      icon: const Icon(Icons.repeat),
                      label: const Text("Tekrar"),
                      onPressed: () => _markAsToRepeat(currentWord!),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      icon: const Icon(Icons.check),
                      label: const Text("Biliyorum"),
                      onPressed: () => _markAsLearned(currentWord!),
                    ),
                  ],
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("V.1.0.$buildNo", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("By: Tayfun YAMAK©", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCardFront(WordModel word) {
    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Center(child: Text(word.word, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
          Positioned(
            right: 0, top: 0,
            child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: false)),
          ),
          Positioned(
            left: 0, top: 0,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 28, color: Colors.grey),
              tooltip: 'Kelimeyi Düzenle',
              onPressed: () => _openEditScreen(word),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardBack(WordModel word) {
    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  const Divider(),
                  const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ...word.meanings.map((m) => Text("• $m")),
                  const SizedBox(height: 10),
                  if (word.examples.isNotEmpty) const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...word.examples.map((e) => Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0, top: 0,
            child: IconButton(icon: const Icon(Icons.volume_up, size: 30), onPressed: () => _speakWord(word, isMeaning: true)),
          ),
          Positioned(
            left: 0, top: 0,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 28, color: Colors.grey),
              tooltip: 'Kelimeyi Düzenle',
              onPressed: () => _openEditScreen(word),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      // KESİN ÇÖZÜM: SafeArea eklendi, Drawer listesi sanal butonların altında kalmayacak.
      child: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Build: v1.0.$buildNo", style: const TextStyle(color: Colors.white70)),
                  const Text("Tayfun Yamak ©", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text("Kelime Ekle"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(
                  availableLibraries: availableLibraries,
                  onSave: (newWord) { setState(() => allWords.add(newWord)); _saveData(); }
                )));
              }
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("Kelime Listesi"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(
                  words: filteredWords,
                  onDelete: (wordToDelete) {
                    setState(() {
                      allWords.removeWhere((w) => w.word == wordToDelete.word);
                      toRepeatWords.removeWhere((w) => w.word == wordToDelete.word);
                    });
                    _saveData();
                  }
                )));
              }
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Ayarlar, Temalar, Seçimler"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                  currentGoal: dailyGoal,
                  currentThreshold: quizThreshold,
                  currentQuestionCount: quizQuestionCount,
                  currentThemeIndex: widget.themeIndex,
                  selectedLibrary: selectedLibrary,
                  selectedLevel: selectedLevel,
                  availableLibraries: availableLibraries,
                  onSaveSettings: (newGoal, newThreshold, newQCount, newThemeIdx, newLib, newLevel) {
                    setState(() {
                      dailyGoal = newGoal;
                      quizThreshold = newThreshold;
                      quizQuestionCount = newQCount;
                      widget.onThemeChanged(newThemeIdx);
                      selectedLibrary = newLib;
                      selectedLevel = newLevel;
                      currentCardIndex = 0;
                    });
                    _saveData();
                  },
                  onAddPackage: (assetPath, ext, name) => _loadPackageFromAssets(assetPath, ext, name),
                )));
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text("Öğrenilen Kelimeler"),
              subtitle: Text("${learnedWords.length} kelime", style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(
                  title: "Öğrenilen Kelimeler", words: learnedWords,
                  onDelete: (w) { setState(() => learnedWords.remove(w)); _saveData(); },
                  onClearAll: () { setState(() => learnedWords.clear()); _saveData(); }
                )));
              }
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.orange),
              title: const Text("Tekrar Listesi"),
              subtitle: Text("${toRepeatWords.length} kelime", style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(
                  title: "Tekrar Listesi", words: toRepeatWords,
                  onDelete: (w) { setState(() => toRepeatWords.remove(w)); _saveData(); },
                  onClearAll: () { setState(() => toRepeatWords.clear()); _saveData(); }
                )));
              }
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("Yanlış Kelimeler"),
              subtitle: Text("${wrongWords.length} kelime", style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(
                  title: "Yanlış Kelimeler", words: wrongWords, showWrongCount: true,
                  onDelete: (w) { setState(() => wrongWords.remove(w)); _saveData(); },
                  onClearAll: () { setState(() => wrongWords.clear()); _saveData(); }
                )));
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.my_library_books),
              title: const Text("Kütüphane Yönetimi"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(
                  allWords: allWords, learnedWords: learnedWords, wrongWords: wrongWords,
                  onRename: _renameLibrary, onDelete: _deleteLibrary, onExport: _exportLibrary,
                )));
              }
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text("Quiz"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                  words: filteredWords,
                  threshold: quizThreshold,
                  questionCount: quizQuestionCount,
                  onWordLearned: (w) {
                    setState(() {
                      if (!learnedWords.any((existing) => existing.word == w.word)) {
                        learnedWords.add(w);
                        learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
                      }
                      allWords.removeWhere((existing) => existing.word == w.word);
                      toRepeatWords.removeWhere((existing) => existing.word == w.word);
                    });
                    _saveData();
                  },
                  onWordWrong: (w) {
                    setState(() {
                      if (!toRepeatWords.any((existing) => existing.word == w.word)) toRepeatWords.add(w);
                      var existingWrong = wrongWords.where((existing) => existing.word == w.word).toList();
                      if (existingWrong.isNotEmpty) {
                        existingWrong.first.wrongCount++;
                      } else {
                        w.wrongCount = 1;
                        wrongWords.add(w);
                      }
                      wrongAnswerTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
                    });
                    _saveData();
                  },
                  onQuizFinished: (timeElapsed, answered, wrong) {
                    setState(() {
                      totalCompletedQuizzes++;
                      totalQuizTimeSeconds += timeElapsed;
                      totalQuizQuestions += answered;
                      totalQuizWrong += wrong;
                      completedQuizTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
                    });
                    _saveData();
                  },
                )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text("İstatistikler"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(
                  allWords: allWords,
                  learnedWords: learnedWords,
                  wrongWords: wrongWords,
                  availableLibraries: availableLibraries,
                  totalCompletedQuizzes: totalCompletedQuizzes,
                  totalQuizTimeSeconds: totalQuizTimeSeconds,
                  totalQuizQuestions: totalQuizQuestions,
                  totalQuizWrong: totalQuizWrong,
                  learnedWordTimestamps: learnedWordTimestamps,
                  completedQuizTimestamps: completedQuizTimestamps,
                  viewedCardTimestamps: viewedCardTimestamps,
                  wrongAnswerTimestamps: wrongAnswerTimestamps,
                  firstUseTimestamp: firstUseTimestamp,
                )));
              },
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
            ListTile(leading: const Icon(Icons.share), title: const Text("Dışa Aktar / Paylaş"), onTap: () { Navigator.pop(context); _exportLibrary(selectedLibrary); }),
          ],
        ),
      ),
    );
  }
}
