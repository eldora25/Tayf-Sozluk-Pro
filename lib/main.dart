import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'models.dart';
import 'quiz_screen.dart';
import 'add_word_screen.dart';
import 'word_list_screen.dart';
import 'settings_screen.dart';

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
  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = prefs.getBool('isDarkMode') ?? true);
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = value);
    prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // GitHub Run Number'ı dinamik olarak alıyoruz
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
  int currentCardIndex = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    _loadData();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
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
      currentCardIndex = prefs.getInt('currentCardIndex') ?? 0;

      allWords = _parseWordList(prefs.getStringList('allWords'));
      learnedWords = _parseWordList(prefs.getStringList('learnedWords'));
      toRepeatWords = _parseWordList(prefs.getStringList('toRepeatWords'));
      wrongWords = _parseWordList(prefs.getStringList('wrongWords'));

      if (allWords.isEmpty) {
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
    prefs.setInt('currentCardIndex', currentCardIndex);

    prefs.setStringList('allWords', allWords.map((e) => e.toJson()).toList());
    prefs.setStringList('learnedWords', learnedWords.map((e) => e.toJson()).toList());
    prefs.setStringList('toRepeatWords', toRepeatWords.map((e) => e.toJson()).toList());
    prefs.setStringList('wrongWords', wrongWords.map((e) => e.toJson()).toList());
  }

  void _createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.', 'Book a flight.'], libraryName: 'Varsayılan'),
    ];
    _saveData();
  }

  List<WordModel> get filteredWords {
    return allWords.where((w) => w.libraryName == selectedLibrary && w.level == selectedLevel).toList();
  }

  List<String> get availableLibraries {
    return allWords.map((e) => e.libraryName).toSet().toList();
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
      flutterTts.speak(word.word); 
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _markAsLearned(WordModel word) {
    setState(() {
      learnedWords.add(word);
      allWords.removeWhere((w) => w.word == word.word);
      _nextCard();
    });
    _saveData();
  }

  void _markAsToRepeat(WordModel word) {
    setState(() {
      if (!toRepeatWords.any((w) => w.word == word.word)) toRepeatWords.add(word);
      
      var existingWrong = wrongWords.where((w) => w.word == word.word).toList();
      if (existingWrong.isNotEmpty) {
        existingWrong.first.wrongCount++;
      } else {
        word.wrongCount = 1;
        wrongWords.add(word);
      }
      _nextCard();
    });
    _saveData();
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['csv', 'json', 'txt']
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String content = await file.readAsString(encoding: utf8);
      String extension = result.files.single.extension ?? '';

      String? customLibraryName = await _showInputDialog("Kütüphane Adı", fileName);
      if (customLibraryName == null || customLibraryName.isEmpty) return;

      List<WordModel> newWords = [];

      try {
        if (extension == 'json') {
          var decoded = json.decode(content);
          List list = decoded is Map ? decoded['words'] : decoded;
          newWords = list.map((e) => WordModel(
            word: e['word'] ?? '',
            meanings: List<String>.from(e['meanings'] ?? []),
            examples: List<String>.from(e['examples'] ?? []),
            level: e['level'] ?? 'Genel',
            libraryName: customLibraryName,
          )).toList();
        } else {
          List<List<dynamic>> rows = const CsvToListConverter().convert(content);
          for (var row in rows) {
            if (row.isEmpty) continue;
            newWords.add(WordModel(
              word: row[0].toString(),
              meanings: row.length > 1 ? row[1].toString().split(';') : [''],
              examples: row.length > 2 ? row[2].toString().split(';') : [],
              level: row.length > 3 && row[3].toString().isNotEmpty ? row[3].toString() : 'Genel',
              libraryName: customLibraryName,
            ));
          }
        }

        setState(() {
          allWords.addAll(newWords);
          selectedLibrary = customLibraryName;
          currentCardIndex = 0;
        });
        _saveData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${newWords.length} kelime aktarıldı.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dosya formatı hatalı: $e")));
      }
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
        title: Text("$selectedLibrary - $selectedLevel"),
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
                    LinearProgressIndicator(value: learnedWords.length / dailyGoal),
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
              const SizedBox(height: 40),
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
        color: widget.isDarkMode ? Colors.grey[800] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Center(child: Text(word.word, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
          Positioned(
            right: 0, top: 0,
            child: IconButton(
              icon: const Icon(Icons.volume_up, size: 30),
              onPressed: () => flutterTts.speak(word.word),
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
        color: widget.isDarkMode ? Colors.grey[700] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.volume_up), onPressed: () => flutterTts.speak(word.word)),
              ],
            ),
            const Divider(),
            const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ...word.meanings.map((m) => Text("• $m")),
            const SizedBox(height: 10),
            if (word.examples.isNotEmpty) const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ...word.examples.map((e) => Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic))),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Build: v1.0.$buildNo", style: const TextStyle(color: Colors.white70)),
                // HATA DÜZELTİLDİ: Colors.white50 yerine Colors.white54 kullanıldı
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
                onSave: (newWord) {
                  setState(() => allWords.add(newWord));
                  _saveData();
                }
              )));
            }
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("Kelime Listesi"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(
                words: allWords,
                onDelete: (wordToDelete) {
                  setState(() => allWords.removeWhere((w) => w.word == wordToDelete.word));
                  _saveData();
                }
              )));
            }
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Ayarlar"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                currentGoal: dailyGoal,
                currentThreshold: quizThreshold,
                onSaveSettings: (newGoal, newThreshold) {
                  setState(() {
                    dailyGoal = newGoal;
                    quizThreshold = newThreshold;
                  });
                  _saveData();
                }
              )));
            }
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text("Kütüphane Seç"),
            trailing: DropdownButton<String>(
              value: availableLibraries.contains(selectedLibrary) ? selectedLibrary : null,
              items: availableLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) { setState(() { selectedLibrary = v!; currentCardIndex=0; }); _saveData(); },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Seviye Seç"),
            trailing: DropdownButton<String>(
              value: selectedLevel,
              items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) { setState(() { selectedLevel = v!; currentCardIndex=0; }); _saveData(); },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text("Quiz"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                words: filteredWords,
                threshold: quizThreshold,
                onWordLearned: (w) => _markAsLearned(w),
                onWordWrong: (w) => _markAsToRepeat(w),
              )));
            },
          ),
          ListTile(leading: const Icon(Icons.upload_file), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text("Yanlış Kelimeler"),
            trailing: CircleAvatar(radius: 12, child: Text(wrongWords.length.toString(), style: const TextStyle(fontSize: 12))),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                appBar: AppBar(title: const Text("Yanlış Kelimeler")),
                body: ListView.builder(
                  itemCount: wrongWords.length,
                  itemBuilder: (c, i) => ListTile(
                    title: Text(wrongWords[i].word),
                    subtitle: Text(wrongWords[i].meanings.join(', ')),
                    trailing: Text("Yanlış: ${wrongWords[i].wrongCount}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                )
              )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Karanlık Mod"),
            trailing: Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
          ),
        ],
      ),
    );
  }
}
