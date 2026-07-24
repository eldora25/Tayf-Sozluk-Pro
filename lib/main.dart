import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'models/word_model.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: (val) => setState(() => _isDarkMode = val),
      ),
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
  
  // Uygulama Ayarları ve Durumları
  String buildNo = "451"; // CI/CD entegrasyonu simülasyonu
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
  bool _shuffleQuizQuestions = true;
  
  int _currentCardIndex = 0;
  bool _isCardFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadAllData();
    _initDefaultTestPackage();
  }

  void _initDefaultTestPackage() {
    if (_allWords.isEmpty) {
      List<Map<String, dynamic>> defaultData = [
        {"word": "word", "meanings": ["söz, sözcük, kelime", "lafız"], "examples": ["Words fail me.", "word game"], "level": "Genel", "libraryName": "test"},
        {"word": "book", "meanings": ["kitap", "rezervasyon yapmak"], "examples": ["I read a good book."], "level": "Genel", "libraryName": "test"},
        {"word": "mean", "meanings": ["anlamına gelmek", "cimri"], "examples": ["What do you mean?"], "level": "Genel", "libraryName": "test"},
        {"word": "light", "meanings": ["ışık", "hafif"], "examples": ["The light is bright."], "level": "Genel", "libraryName": "test"},
        {"word": "run", "meanings": ["koşmak", "yönetmek"], "examples": ["He runs fast."], "level": "Genel", "libraryName": "test"}
      ];
      setState(() {
        _allWords = defaultData.map((e) => WordModel.fromMap(e)).toList();
      });
      _saveWords();
    }
  }

  // SharedPreferences Kayıt ve Yükleme İşlemleri
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLibrary = prefs.getString('selectedLibrary') ?? 'test';
      _selectedLevel = prefs.getString('selectedLevel') ?? 'Genel';
      _dailyGoal = prefs.getInt('dailyGoal') ?? 10;
      _dailyProgress = prefs.getInt('dailyProgress') ?? 0;
      _quizQuestionCount = prefs.getInt('quizQuestionCount') ?? 10;
      _masteryThreshold = prefs.getInt('masteryThreshold') ?? 3;
      _shuffleQuizQuestions = prefs.getBool('shuffleQuizQuestions') ?? true;
      _currentCardIndex = prefs.getInt('currentCardIndex') ?? 0;
      
      String? wordsJson = prefs.getString('allWords');
      if (wordsJson != null) {
        _allWords = (json.decode(wordsJson) as List).map((e) => WordModel.fromMap(e)).toList();
      }
      String? learnedJson = prefs.getString('learnedWords');
      if (learnedJson != null) {
        _learnedWords = (json.decode(learnedJson) as List).map((e) => WordModel.fromMap(e)).toList();
      }
      String? reviewJson = prefs.getString('reviewWords');
      if (reviewJson != null) {
        _reviewWords = (json.decode(reviewJson) as List).map((e) => WordModel.fromMap(e)).toList();
      }
      String? wrongJson = prefs.getString('wrongWords');
      if (wrongJson != null) {
        _wrongWords = (json.decode(wrongJson) as List).map((e) => WrongWordModel.fromMap(e)).toList();
      }
      
      _libraries = _allWords.map((e) => e.libraryName).toSet().toList();
      if (!_libraries.contains('test')) _libraries.add('test');
    });
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('allWords', json.encode(_allWords.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveAppState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedLibrary', _selectedLibrary);
    prefs.setString('selectedLevel', _selectedLevel);
    prefs.putInt('dailyGoal', _dailyGoal);
    prefs.putInt('dailyProgress', _dailyProgress);
    prefs.putInt('quizQuestionCount', _quizQuestionCount);
    prefs.putInt('masteryThreshold', _masteryThreshold);
    prefs.putBool('shuffleQuizQuestions', _shuffleQuizQuestions);
    prefs.putInt('currentCardIndex', _currentCardIndex);
    prefs.setString('learnedWords', json.encode(_learnedWords.map((e) => e.toMap()).toList()));
    prefs.setString('reviewWords', json.encode(_reviewWords.map((e) => e.toMap()).toList()));
    prefs.setString('wrongWords', json.encode(_wrongWords.map((e) => e.toMap()).toList()));
  }

  // Seslendirme Fonksiyonu
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text);
  }

  // Kart Çevirme Animasyon Tetikleyicisi
  void _toggleCard() {
    if (_isCardFlipped) {
      _flipAnimationController.reverse();
    } else {
      _flipAnimationController.forward();
      if (_getCurrentFilteredWords().isNotEmpty) {
        _speak(_getCurrentFilteredWords()[_currentCardIndex].word);
      }
    }
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
  }

  List<WordModel> _getCurrentFilteredWords() {
    return _allWords.where((w) => w.libraryName == _selectedLibrary && w.level == _selectedLevel).toList();
  }

  // Buton Aksiyonları
  void _onBiliyorumPressed(WordModel word) {
    setState(() {
      _learnedWords.add(word);
      _allWords.remove(word);
      _dailyProgress++;
      _isCardFlipped = false;
      _flipAnimationController.reset();
      if (_currentCardIndex >= _getCurrentFilteredWords().length && _currentCardIndex > 0) {
        _currentCardIndex--;
      }
    });
    _saveWords();
    _saveAppState();
  }

  void _onTekrarPressed(WordModel word) {
    setState(() {
      if (!_reviewWords.any((w) => w.word == word.word)) {
        _reviewWords.add(word);
      }
      var existingWrong = _wrongWords.firstWhere((w) => w.wordInfo.word == word.word, 
          orElse: () => WrongWordModel(wordInfo: word, wrongCount: 0));
      if (existingWrong.wrongCount == 0) {
        _wrongWords.add(existingWrong);
      }
      existingWrong.wrongCount++;
      
      _isCardFlipped = false;
      _flipAnimationController.reset();
      if (_getCurrentFilteredWords().length > 1) {
        _currentCardIndex = (_currentCardIndex + 1) % _getCurrentFilteredWords().length;
      }
    });
    _saveAppState();
  }

  // Dışarıdan Dosya İçe Aktarma (JSON/CSV)
  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      String fileName = result.files.single.name.split('.').first;
      String content = await java.io.File(path).readAsString(encoding: utf8);

      TextEditingController nameController = TextEditingController(text: fileName);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Kütüphane İsmi"),
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "Kütüphane Adı")),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  List<dynamic> parsed = json.decode(content);
                  for (var item in parsed) {
                    _allWords.add(WordModel(
                      word: item['word'] ?? '',
                      meanings: List<String>.from(item['meanings'] ?? [item['meaning'] ?? '']),
                      examples: List<String>.from(item['examples'] ?? []),
                      level: item['level'] ?? 'Genel',
                      libraryName: nameController.text,
                    ));
                  }
                  setState(() {
                    _libraries.add(nameController.text);
                    _selectedLibrary = nameController.text;
                  });
                  _saveWords();
                  _saveAppState();
                } catch (e) {
                  // Fallback to simple parse lines if JSON fails
                }
                Navigator.pop(context);
              },
              child: const Text("Aktar"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = _getCurrentFilteredWords();
    WordModel? currentWord = filteredList.isNotEmpty && _currentCardIndex < filteredList.length 
        ? filteredList[_currentCardIndex] 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kelime Hatırlatıcı\n$_selectedLibrary / $_selectedLevel | Toplam: ${filteredList.length} kelime", 
          style: const TextStyle(fontSize: 14)),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Günlük hedef: $_dailyProgress / $_dailyGoal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _dailyGoal > 0 ? _dailyProgress / _dailyGoal : 0),
            const SizedBox(height: 32),
            Expanded(
              child: currentWord == null 
                  ? const Center(child: Text("Bu kütüphane veya seviyede kelime kalmadı!"))
                  : GestureDetector(
                      onTap: _toggleCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimationController,
                        builder: (context, child) {
                          final angle = _flipAnimationController.value * pi;
                          final isFront = angle < pi / 2;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isFront 
                                ? _buildCardFront(currentWord.word)
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi),
                                    child: _buildCardBack(currentWord),
                                  ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            if (currentWord != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 32),
                    onPressed: () => _openSettings(),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: () => _onBiliyorumPressed(currentWord),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Biliyorum", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: () => _onTekrarPressed(currentWord),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Tekrar", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text("v:1.0.$buildNo   By: Tayfun Yamak ©", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(String word) {
    return Container(
      decoration: BoxDecoration(color: widget.isDarkMode ? Colors.grey[800] : Colors.purple[50], borderRadius: BorderRadius.circular(24)),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple)),
              IconButton(icon: const Icon(Icons.volume_up, color: Colors.purple), onPressed: () => _speak(word)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Geri çevirmek için dokun", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardBack(WordModel word) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: widget.isDarkMode ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.purple.shade200)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
            const Divider(),
            const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ...word.meanings.map((m) => Text("• $m", style: const TextStyle(fontSize: 16))),
            const SizedBox(height: 12),
            const Text("Örnek Cümleler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ...word.examples.map((e) => Text("» $e", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
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
            decoration: const BoxDecoration(color: Colors.purple),
            child: Text("Tayf Sözlük Pro\nSürüm: v1.0.$buildNo\nTayfun Yamak ©", style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ListTile(leading: const Icon(Icons.add), title: const Text("Kelime Ekle"), onTap: () {}),
          ListTile(leading: const Icon(Icons.list), title: const Text("Kelime Listesi"), onTap: () {}),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text("Kütüphane Seç"),
            subtitle: Text(_selectedLibrary),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Kütüphane Seç"),
                  children: _libraries.map((lib) => SimpleDialogOption(
                    onPressed: () { setState(() => _selectedLibrary = lib); _saveAppState(); Navigator.pop(context); },
                    child: Text(lib),
                  )).toList(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Seviye Seç"),
            subtitle: Text(_selectedLevel),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Seviye Seç"),
                  children: ['A1','A2','B1','B2','C1','C2','Genel'].map((lvl) => SimpleDialogOption(
                    onPressed: () { setState(() => _selectedLevel = lvl); _saveAppState(); Navigator.pop(context); },
                    child: Text(lvl),
                  )).toList(),
                ),
              );
            },
          ),
          ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz"), onTap: () { Navigator.pop(context); _startQuiz(); }),
          ListTile(leading: const Icon(Icons.file_upload), title: const Text("İçe Aktar"), onTap: () { Navigator.pop(context); _importFile(); }),
          ListTile(
            leading: const Icon(Icons.error_outline), 
            title: const Text("Yanlış Kelimeler"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => WrongWordsScreen(wrongWords: _wrongWords)));
            }
          ),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Ayarlar"), onTap: () { Navigator.pop(context); _openSettings(); }),
        ],
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Quiz Ayarları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                decoration: const InputDecoration(labelText: "Quiz Soru Sayısı"),
                keyboardType: TextInputType.number,
                onChanged: (v) => _quizQuestionCount = int.tryParse(v) ?? 10,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Ezberleme Eşik Değeri"),
                keyboardType: TextInputType.number,
                onChanged: (v) => _masteryThreshold = int.tryParse(v) ?? 3,
              ),
              SwitchListTile(
                title: const Text("Karanlık Mod"),
                value: widget.isDarkMode,
                onChanged: (v) {
                  widget.onThemeChanged(v);
                  setModalState(() {});
                },
              ),
              ElevatedButton(
                onPressed: () { _saveAppState(); Navigator.pop(context); setState(() {}); },
                child: const Text("Kaydet"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz() {
    var quizList = _getCurrentFilteredWords();
    if (quizList.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz başlatmak için en az 4 kelime olmalıdır!")));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
      words: quizList,
      questionCount: _quizQuestionCount,
      threshold: _masteryThreshold,
      onWrongWord: (w) {
        if (!_wrongWords.any((element) => element.wordInfo.word == w.word)) {
          _wrongWords.add(WrongWordModel(wordInfo: w));
        } else {
          _wrongWords.firstWhere((element) => element.wordInfo.word == w.word).wrongCount++;
        }
        if (!_reviewWords.any((element) => element.wordInfo.word == w.word)) {
          _reviewWords.add(w);
        }
        _saveAppState();
      },
      onWordMastered: (w) {
        setState(() {
          _learnedWords.add(w);
          _allWords.removeWhere((element) => element.word == w.word);
        });
        _saveWords();
        _saveAppState();
      },
    )));
  }
}

// dynamic Quiz ve Yanlış Kelimeler ekran sınıfları aşağıda devam etmektedir...
