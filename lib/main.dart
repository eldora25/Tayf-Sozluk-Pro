import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'models/word_model.dart';
import 'screens/quiz_screen.dart';
import 'screens/wrong_words_screen.dart';
import 'screens/add_word_screen.dart';
import 'screens/word_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TayfSozlukApp());
}

class TayfSozlukApp extends StatefulWidget {
  const TayfSozlukApp({Key? key}) : super(key: key);

  @override
  State<TayfSozlukApp> createState() => _TayfSozlukAppState();
}

class _TayfSozlukAppState extends State<TayfSozlukApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _isDarkMode = prefs.getBool('isDarkMode') ?? true; });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _isDarkMode = value; });
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(isDarkMode: _isDarkMode, onThemeChanged: _toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  const HomeScreen({Key? key, required this.isDarkMode, required this.onThemeChanged}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _flipAnimationController;
  
  String buildNo = "1"; 
  List<WordModel> _allWords = [];
  List<WordModel> _learnedWords = [];
  List<WordModel> _reviewWords = [];
  List<WrongWordModel> _wrongWords = [];
  List<String> _libraries = ['test'];
  String _selectedLibrary = 'test';
  String _selectedLevel = 'Genel';
  int _dailyGoal = 10;
  int _dailyProgress = 0;
  int _quizQuestionCount = 10;
  int _masteryThreshold = 3;
  int _currentCardIndex = 0;
  bool _isCardFlipped = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _flipAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadAllData();
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLibrary = prefs.getString('selectedLibrary') ?? 'test';
      _selectedLevel = prefs.getString('selectedLevel') ?? 'Genel';
      _dailyGoal = prefs.getInt('dailyGoal') ?? 10;
      _dailyProgress = prefs.getInt('dailyProgress') ?? 0;
      _quizQuestionCount = prefs.getInt('quizQuestionCount') ?? 10;
      _masteryThreshold = prefs.getInt('masteryThreshold') ?? 3;
      _currentCardIndex = prefs.getInt('currentCardIndex') ?? 0;
      
      String? wordsJson = prefs.getString('allWords');
      if (wordsJson != null) _allWords = (json.decode(wordsJson) as List).map((e) => WordModel.fromMap(e)).toList();
      String? learnedJson = prefs.getString('learnedWords');
      if (learnedJson != null) _learnedWords = (json.decode(learnedJson) as List).map((e) => WordModel.fromMap(e)).toList();
      String? reviewJson = prefs.getString('reviewWords');
      if (reviewJson != null) _reviewWords = (json.decode(reviewJson) as List).map((e) => WordModel.fromMap(e)).toList();
      String? wrongJson = prefs.getString('wrongWords');
      if (wrongJson != null) _wrongWords = (json.decode(wrongJson) as List).map((e) => WrongWordModel.fromMap(e)).toList();
      
      _updateLibraryList();
      _isLoading = false;
    });
    if (_allWords.isEmpty) _initDefaultTestPackage();
  }

  void _updateLibraryList() {
    final extracted = _allWords.map((e) => e.libraryName).toSet().toList();
    for (var lib in extracted) { if (!_libraries.contains(lib)) _libraries.add(lib); }
  }

  void _initDefaultTestPackage() {
    List<Map<String, dynamic>> defaultData = [
      {"word": "word", "meanings": ["söz, sözcük", "lafız"], "examples": ["Words fail me."], "level": "Genel", "libraryName": "test"},
      {"word": "book", "meanings": ["kitap", "ayırtmak"], "examples": ["I read a book."], "level": "Genel", "libraryName": "test"}
    ];
    setState(() { _allWords = defaultData.map((e) => WordModel.fromMap(e)).toList(); _updateLibraryList(); });
    _saveWords();
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allWords', json.encode(_allWords.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveAppState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLibrary', _selectedLibrary);
    await prefs.setString('selectedLevel', _selectedLevel);
    await prefs.putInt('dailyGoal', _dailyGoal);
    await prefs.putInt('dailyProgress', _dailyProgress);
    await prefs.putInt('quizQuestionCount', _quizQuestionCount);
    await prefs.putInt('masteryThreshold', _masteryThreshold);
    await prefs.putInt('currentCardIndex', _currentCardIndex);
    await prefs.setString('learnedWords', json.encode(_learnedWords.map((e) => e.toMap()).toList()));
    await prefs.setString('reviewWords', json.encode(_reviewWords.map((e) => e.toMap()).toList()));
    await prefs.setString('wrongWords', json.encode(_wrongWords.map((e) => e.toMap()).toList()));
  }

  Future<void> _speak(String text) async { await _flutterTts.setLanguage("en-US"); await _flutterTts.speak(text); }

  void _toggleCard() {
    var filtered = _getCurrentFilteredWords();
    if (filtered.isEmpty) return;
    if (_isCardFlipped) { _flipAnimationController.reverse(); } 
    else { _flipAnimationController.forward(); if (_currentCardIndex < filtered.length) _speak(filtered[_currentCardIndex].word); }
    setState(() { _isCardFlipped = !_isCardFlipped; });
  }

  List<WordModel> _getCurrentFilteredWords() { return _allWords.where((w) => w.libraryName == _selectedLibrary && w.level == _selectedLevel).toList(); }

  void _onBiliyorumPressed(WordModel word) {
    setState(() { _learnedWords.add(word); _allWords.removeWhere((w) => w.word == word.word); _dailyProgress++; _isCardFlipped = false; _flipAnimationController.reset(); });
    _saveWords(); _saveAppState();
  }

  void _onTekrarPressed(WordModel word) {
    setState(() {
      if (!_reviewWords.any((w) => w.word == word.word)) _reviewWords.add(word);
      var idx = _wrongWords.indexWhere((w) => w.wordInfo.word == word.word);
      if (idx == -1) { _wrongWords.add(WrongWordModel(wordInfo: word, wrongCount: 1)); } else { _wrongWords[idx].wrongCount++; }
      _isCardFlipped = false; _flipAnimationController.reset();
      var rem = _getCurrentFilteredWords();
      if (rem.length > 1) _currentCardIndex = (_currentCardIndex + 1) % rem.length;
    });
    _saveAppState();
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String content = await file.readAsString(encoding: utf8);
      var decoded = json.decode(content);
      List<dynamic> wordsList = decoded is Map && decoded.containsKey('words') ? decoded['words'] : decoded;
      for (var item in wordsList) {
        _allWords.add(WordModel(word: item['word'] ?? '', meanings: List<String>.from(item['meanings'] ?? []), examples: List<String>.from(item['examples'] ?? []), level: item['level'] ?? 'Genel', libraryName: fileName));
      }
      setState(() { if (!_libraries.contains(fileName)) _libraries.add(fileName); _selectedLibrary = fileName; _currentCardIndex = 0; });
      _saveWords(); _saveAppState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    var filteredList = _getCurrentFilteredWords();
    WordModel? currentWord = filteredList.isNotEmpty && _currentCardIndex < filteredList.length ? filteredList[_currentCardIndex] : null;

    return Scaffold(
      appBar: AppBar(title: Text("Tayf Sözlük - $_selectedLibrary / $_selectedLevel", style: const TextStyle(fontSize: 14))),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Hedef: $_dailyProgress / $_dailyGoal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            LinearProgressIndicator(value: _dailyGoal > 0 ? _dailyProgress / _dailyGoal : 0),
            const SizedBox(height: 32),
            Expanded(child: currentWord == null ? const Center(child: Text("Kelime kalmadı!")) : GestureDetector(onTap: _toggleCard, child: AnimatedBuilder(animation: _flipAnimationController, builder: (context, child) {
              final angle = _flipAnimationController.value * pi;
              return Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle), alignment: Alignment.center, child: angle < pi / 2 ? _buildCardFront(currentWord.word) : Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: _buildCardBack(currentWord)));
            }))),
            const SizedBox(height: 24),
            if (currentWord != null) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _onBiliyorumPressed(currentWord), child: const Text("Biliyorum")),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => _onTekrarPressed(currentWord), child: const Text("Tekrar")),
            ]),
            const SizedBox(height: 16),
            Text("By: Tayfun Yamak ©", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(String word) {
    return Container(decoration: BoxDecoration(color: widget.isDarkMode ? Colors.grey[800] : Colors.purple[50], borderRadius: BorderRadius.circular(24)), alignment: Alignment.center, child: Text(word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)));
  }

  Widget _buildCardBack(WordModel word) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: widget.isDarkMode ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.purple)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Divider(), ...word.meanings.map((m) => Text("• $m")), const SizedBox(height: 12), ...word.examples.map((e) => Text("» $e"))]));
  }

  Widget _buildDrawer() {
    return Drawer(child: ListView(children: [
      const DrawerHeader(decoration: BoxDecoration(color: Colors.purple), child: Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 20))),
      ListTile(leading: const Icon(Icons.add), title: const Text("Kelime Ekle"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(libraries: _libraries, onWordAdded: (w) { setState(() { _allWords.add(w); _updateLibraryList(); }); _saveWords(); }))); }),
      ListTile(leading: const Icon(Icons.list), title: const Text("Kelime Listesi"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: _allWords, onWordDeleted: (w) { setState(() { _allWords.removeWhere((x) => x.word == w.word); }); _saveWords(); }))); }),
      ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz"), onTap: () { Navigator.pop(context); _startQuiz(); }),
      ListTile(leading: const Icon(Icons.file_upload), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
      ListTile(leading: const Icon(Icons.error), title: const Text("Yanlış Kelimeler"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WrongWordsScreen(wrongWords: _wrongWords))); }),
    ]));
  }

  void _startQuiz() {
    var quizList = _getCurrentFilteredWords();
    if (quizList.length < 4) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(words: quizList, questionCount: _quizQuestionCount, threshold: _masteryThreshold, onWrongWord: (w) { setState(() { var idx = _wrongWords.indexWhere((x) => x.wordInfo.word == w.word); if (idx == -1) { _wrongWords.add(WrongWordModel(wordInfo: w, wrongCount: 1)); } else { _wrongWords[idx].wrongCount++; } }); _saveAppState(); }, onWordMastered: (w) { setState(() { _learnedWords.add(w); _allWords.removeWhere((x) => x.word == w.word); }); _saveWords(); _saveAppState(); })));
  }
}
