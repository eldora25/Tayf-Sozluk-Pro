part of 'home_screen.dart';

extension HomeDrawer on _HomeScreenState {
  Widget buildDrawer() {
    return Drawer(
      elevation: 10,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), 
      child: RepaintBoundary( 
        child: _isLowPowerMode 
          ? Container(color: Theme.of(context).scaffoldBackgroundColor, child: _buildDrawerContent())
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
              child: _buildDrawerContent(),
            ),
      ),
    );
  }

  Widget _buildDrawerContent() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                AnimatedBuilder(
                  animation: _bgGradientController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary, Colors.indigoAccent],
                          stops: [0.0, _bgGradientController.value, 1.0],
                          begin: Alignment.topLeft, end: Alignment.bottomRight
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                              image: const DecorationImage(image: AssetImage('assets/ic_launcher.png'), fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text("Lexis Eldora", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Text("Build v2.4.${_HomeScreenState.buildNo}", style: const TextStyle(color: Colors.white70, fontSize: 13))
                        ],
                      ),
                    );
                  }
                ),
                
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: changeUsernameDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.08), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15)))),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8)]),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Kullanıcı Adı", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                Text(_username, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          Icon(Icons.edit, color: Colors.grey.shade400, size: 20),
                        ]
                      )
                    ),
                  ),
                ),
                
                ListTile(tileColor: Colors.blue.withOpacity(0.1), leading: const Icon(Icons.ac_unit, color: Colors.blue), title: const Text("Buz Kalkanı Al (100 💎)", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Mevcut Kalkan: $streakFreezes ❄️\nSerinin bozulmasını engeller."), onTap: () { Navigator.pop(context); buyFreeze(); }),
                const Divider(),
                
                ListTile(leading: const Icon(Icons.travel_explore, color: Colors.indigoAccent), title: const Text("WordNet Browser", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)), subtitle: const Text("Gelişmiş İng-İng Sözlük Arama"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordNetSearchScreen(words: [...allWords, ...learnedWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords]))); }),
                ListTile(leading: const Icon(Icons.add_box), title: const Text("Kelime Ekle"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(availableLibraries: safeLibraries(), onSave: (w) { setState(() => allWords.add(w)); buildActiveDeck(); savePreferencesOnly(); }))); }),
                ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: _activeDeck, onDelete: (w) { setState(() { allWords.remove(w); toRepeatWords.remove(w); toSRSRepeatWords.remove(w); _activeDeck.remove(w); }); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onLearned: markAsLearned))); }),
                
                ListTile(
                  leading: const Icon(Icons.settings), 
                  title: const Text("Ayarlar, Temalar, Seçimler"), 
                  onTap: () { 
                    HapticFeedback.lightImpact(); Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                      currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, isGlobalSrsEnabled: _globalSrs, isLowPowerMode: _isLowPowerMode, availableLibraries: safeLibraries(), 
                      onSaveSettings: (nG, nT, nQC, nTI, nL, nLv, glSrs, lowPow) async { 
                        setState(() { 
                          dailyGoal = nG; quizThreshold = nT; quizQuestionCount = nQC; widget.onThemeChanged(nTI); 
                          selectedLibrary = nL; selectedLevel = nLv; _globalSrs = glSrs; _isLowPowerMode = lowPow; 
                          if (nL == 'WordNet Veritabanı') {
                            _isAppLoading = true;
                            _loadingText = "Devasa WordNet veritabanından en güzel kelimeler çekiliyor...\nLütfen sabırlı olun.";
                          }
                        }); 
                        await Future.delayed(const Duration(milliseconds: 100));
                        await buildActiveDeck(); savePreferencesOnly(); 
                        setState(() { _isAppLoading = false; }); 
                        Future.delayed(const Duration(milliseconds: 150), () { showCenteredDialog(title: "Harika!", message: "Ayarlar başarıyla kalıcı olarak kaydedildi.", icon: Icons.verified_user, color: Colors.green); });
                      }, 
                      onAddPackage: installLocalPackage // ÇÖZÜM: Çakışma Düzeltildi
                    ))); 
                  }
                ),
                
                const Divider(),
                ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: const Text("Öğrenilen Kelimeler"), subtitle: Text("${learnedWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Öğrenilen Kelimeler", words: learnedWords, onDelete: (w) { setState(() => learnedWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => learnedWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                ListTile(leading: const Icon(Icons.repeat, color: Colors.orange), title: const Text("Tekrar Listesi (Normal)"), subtitle: Text("${toRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Tekrar Listesi", words: toRepeatWords, onDelete: (w) { setState(() => toRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => toRepeatWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                ListTile(leading: const Icon(Icons.schedule, color: Colors.blue), title: const Text("SRS Tekrar Listesi"), subtitle: Text("${toSRSRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "SRS Tekrar Listesi", words: toSRSRepeatWords, showSrsLevel: true, onDelete: (w) { setState(() => toSRSRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => toSRSRepeatWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text("Yanlış Kelimeler"), subtitle: Text("${wrongWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Yanlış Kelimeler", words: wrongWords, showWrongCount: true, onDelete: (w) { setState(() => wrongWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => wrongWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                
                ListTile(leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber), title: const Text("Karantina & Hata Havuzu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)), subtitle: Text("${reviewWordsPool.length} kelime (İncelenecek)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Karantina & Hata Havuzu", words: reviewWordsPool, onDelete: (w) { setState(() => reviewWordsPool.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => reviewWordsPool.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                ListTile(leading: const Icon(Icons.dangerous, color: Colors.redAccent), title: const Text("Bir daha görmek istemiyorum", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)), subtitle: const Text("Kara liste (İzole edilmiş kelimeler)"), onTap: () async { HapticFeedback.lightImpact(); Navigator.pop(context); List<WordModel> blacklistWords = await isar.wordModels.filter().listTypeEqualTo('blacklist').findAll(); if (mounted) { Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Kara Liste", words: blacklistWords, availableLibraries: safeLibraries(), onDelete: (w) { setState(() { }); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() { }); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) { setState((){}); loadData(); }); } }),
                
                const Divider(),
                ListTile(leading: const Icon(Icons.my_library_books), title: const Text("Kütüphane Yönetimi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(allWords: allWords, learningWords: learningWords, learnedWords: learnedWords, toRepeatWords: [...toRepeatWords, ...toSRSRepeatWords], wrongWords: wrongWords, onRename: renameLibrary, onDelete: deleteLibrary, onExport: exportLibrary, onPointsEarned: (points) => recordActivity(points)))); }),
                
                ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: _activeDeck, isWordNet: selectedLibrary == 'WordNet Veritabanı', onGameFinished: (points) { recordActivity(points); savePreferencesOnly(); }))); }),
                ListTile(leading: const Icon(Icons.mic, color: Colors.teal), title: const Text("Telaffuz Sınavı"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => PronunciationScreen(words: _activeDeck, isWordNet: selectedLibrary == 'WordNet Veritabanı', onGameFinished: (points) { recordActivity(points); savePreferencesOnly(); }))); }),
                ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () { 
                  HapticFeedback.lightImpact(); Navigator.pop(context); 
                  List<WordModel> fullPool = [];
                  if (selectedLibrary == 'WordNet Veritabanı') { var wnList = allWords.where((w) => w.libraryName == 'WordNet Veritabanı').toList(); wnList.shuffle(); fullPool = wnList.take(200).toList(); } 
                  else { fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList(); }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(words: fullPool, threshold: quizThreshold, questionCount: quizQuestionCount, isWordNet: selectedLibrary == 'WordNet Veritabanı', currentBestTime: bestQuizTime, currentBestCorrect: bestQuizCorrect, isLowPowerMode: _isLowPowerMode, onWordMastered: (w) => markAsLearned(w, fromQuiz: true), onWrongWord: (w) => markAsToRepeat(w, fromQuiz: true), onQuizFinished: (t, a, w, tp, firstTryCorrect, isNewRecord) { setState(() { totalCompletedQuizzes++; totalQuizTimeSeconds += t; totalQuizQuestions += a; totalQuizWrong += w; tayfPoints += tp; completedQuizTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); if (isNewRecord) { bestQuizTime = t; bestQuizCorrect = firstTryCorrect; final now = DateTime.now(); bestQuizDate = "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}"; } }); savePreferencesOnly(); }))).then((_) { loadData(); setState((){}); }); 
                }),
                ListTile(leading: const Icon(Icons.analytics), title: const Text("İstatistikler & Rozetler"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(allWords: allWords, learningWords: learningWords, toRepeatWords: toRepeatWords, toSRSRepeatWords: toSRSRepeatWords, learnedWords: learnedWords, wrongWords: wrongWords, availableLibraries: safeLibraries(), totalCompletedQuizzes: totalCompletedQuizzes, totalQuizTimeSeconds: totalQuizTimeSeconds, totalQuizQuestions: totalQuizQuestions, totalQuizWrong: totalQuizWrong, learnedWordTimestamps: learnedWordTimestamps, completedQuizTimestamps: completedQuizTimestamps, viewedCardTimestamps: viewedCardTimestamps, wrongAnswerTimestamps: wrongAnswerTimestamps, firstUseTimestamp: firstUseTimestamp, bestStreak: bestStreak, tayfPoints: tayfPoints, bestQuizTime: bestQuizTime, bestQuizCorrect: bestQuizCorrect, bestQuizDate: bestQuizDate))); }), 
                
                const Divider(),
                ListTile(leading: const Icon(Icons.science, color: Colors.purple), title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)), subtitle: const Text("Görünüm ve fonksiyon testleri", style: TextStyle(fontSize: 12)), onTap: () async { HapticFeedback.lightImpact(); Navigator.pop(context); await Navigator.push(context, MaterialPageRoute(builder: (context) => const DemoScreen())); final prefs = await SharedPreferences.getInstance(); await prefs.setString('selectedLibrary', 'Tekrarlanması Gerekenler'); await prefs.setInt('currentCardIndex', 0); setState(() { selectedLibrary = 'Tekrarlanması Gerekenler'; currentCardIndex = 0; isFlipped = false; }); loadData(); }),
                ListTile(leading: const Icon(Icons.bug_report, color: Colors.orange), title: const Text("Hata Kayıtları (Log)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LoggerScreen())); }),
                
                const Divider(),
                ListTile(leading: const Icon(Icons.info_outline, color: Colors.indigo), title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen())); }),
                ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar (Sihirbaz)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); startImportWizard(); }), // ÇÖZÜM: İsim çakışması önlendi
                ListTile(leading: const Icon(Icons.share), title: const Text("Paylaş / Dışa Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); exportLibrary(selectedLibrary); }),
                ListTile(leading: const Icon(Icons.cloud_upload, color: Colors.blueAccent), title: const Text("Buluta Yedekle", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("SRS, TP, Rozetler ve özel kartları dışa aktar", style: TextStyle(fontSize: 12)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); cloudBackupProgress(); }),
                ListTile(leading: const Icon(Icons.cloud_download, color: Colors.green), title: const Text("Buluttan Geri Yükle", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Buluttaki yedeği cihazınıza çekin", style: TextStyle(fontSize: 12)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); cloudRestoreProgress(); }),
                ListTile(leading: const Icon(Icons.bug_report_outlined, color: Colors.redAccent), title: const Text("İstek / Hata Bildir", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())); }),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 16 + MediaQuery.of(context).padding.bottom), 
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.08), border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("V2.4.${_HomeScreenState.buildNo}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purpleAccent.shade400, Colors.deepPurple]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]),
                      child: const Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
