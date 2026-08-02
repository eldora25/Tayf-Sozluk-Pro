import 'dart:convert';
import 'package:isar/isar.dart';

part 'models.g.dart';

@collection
class WordModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.hash)
  late String word;

  late List<String> meanings;
  late List<String> examples;
  
  @Index(type: IndexType.hash)
  late String libraryName;
  
  @Index(type: IndexType.hash)
  late String level;

  @Index(type: IndexType.value)
  int correctCount = 0;
  
  @Index(type: IndexType.value)
  int wrongCount = 0;

  @Index(type: IndexType.hash)
  String listType = 'all';

  @Index(type: IndexType.value)
  int srsLevel = 0;
  
  @Index(type: IndexType.value)
  int nextReviewDate = 0;

  // TTS için Kalıcı Dil Kimliği Parametreleri
  String sourceLanguage = 'en-US';
  String targetLanguage = 'tr-TR';

  WordModel({
    required this.word,
    required this.meanings,
    required this.examples,
    required this.libraryName,
    required this.level,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.listType = 'all',
    this.srsLevel = 0,
    this.nextReviewDate = 0,
    this.sourceLanguage = 'en-US',
    this.targetLanguage = 'tr-TR',
  });

  factory WordModel.fromJson(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    return WordModel(
      word: map['word'] ?? '',
      meanings: List<String>.from(map['meanings'] ?? []),
      examples: List<String>.from(map['examples'] ?? []),
      libraryName: map['libraryName'] ?? 'Varsayılan',
      level: map['level'] ?? 'Genel',
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      listType: map['listType'] ?? 'all',
      srsLevel: map['srsLevel'] ?? 0,
      nextReviewDate: map['nextReviewDate'] ?? 0,
      sourceLanguage: map['sourceLanguage'] ?? 'en-US',
      targetLanguage: map['targetLanguage'] ?? 'tr-TR',
    );
  }
}
```[cite: 12]

---

### Adım 2: `main.dart` İçindeki `_loadData()` Optimizasyonu

`main.dart` dosyanızda yer alan `_loadData()` fonksiyonunu, verileri sırayla beklemek yerine **`Future.wait`** ile paralel olarak çekecek ve UI thread üzerindeki yükü sıfırlayacak şekilde güncelliyoruz.

Lütfen `main.dart` dosyanızdaki **`_loadData()`** fonksiyonunu bulup şu şekilde güncelleyin:

```dart
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

      // PERFORMANS OPTİMİZASYONU: Tüm Isar sorguları Future.wait ile paralel yürütülür (Jank önleyici)
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
