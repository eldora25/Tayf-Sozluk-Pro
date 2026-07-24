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
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Sözlük Pro',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
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
  String buildNo = "451"; 
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
    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // SharedPreferences Kayıt ve Yükleme İşlemleri
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
      
      _updateLibraryList();
      _isLoading = false;
    });

    if (_allWords.isEmpty) {
      _initDefaultTestPackage();
    }
  }

  void _updateLibraryList() {
    final extracted = _allWords.map((e) => e.libraryName).toSet().toList();
    for (var lib in extracted) {
      if (!_libraries.contains(lib)) {
        _libraries.add(lib);
      }
    }
    if (!_libraries.contains('test')) _libraries.add('test');
  }

  void _initDefaultTestPackage() {
    List<Map<String, dynamic>> defaultData = [
      {"word": "word", "meanings": ["söz, sözcük, kelime", "lafız"], "examples": ["Words fail me.", "word game"], "level": "Genel", "libraryName": "test"},
      {"word": "book", "meanings": ["kitap", "rezervasyon yapmak"], "examples": ["I read a good book."], "level": "Genel", "libraryName": "test"},
      {"word": "mean", "meanings": ["anlamına gelmek", "cimri"], "examples": ["What do you mean?"], "level": "Genel", "libraryName": "test"},
      {"word": "light", "meanings": ["ışık", "hafif"], "examples": ["The light is bright."], "level": "Genel", "libraryName": "test"},
      {"word": "run", "meanings": ["koşmak", "yönetmek"], "examples": ["He runs fast."], "level": "Genel", "libraryName": "test"}
    ];
    setState(() {
      _allWords = defaultData.map((e) => WordModel.fromMap(e)).toList();
      _updateLibraryList();
    });
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

  // Seslendirme Fonksiyonu
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text);
  }

  // Kart Çevirme Animasyon Tetikleyicisi
  void _toggleCard() {
    var filtered = _getCurrentFilteredWords();
    if (filtered.isEmpty) return;

    if (_isCardFlipped) {
      _flipAnimationController.reverse();
    } else {
      _flipAnimationController.forward();
      if (_currentCardIndex < filtered.length) {
        _speak(filtered[_currentCardIndex].word);
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
      _allWords.removeWhere((w) => w.word == word.word);
      _dailyProgress++;
      _isCardFlipped = false;
      _flipAnimationController.reset();
      
      var remaining = _getCurrentFilteredWords();
      if (_currentCardIndex >= remaining.length && _currentCardIndex > 0) {
        _currentCardIndex = remaining.length - 1;
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
      var existingWrongIndex = _wrongWords.indexWhere((w) => w.wordInfo.word == word.word);
      if (existingWrongIndex == -1) {
        _wrongWords.add(WrongWordModel(wordInfo: word, wrongCount: 1));
      } else {
        _wrongWords[existingWrongIndex].wrongCount++;
      }
      
      _isCardFlipped = false;
      _flipAnimationController.reset();
      
      var remaining = _getCurrentFilteredWords();
      if (remaining.length > 1) {
        _currentCardIndex = (_currentCardIndex + 1) % remaining.length;
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
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String content = await file.readAsString(encoding: utf8);

      TextEditingController nameController = TextEditingController(text: fileName);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Kütüphane İsmi Belirle"),
          content: TextField(
            controller: nameController, 
            decoration: const InputDecoration(labelText: "Kütüphane Adı", border: OutlineInputBorder())
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            TextButton(
              onPressed: () {
                String libName = nameController.text.trim().isEmpty ? fileName : nameController.text.trim();
                try {
                  // JSON formatı kontrolü
                  if (result.files.single.extension == 'json') {
                    var decoded = json.decode(content);
                    List<dynamic> wordsList = [];
                    if (decoded is Map && decoded.containsKey('words')) {
                      wordsList = decoded('words');
                    } else if (decoded is List) {
                      wordsList = decoded;
                    }

                    for (var item in wordsList) {
                      _allWords.add(WordModel(
                        word: item['word'] ?? '',
                        meanings: item['meanings'] != null ? List<String>.from(item['meanings']) : [item['meaning'] ?? ''],
                        examples: item['examples'] != null ? List<String>.from(item['examples']) : [],
                        level: item['level'] ?? 'Genel',
                        libraryName: libName,
                      ));
                    }
                  } else {
                    // Satır bazlı düz metin veya basit CSV ayrıştırma fallback'i
                    List<String> lines = const LineSplitter().convert(content);
                    for (var line in lines) {
                      var parts = line.split(',');
                      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                        _allWords.add(WordModel(
                          word: parts[0].trim(),
                          meanings: parts.length > 1 ? [parts[1].trim()] : ['Tanımlanmamış'],
                          examples: parts.length > 2 ? [parts[2].trim()] : [],
                          level: 'Genel',
                          libraryName: libName,
                        ));
                      }
                    }
                  }
                  
                  setState(() {
                    if (!_libraries.contains(libName)) _libraries.add(libName);
                    _selectedLibrary = libName;
                    _currentCardIndex = 0;
                  });
                  _saveWords();
                  _saveAppState();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$libName başarıyla içe aktarıldı!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dosya formatı hatalı veya okunamadı!")));
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    var filteredList = _getCurrentFilteredWords();
    WordModel? currentWord = filteredList.isNotEmpty && _currentCardIndex < filteredList.length 
        ? filteredList[_currentCardIndex] 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kelime Hatırlatıcı\n$_selectedLibrary / $_selectedLevel | Toplam: ${filteredList.length} kelime", 
          style: const TextStyle(fontSize: 13, height: 1.3)
        ),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text("Günlük hedef: $_dailyProgress / $_dailyGoal", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text("%${_dailyGoal > 0 ? ((_dailyProgress / _dailyGoal) * 100).clamp(0, 100).toInt() : 0}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _dailyGoal > 0 ? (_dailyProgress / _dailyGoal).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: currentWord == null 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.blur_on, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text("$_selectedLibrary kütüphanesinde\n$_selectedLevel seviyesine ait aktif kelime kalmadı.", textAlign: Center),
                        ],
                      ),
                    )
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
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () => _openSettings(),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => _onBiliyorumPressed(currentWord),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Biliyorum", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => _onTekrarPressed(currentWord),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Tekrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Text("v1.0.$buildNo   By: Tayfun Yamak ©", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(String word) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.purple[50], 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  word, 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.purple, size: 28), 
                onPressed: () => _speak(word)
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Geri çevirmek için dokun", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCardBack(WordModel word) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.purple.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.purple)),
              const Divider(height: 20, thickness: 1),
              const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
              const SizedBox(height: 6),
              ...word.meanings.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text("• $m", style: const TextStyle(fontSize: 16, height: 1.2)),
              )),
              const SizedBox(height: 18),
              const Text("Örnek Cümleler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
              const SizedBox(height: 6),
              word.examples.isEmpty 
                  ? const Text("Örnek cümle eklenmemiş.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: word.examples.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("» $e", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.3)),
                      )).toList(),
                    ),
            ],
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Tayf Sözlük Pro", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Sürüm: v1.0.$buildNo", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Text("Tayfun Yamak ©", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add), 
            title: const Text("Kelime Ekle"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(
                libraries: _libraries,
                onWordAdded: (newWord) {
                  setState(() {
                    _allWords.add(newWord);
                    _updateLibraryList();
                  });
                  _saveWords();
                },
              )));
            }
          ),
          ListTile(
            leading: const Icon(Icons.list), 
            title: const Text("Kelime Listesi"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(
                words: _allWords,
                onWordDeleted: (targetWord) {
                  setState(() {
                    _allWords.removeWhere((w) => w.word == targetWord.word);
                    _updateLibraryList();
                  });
                  _saveWords();
                },
              )));
            }
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text("Kütüphane Seç"),
            subtitle: Text(_selectedLibrary, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Kütüphane Seç"),
                  children: _libraries.map((lib) => SimpleDialogOption(
                    onPressed: () { 
                      setState(() { _selectedLibrary = lib; _currentCardIndex = 0; }); 
                      _saveAppState(); 
                      Navigator.pop(context); 
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(lib, style: const TextStyle(fontSize: 16)),
                    ),
                  )).toList(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Seviye Seç"),
            subtitle: Text(_selectedLevel, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Seviye Seç"),
                  children: ['A1','A2','B1','B2','C1','C2','Genel'].map((lvl) => SimpleDialogOption(
                    onPressed: () { 
                      setState(() { _selectedLevel = lvl; _currentCardIndex = 0; }); 
                      _saveAppState(); 
                      Navigator.pop(context); 
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(lvl, style: const TextStyle(fontSize: 16)),
                    ),
                  )).toList(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz), 
            title: const Text("Quiz"), 
            onTap: () { 
              Navigator.pop(context); 
              _startQuiz(); 
            }
          ),
          ListTile(
            leading: const Icon(Icons.file_upload), 
            title: const Text("İçe Aktar"), 
            onTap: () { 
              Navigator.pop(context); 
              _importFile(); 
            }
          ),
          ListTile(
            leading: const Icon(Icons.error_outline), 
            title: const Text("Yanlış Kelimeler"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => WrongWordsScreen(wrongWords: _wrongWords)));
            }
          ),
          ListTile(
            leading: const Icon(Icons.settings), 
            title: const Text("Ayarlar"), 
            onTap: () { 
              Navigator.pop(context); 
              _openSettings(); 
            }
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    final goalController = TextEditingController(text: _dailyGoal.toString());
    final countController = TextEditingController(text: _quizQuestionCount.toString());
    final thresholdController = TextEditingController(text: _masteryThreshold.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Uygulama Ayarları", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                const SizedBox(height: 16),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: "Günlük Öğrenme Hedefi", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(labelText: "Quiz Soru Sayısı", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(labelText: "Ezberleme Eşik Değeri (Doğru Sayısı)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text("Karanlık Mod / Gece Modu"),
                  secondary: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  value: widget.isDarkMode,
                  onChanged: (v) {
                    widget.onThemeChanged(v);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () { 
                      setState(() {
                        _dailyGoal = int.tryParse(goalController.text) ?? 10;
                        _quizQuestionCount = int.tryParse(countController.text) ?? 10;
                        _masteryThreshold = int.tryParse(thresholdController.text) ?? 3;
                      });
                      _saveAppState(); 
                      Navigator.pop(context); 
                    },
                    child: const Text("Ayarları Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz() {
    var quizList = _getCurrentFilteredWords();
    if (quizList.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz başlatmak için mevcut filtrede en az 4 kelime olmalıdır!")));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
      words: quizList,
      questionCount: _quizQuestionCount,
      threshold: _masteryThreshold,
      onWrongWord: (w) {
        setState(() {
          if (!_reviewWords.any((element) => element.word == w.word)) {
            _reviewWords.add(w);
          }
          var idx = _wrongWords.indexWhere((element) => element.wordInfo.word == w.word);
          if (idx == -1) {
            _wrongWords.add(WrongWordModel(wordInfo: w, wrongCount: 1));
          } else {
            _wrongWords[idx].wrongCount++;
          }
        });
        _saveAppState();
      },
      onWordMastered: (w) {
        setState(() {
          _learnedWords.add(w);
          _allWords.removeWhere((element) => element.word == w.word);
          var remaining = _getCurrentFilteredWords();
          if (_currentCardIndex >= remaining.length && _currentCardIndex > 0) {
            _currentCardIndex = remaining.length - 1;
          }
        });
        _saveWords();
        _saveAppState();
      },
    )));
  }
}
