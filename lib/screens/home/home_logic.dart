part of 'home_screen.dart';

extension HomeLogic on _HomeScreenState {
  Future<void> buildActiveDeck() async {
    _activeDeck.clear();
    _cardMistakes.clear();

    if (selectedLibrary == 'Tekrarlanması Gerekenler') {
      List<WordModel> urgent = [];
      urgent.addAll(toSRSRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
      urgent.addAll(toRepeatWords.where((w) => selectedLevel == 'Genel' || w.level == selectedLevel));
      urgent.shuffle();
      _activeDeck.addAll(urgent);
    } else if (selectedLibrary == 'WordNet Veritabanı') {
      List<WordModel> wnUrgent = [];
      wnUrgent.addAll(toSRSRepeatWords.where((w) => w.libraryName == 'WordNet Veritabanı'));
      wnUrgent.addAll(toRepeatWords.where((w) => w.libraryName == 'WordNet Veritabanı'));
      wnUrgent.shuffle();

      List<int> allWordNetIds = await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').idProperty().findAll();
      List<WordModel> wnNew = [];

      if (allWordNetIds.isNotEmpty) {
        final random = Random();
        Set<int> selectedIds = {};
        int targetCount = min(200, allWordNetIds.length);

        while (selectedIds.length < targetCount) {
          selectedIds.add(allWordNetIds[random.nextInt(allWordNetIds.length)]);
        }

        List<WordModel?> fetchedWords = await isar.wordModels.getAll(selectedIds.toList());
        wnNew = fetchedWords.whereType<WordModel>().toList();
      }

      _cachedWordNetDeck = [...wnUrgent, ...wnNew];
      _activeDeck.addAll(_cachedWordNetDeck);
    } else {
      List<WordModel> urgent = [];
      urgent.addAll(toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      urgent.addAll(toRepeatWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      urgent.shuffle();

      List<WordModel> newWords = [];
      newWords.addAll(allWords.where((w) => w.libraryName == selectedLibrary && (selectedLevel == 'Genel' || w.level == selectedLevel)));
      newWords.shuffle();

      _activeDeck.addAll(urgent);
      _activeDeck.addAll(newWords);
    }
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _username = prefs.getString('username') ?? 'Eldora25';
      bestQuizTime = prefs.getInt('bestQuizTime') ?? 999999;
      bestQuizCorrect = prefs.getInt('bestQuizCorrect') ?? 0;
      bestQuizDate = prefs.getString('bestQuizDate') ?? "Henüz rekor yok";

      int wordNetCount = await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').count();

      if (wordNetCount < 50000) {
        setState(() {
          _loadingText = "WordNet İlk Kurulumu Yapılıyor...\n(Bu işlem sadece 1 kez yapılır\nve cihaz hızına göre 1-2 dk sürebilir)";
        });

        await isar.writeTxn(() async {
          await isar.wordModels.filter().libraryNameEqualTo('WordNet Veritabanı').deleteAll();
        });

        List<WordModel> wnList = await WordNetInstaller.getWordNetModels();

        if (wnList.isNotEmpty) {
          setState(() {
            _loadingText = "Veritabanına Gömülüyor...\n(${wnList.length} Kelime)\nLütfen uygulamayı kapatmayın...";
          });

          int batchSize = 5000;
          for (int i = 0; i < wnList.length; i += batchSize) {
            int end = (i + batchSize < wnList.length) ? i + batchSize : wnList.length;
            await isar.writeTxn(() async {
              await isar.wordModels.putAll(wnList.sublist(i, end));
            });
            await Future.delayed(const Duration(milliseconds: 10));
          }
          GlobalLogger.addLog("WordNet Isar'a başarıyla kuruldu.");
        } else {
          GlobalLogger.addLog("HATA: WordNet verileri çıkarılamadı.");
        }
      }

      setState(() { _loadingText = "Kullanıcı Verileri Yükleniyor..."; });

      String savedLib = prefs.getString('selectedLibrary') ?? '';
      if (savedLib.isEmpty || savedLib == 'Varsayılan') {
        int testPackCount = await isar.wordModels.filter().libraryNameEqualTo('Test Paketi').count();
        if (testPackCount == 0) {
          try {
            final ByteData data = await rootBundle.load('assets/test_paket.json');
            final List<int> bytes = data.buffer.asUint8List();
            final String content = utf8.decode(bytes);
            final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {
              'content': content,
              'extension': 'json',
              'libraryName': 'Test Paketi',
              'originalFileName': 'test_paket.json'
            });

            List<WordModel> newWords = [];
            for (var jsonStr in parsedJsons) {
              try { newWords.add(WordModel.fromJson(jsonStr)..listType = 'all'); } catch (e) {}
            }
            await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
          } catch (e) { debugPrint("Test paketi yüklenemedi: $e"); }
        }
        selectedLibrary = 'Test Paketi';
        prefs.setString('selectedLibrary', 'Test Paketi');
      } else {
        selectedLibrary = savedLib;
      }

      setState(() {
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

      allWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');
      learningWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');
      learnedWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');
      toRepeatWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');
      toSRSRepeatWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');
      wrongWords.removeWhere((w) => w.libraryName == 'İncelenecek Kelimeler' || w.libraryName == 'Kara Liste');

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
        createDefaultLibrary();
      }

      await buildActiveDeck();

      setState(() {
        int urgentCount = _activeDeck.where((w) => w.listType == 'toSRSRepeat' || w.listType == 'toRepeat').length;

        if (urgentCount > 0 && currentCardIndex >= urgentCount) {
          currentCardIndex = 0;
          isFlipped = false;
        } else if (_activeDeck.isNotEmpty && currentCardIndex >= _activeDeck.length) {
          currentCardIndex = 0;
          isFlipped = false;
        }

        _isAppLoading = false;
      });

      bool hasSeenImportPrompt = prefs.getBool('has_seen_import_prompt') ?? false;
      if (!hasSeenImportPrompt) {
        prefs.setBool('has_seen_import_prompt', true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) showInitialImportPrompt();
        });
      }

    } catch (e) {
      debugPrint("Load Data Error: $e");
      GlobalLogger.addLog("Load Data Error: $e");
      setState(() { _isAppLoading = false; });
    }
  }

  Future<void> savePreferencesOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      prefs.setString('username', _username);
      prefs.setInt('bestQuizTime', bestQuizTime);
      prefs.setInt('bestQuizCorrect', bestQuizCorrect);
      prefs.setString('bestQuizDate', bestQuizDate);

      if (learnedWordTimestamps.length > 5000) learnedWordTimestamps.removeRange(0, learnedWordTimestamps.length - 5000);
      if (completedQuizTimestamps.length > 5000) completedQuizTimestamps.removeRange(0, completedQuizTimestamps.length - 5000);
      if (viewedCardTimestamps.length > 5000) viewedCardTimestamps.removeRange(0, viewedCardTimestamps.length - 5000);
      if (wrongAnswerTimestamps.length > 5000) wrongAnswerTimestamps.removeRange(0, wrongAnswerTimestamps.length - 5000);

      prefs.setString('selectedLibrary', selectedLibrary);
      prefs.setString('selectedLevel', selectedLevel);
      prefs.setInt('dailyGoal', dailyGoal);
      prefs.setInt('quizQuestionCount', quizQuestionCount);
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

  void createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
    ];
    isar.writeTxnSync(() { isar.wordModels.putAllSync(allWords); });
    savePreferencesOnly();
  }

  List<String> safeLibraries() {
    var libs = allWords.map((e) => e.libraryName).toSet()
      ..addAll(learnedWords.map((e) => e.libraryName))
      ..addAll(toRepeatWords.map((e) => e.libraryName))
      ..addAll(toSRSRepeatWords.map((e) => e.libraryName))
      ..addAll(learningWords.map((e) => e.libraryName));
    var uniqueLibs = libs.toSet();
    uniqueLibs.add('Tekrarlanması Gerekenler');
    uniqueLibs.add('WordNet Veritabanı');
    return uniqueLibs.toList();
  }

  Future<void> speakWord(WordModel word, {bool isMeaning = false}) async {
    try {
      await globalTts.stop();
      String rawText = "";

      if (isMeaning) {
        List<String> combinedList = [...word.meanings, ...word.examples];

        bool isWordNet = word.libraryName == 'WordNet Veritabanı' || word.pos.isNotEmpty || word.synonyms.isNotEmpty || word.antonyms.isNotEmpty;
        if (isWordNet) {
          if (word.synonyms.isNotEmpty) {
            combinedList.add("synonym: " + word.synonyms.take(4).join(', '));
          }
          if (word.antonyms.isNotEmpty) {
            combinedList.add("antonym: " + word.antonyms.take(4).join(', '));
          }
        }

        if (combinedList.isEmpty) return;
        rawText = combinedList.join('. ');
      } else {
        String wText = word.word;
        if (RegExp(r'^\d{8}-').hasMatch(wText) || wText.contains('[ID:')) {
          wText = word.synonyms.isNotEmpty ? word.synonyms.first : (word.meanings.isNotEmpty ? word.meanings.first : wText);
        }
        rawText = wText;
      }

      if (rawText.isEmpty) return;

      String cleanText = rawText
          .replaceAll(RegExp(r'\[.*?\]'), ' ')
          .replaceAll(RegExp(r'\(.*?\)'), ' ')
          .replaceAll(RegExp(r'[\[\]\{\}\\|_»•:;*+><=~]'), ' ')
          .replaceAll('ANLAM:', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      String detectText = isMeaning ? (word.meanings.isNotEmpty ? word.meanings.first : cleanText) : cleanText;

      String targetLang = isMeaning
          ? getSmartTargetLanguage(word.libraryName, detectText)
          : getSmartSourceLanguage(word.libraryName, detectText);

      globalTts.setLanguage(targetLang);
      globalTts.setSpeechRate(0.45);
      globalTts.speak(cleanText);
    } catch (e) {}
  }

  void nextCard({bool increment = false}) {
    HapticFeedback.lightImpact();
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
      if (increment) {
        currentCardIndex++;
      }
    });

    savePreferencesOnly();
    if (_activeDeck.isNotEmpty) {
      if (currentCardIndex >= _activeDeck.length) currentCardIndex = 0;
      speakWord(_activeDeck[currentCardIndex], isMeaning: false);
    }
  }

  void flipCard(WordModel word) {
    HapticFeedback.selectionClick();
    if (isFlipped) {
      _flipController.reverse();
      speakWord(word, isMeaning: false);
    } else {
      _flipController.forward();
      speakWord(word, isMeaning: true);
      viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
      savePreferencesOnly();
    }
    setState(() => isFlipped = !isFlipped);
  }

  void checkDailyGoalBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final lastClaimedDate = prefs.getString('daily_goal_bonus_date') ?? '';

    if (lastClaimedDate == todayStr) return;

    int learnedToday = learnedWordTimestamps.where((ts) {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      final dtStr = dt.toIso8601String().split('T').first;
      return dtStr == todayStr;
    }).length;

    if (learnedToday >= dailyGoal) {
      prefs.setString('daily_goal_bonus_date', todayStr);

      int dynamicBonusTp = dailyGoal;

      setState(() {
        tayfPoints += dynamicBonusTp;
      });
      savePreferencesOnly();

      if (mounted) {
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
                content: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.deepOrange.shade600, Colors.orangeAccent.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 70),
                      const SizedBox(height: 16),
                      const Text("GÜNLÜK HEDEF TAMAMLANDI! 🔥", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      const Text("Harika bir iş çıkardın! Hedefini tamamladığın için cömert bir alev bonusu kazandın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond, color: Colors.lightBlueAccent, size: 28),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("+$dynamicBonusTp TP KAZANDIN!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Süper!", style: TextStyle(fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    }
  }

  void markAsLearned(WordModel word, {bool fromQuiz = false}) {
    HapticFeedback.heavyImpact();
    learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());

    checkDailyGoalBonus();

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
          triggerLevel5Celebration();
          recordActivity(10);
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

      int mistakes = _cardMistakes[word.word] ?? 0;
      if (mistakes == 0) {
        recordActivity(1);
      } else {
        recordActivity(0);
      }

      _activeDeck.removeWhere((w) => w.id == word.id);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
      Future.microtask(() async {
        await isar.writeTxn(() async { await isar.wordModels.put(word); });
      });
    }

    if (!fromQuiz) nextCard(increment: false);
    else savePreferencesOnly();
  }

  void markAsToRepeat(WordModel word, {bool fromQuiz = false}) {
    HapticFeedback.mediumImpact();
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

      int currentMistakeCount = (_cardMistakes[word.word] ?? 0) + 1;
      _cardMistakes[word.word] = currentMistakeCount;
      int penalty = currentMistakeCount * 2;

      tayfPoints -= penalty;
      if (tayfPoints < 0) tayfPoints = 0;

      _tpFlashController.forward(from: 0.0).then((_) => _tpFlashController.reverse());

      _activeDeck.removeWhere((w) => w.id == word.id);
      _activeDeck.add(word);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
      Future.microtask(() async {
        await isar.writeTxn(() async { await isar.wordModels.put(word); });
      });
    }

    if (!fromQuiz) nextCard(increment: false);
    else savePreferencesOnly();
  }

  void moveToReview(WordModel word) {
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

      _activeDeck.removeWhere((w) => w.id == word.id);

      reviewWordsPool.add(word);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
      Future.microtask(() async {
        await isar.writeTxn(() async { await isar.wordModels.put(word); });
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Kelime karantinaya alındı! Bulut güven skoru düşürüldü.", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange)
    );

    nextCard(increment: false);
  }

  void moveToBlacklist(WordModel word) {
    HapticFeedback.heavyImpact();
    setState(() {
      word.libraryName = 'Kara Liste';
      word.listType = 'blacklist';

      allWords.removeWhere((w) => w.id == word.id);
      learningWords.removeWhere((w) => w.id == word.id);
      toRepeatWords.removeWhere((w) => w.id == word.id);
      toSRSRepeatWords.removeWhere((w) => w.id == word.id);
      wrongWords.removeWhere((w) => w.id == word.id);
      learnedWords.removeWhere((w) => w.id == word.id);
      reviewWordsPool.removeWhere((w) => w.id == word.id);

      _activeDeck.removeWhere((w) => w.id == word.id);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
      Future.microtask(() async {
        await isar.writeTxn(() async { await isar.wordModels.put(word); });
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kelime KARA LİSTE'ye eklendi ve tüm sistemlerden gizlendi.", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red)
    );

    nextCard(increment: false);
  }

  void renameLibrary(String oldName, String newName) async {
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

    await buildActiveDeck();
    isar.writeTxn(() async {
      List<WordModel> toUpdate = await isar.wordModels.filter().libraryNameEqualTo(oldName).findAll();
      for (var w in toUpdate) { w.libraryName = newName; }
      await isar.wordModels.putAll(toUpdate);
    });
    savePreferencesOnly();
  }

  void deleteLibrary(String libName) async {
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

    await buildActiveDeck();
    isar.writeTxn(() async {
      await isar.wordModels.filter().libraryNameEqualTo(libName).deleteAll();
    });
    savePreferencesOnly();
  }

  Future<void> exportLibrary(String libName) async {
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

  Future<String?> showInputDialog(String title, String defVal) {
    TextEditingController ctrl = TextEditingController(text: defVal);
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Kaydet"))]));
  }

  Future<void> openEditScreen(WordModel word) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => EditWordScreen(
      word: word, availableLibraries: safeLibraries(),
      onAction: (action, updatedWord) async {
        setState(() {
          if (action == EditAction.delete) {
            allWords.removeWhere((w) => w.id == word.id);
            toRepeatWords.removeWhere((w) => w.id == word.id);
            toSRSRepeatWords.removeWhere((w) => w.id == word.id);
            learningWords.removeWhere((w) => w.id == word.id);
            wrongWords.removeWhere((w) => w.id == word.id);
            learnedWords.removeWhere((w) => w.id == word.id);
            reviewWordsPool.removeWhere((w) => w.id == word.id);
            if (word.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.delete(word.id); });
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
            if (updatedWord.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          } else if (action == EditAction.copy) {
            allWords.add(updatedWord);
            if (updatedWord.id != Isar.autoIncrement) isar.writeTxn(() async { await isar.wordModels.put(updatedWord); });
          }
          currentCardIndex = 0;
        });
        await buildActiveDeck();
        savePreferencesOnly();
      },
    )));
  }
}
