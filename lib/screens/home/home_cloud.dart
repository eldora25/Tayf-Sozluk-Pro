part of 'home_screen.dart';

String encodeWordsJson(List<Map<String, dynamic>> words) {
  return json.encode(words);
}

extension HomeCloud on _HomeScreenState {
  Future<void> cloudBackupProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int lastBackupTime = prefs.getInt('last_cloud_backup_time') ?? 0;
    int now = DateTime.now().millisecondsSinceEpoch;
    int sixHoursInMillis = 6 * 60 * 60 * 1000;

    if (now - lastBackupTime < sixHoursInMillis) {
      int remainingMillis = sixHoursInMillis - (now - lastBackupTime);
      int hours = remainingMillis ~/ (1000 * 60 * 60);
      int minutes = (remainingMillis % (1000 * 60 * 60)) ~/ (1000 * 60);

      showCenteredDialog(
        title: "Süre Sınırı",
        message: "Bulut yedeği Firebase kotalarını korumak için günde sadece 4 kez (6 saatte bir) alınabilir.\n\nKalan süre: $hours saat $minutes dakika.",
        icon: Icons.timer,
        color: Colors.orange
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            const SizedBox(width: 16),
            Expanded(child: Text("$_username geçmişi arka planda buluta yedekleniyor..."))
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      var customOrProgressWords = await isar.wordModels.filter()
          .not().libraryNameEqualTo('WordNet Veritabanı')
          .and()
          .group((q) => q.srsLevelGreaterThan(0)
                        .or().wrongCountGreaterThan(0)
                        .or().correctCountGreaterThan(0)
                        .or().listTypeEqualTo('learned')
                        .or().listTypeEqualTo('learning')
                        .or().listTypeEqualTo('toRepeat')
                        .or().listTypeEqualTo('toSRSRepeat')
                        .or().libraryNameEqualTo('İncelenecek Kelimeler')
                        .or().libraryNameEqualTo('Kara Liste')
                        .or().not().listTypeEqualTo('all'))
          .findAll();

      int srsWordCount = customOrProgressWords.length;

      Map<String, dynamic> statsMap = {
        "tayfPoints": tayfPoints,
        "currentStreak": currentStreak,
        "bestStreak": bestStreak,
        "streakFreezes": streakFreezes,
        "srsWordCount": srsWordCount,
        "dailyGoal": dailyGoal,
        "quizThreshold": quizThreshold,
        "quizQuestionCount": quizQuestionCount,
        "themeIndex": widget.themeIndex,
        "selectedLibrary": selectedLibrary,
        "selectedLevel": selectedLevel,
        "totalCompletedQuizzes": totalCompletedQuizzes,
        "totalQuizTimeSeconds": totalQuizTimeSeconds,
        "totalQuizQuestions": totalQuizQuestions,
        "totalQuizWrong": totalQuizWrong,
        "firstUseTimestamp": firstUseTimestamp,
        "bestQuizTime": bestQuizTime,
        "bestQuizCorrect": bestQuizCorrect,
        "bestQuizDate": bestQuizDate
      };

      Map<String, dynamic> arraysMap = {
        "learnedWordTimestamps": learnedWordTimestamps,
        "completedQuizTimestamps": completedQuizTimestamps,
        "viewedCardTimestamps": viewedCardTimestamps,
        "wrongAnswerTimestamps": wrongAnswerTimestamps
      };

      FirebaseSyncService.backupUserProgress(_username, statsMap, arraysMap, customOrProgressWords).then((result) async {
        if (result["success"] == true) {
          await prefs.setInt('last_cloud_backup_time', DateTime.now().millisecondsSinceEpoch);
          if (mounted) {
            showCenteredDialog(
              title: "Yedekleme Başarılı!",
              message: result["message"],
              icon: Icons.cloud_done,
              color: Colors.green
            );
          }
        } else {
          if (mounted) {
            showCenteredDialog(
              title: "Hata",
              message: result["message"],
              icon: Icons.error_outline,
              color: Colors.red
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yedekleme başarısız: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> exportProgress() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            const SizedBox(width: 16),
            Expanded(child: Text("$_username verileri arka planda şifreleniyor..."))
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      var customOrProgressWords = await isar.wordModels.filter()
          .not().libraryNameEqualTo('WordNet Veritabanı')
          .and()
          .group((q) => q.srsLevelGreaterThan(0)
                        .or().wrongCountGreaterThan(0)
                        .or().correctCountGreaterThan(0)
                        .or().listTypeEqualTo('learned')
                        .or().listTypeEqualTo('learning')
                        .or().listTypeEqualTo('toRepeat')
                        .or().listTypeEqualTo('toSRSRepeat')
                        .or().libraryNameEqualTo('İncelenecek Kelimeler')
                        .or().libraryNameEqualTo('Kara Liste')
                        .or().not().listTypeEqualTo('all'))
          .findAll();

      List<Map<String, dynamic>> wordsJson = customOrProgressWords.map((w) {
        return {
          "word": w.word,
          "meanings": w.meanings,
          "examples": w.examples,
          "libraryName": w.libraryName,
          "level": w.level,
          "correctCount": w.correctCount,
          "wrongCount": w.wrongCount,
          "listType": w.listType,
          "srsLevel": w.srsLevel,
          "nextReviewDate": w.nextReviewDate,
          "sourceLanguage": w.sourceLanguage,
          "targetLanguage": w.targetLanguage,
          "pos": w.pos,
          "synonyms": w.synonyms,
          "antonyms": w.antonyms
        };
      }).toList();

      Map<String, dynamic> backupData = {
        "app": "LexisEldora",
        "version": "2.4",
        "username": _username,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "stats": {
          "tayfPoints": tayfPoints,
          "currentStreak": currentStreak,
          "bestStreak": bestStreak,
          "streakFreezes": streakFreezes,
          "dailyGoal": dailyGoal,
          "quizThreshold": quizThreshold,
          "quizQuestionCount": quizQuestionCount,
          "themeIndex": widget.themeIndex,
          "selectedLibrary": selectedLibrary,
          "selectedLevel": selectedLevel,
          "totalCompletedQuizzes": totalCompletedQuizzes,
          "totalQuizTimeSeconds": totalQuizTimeSeconds,
          "totalQuizQuestions": totalQuizQuestions,
          "totalQuizWrong": totalQuizWrong,
          "firstUseTimestamp": firstUseTimestamp,
          "bestQuizTime": bestQuizTime,
          "bestQuizCorrect": bestQuizCorrect,
          "bestQuizDate": bestQuizDate
        },
        "arrays": {
          "learnedWordTimestamps": learnedWordTimestamps,
          "completedQuizTimestamps": completedQuizTimestamps,
          "viewedCardTimestamps": viewedCardTimestamps,
          "wrongAnswerTimestamps": wrongAnswerTimestamps
        },
        "words": wordsJson
      };

      String jsonStr = await compute(encodeWordsJson, [backupData]);
      final dir = await getTemporaryDirectory();
      String dateStr = DateTime.now().toIso8601String().split('T').first;
      File file = File('${dir.path}/${_username}_ilerleme_$dateStr.json');
      await file.writeAsString(jsonStr.substring(1, jsonStr.length - 1));

      await Share.shareXFiles([XFile(file.path)], subject: 'Lexis Eldora İlerleme Yedeği');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dışa aktarma başarısız: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> cloudRestoreProgress() async {
    TextEditingController userCtrl = TextEditingController(text: _username);
    String? targetUser = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Buluttan Geri Yükle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        content: TextField(
          controller: userCtrl,
          decoration: InputDecoration(
            hintText: "Kurtarılacak Kullanıcı Adı",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.blueAccent.withOpacity(0.05),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (userCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, userCtrl.text.trim());
              }
            },
            child: const Text("Sorgula", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (targetUser == null || targetUser.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 16),
            Expanded(child: Text("Bulutta ilerleme aranıyor..."))
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      Map<String, dynamic>? metaData = await FirebaseSyncService.checkUserProgressMetadata(targetUser);

      if (metaData == null) {
        if (mounted) showCenteredDialog(title: "Bulunamadı", message: "'$targetUser' adlı kullanıcıya ait bir bulut yedeği bulunamadı.", icon: Icons.cloud_off, color: Colors.orange);
        return;
      }

      int timestamp = metaData['backup_timestamp_ms'] ?? 0;
      String backupDate = "Bilinmeyen Tarih";
      if (timestamp > 0) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        backupDate = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }

      final stats = metaData['stats'] ?? {};
      int backupTp = stats['tayfPoints'] ?? 0;
      int backupShields = stats['streakFreezes'] ?? 0;
      int backupBestStreak = stats['bestStreak'] ?? 0;
      int backupSrsCount = stats['srsWordCount'] ?? 0;

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, a1, a2) => const SizedBox(),
          transitionBuilder: (context, a1, a2, child) {
            return Transform.scale(
              scale: Curves.easeOutBack.transform(a1.value),
              child: AlertDialog(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.cloud_download, color: Colors.green, size: 50)),
                    const SizedBox(height: 16),
                    const Text("Bulut Yedeği Bulundu!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text("'$targetUser' kullanıcısına ait yedek bilgileri:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("📅 Tarih:", style: TextStyle(fontWeight: FontWeight.bold)), Text(backupDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))]),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("💎 Tayf Puanı (TP):", style: TextStyle(fontWeight: FontWeight.bold)), Text("$backupTp", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("❄️ Kalkanlar:", style: TextStyle(fontWeight: FontWeight.bold)), Text("$backupShields", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan))]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("🔥 Ateşli Seri:", style: TextStyle(fontWeight: FontWeight.bold)), Text("$backupBestStreak Gün", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("🧠 Aktif SRS Kartı:", style: TextStyle(fontWeight: FontWeight.bold)), Text("$backupSrsCount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Bu ilerlemeyi cihazınıza geri yüklemek istiyor musunuz?", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () async {
                              Navigator.pop(context);
                              executeCloudRestore(targetUser, metaData);
                            },
                            child: const Text("EVET, YÜKLE", style: TextStyle(fontWeight: FontWeight.bold))
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ağ hatası: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> executeCloudRestore(String targetUser, Map<String, dynamic> metadata) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 16),
            Expanded(child: Text("Kelime listeleri buluttan indiriliyor, arka planda uygulanacak..."))
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      Map<String, dynamic>? fullData = await FirebaseSyncService.downloadUserProgressWords(targetUser, metadata);

      if (fullData != null) {
        await executeImportMerge(fullData, isCloud: true);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime verileri indirilemedi."), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İndirme hatası: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> importProgress() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 16),
                Expanded(child: Text("Dosya arka planda analiz ediliyor..."))
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.blueGrey,
            behavior: SnackBarBehavior.floating,
          )
        );

        String content = await file.readAsString();
        Map<String, dynamic> data = json.decode(content);

        if (data['app'] != "LexisEldora") throw Exception("Geçersiz yedek dosyası!");

        String backupUser = data['username'] ?? "Bilinmeyen";
        int timestamp = data['timestamp'] ?? 0;
        String backupDate = "Bilinmeyen Tarih";
        if (timestamp > 0) {
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          backupDate = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        if (mounted) {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, a1, a2) => const SizedBox(),
            transitionBuilder: (context, a1, a2, child) {
              return Transform.scale(
                scale: Curves.easeOutBack.transform(a1.value),
                child: AlertDialog(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.folder_zip, color: Colors.green, size: 50)),
                      const SizedBox(height: 16),
                      const Text("Dosyadan Yükleniyor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15, height: 1.5),
                          children: [
                            TextSpan(text: "'$backupUser'", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 18)),
                            const TextSpan(text: " adlı kullanıcının\n"),
                            TextSpan(text: "$backupDate", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: "\ntarihli ilerleme geçmişini (TP, Kalkanlar, SRS Kelimeleri, Seri ve Rozetler) yüklemek istiyor musunuz?"),
                          ]
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () async {
                                Navigator.pop(context);
                                await executeImportMerge(data);
                              },
                              child: const Text("YÜKLE", style: TextStyle(fontWeight: FontWeight.bold))
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dosya okunamadı: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> executeImportMerge(Map<String, dynamic> data, {bool isCloud = false}) async {
    if (mounted && !isCloud) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yerel dosya arka planda birleştiriliyor..."), backgroundColor: Colors.orange));
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = data['stats'];
      final arrays = data['arrays'];
      final wordsList = data['words'] as List<dynamic>? ?? [];

      if (stats != null) {
        await prefs.setInt('tayfPoints', stats['tayfPoints'] ?? 0);
        await prefs.setInt('currentStreak', stats['currentStreak'] ?? 0);
        await prefs.setInt('bestStreak', stats['bestStreak'] ?? 0);
        await prefs.setInt('streakFreezes', stats['streakFreezes'] ?? 0);

        int incomingGoal = stats['dailyGoal'] ?? 10;
        int incomingQC = stats['quizQuestionCount'] ?? 10;
        int incomingThresh = stats['quizThreshold'] ?? 10;

        await prefs.setInt('dailyGoal', incomingGoal);
        await prefs.setInt('quizQuestionCount', incomingQC);
        await prefs.setInt('quizThreshold', incomingThresh);

        await prefs.setInt('totalCompletedQuizzes', stats['totalCompletedQuizzes'] ?? 0);
        await prefs.setInt('totalQuizTimeSeconds', stats['totalQuizTimeSeconds'] ?? 0);
        await prefs.setInt('totalQuizQuestions', stats['totalQuizQuestions'] ?? 0);
        await prefs.setInt('totalQuizWrong', stats['totalQuizWrong'] ?? 0);
        await prefs.setInt('firstUseTimestamp', stats['firstUseTimestamp'] ?? 0);

        int incomingBestTime = stats['bestQuizTime'] ?? 999999;
        int incomingBestCorrect = stats['bestQuizCorrect'] ?? 0;

        if (incomingBestCorrect > bestQuizCorrect || (incomingBestCorrect == bestQuizCorrect && incomingBestTime < bestQuizTime)) {
          bestQuizTime = incomingBestTime;
          bestQuizCorrect = incomingBestCorrect;
          bestQuizDate = stats['bestQuizDate'] ?? "Bilinmiyor";
          await prefs.setInt('bestQuizTime', bestQuizTime);
          await prefs.setInt('bestQuizCorrect', bestQuizCorrect);
          await prefs.setString('bestQuizDate', bestQuizDate);
        }
      }

      if (arrays != null) {
        await prefs.setStringList('learnedWordTimestamps', List<String>.from(arrays['learnedWordTimestamps'] ?? []));
        await prefs.setStringList('completedQuizTimestamps', List<String>.from(arrays['completedQuizTimestamps'] ?? []));
        await prefs.setStringList('viewedCardTimestamps', List<String>.from(arrays['viewedCardTimestamps'] ?? []));
        await prefs.setStringList('wrongAnswerTimestamps', List<String>.from(arrays['wrongAnswerTimestamps'] ?? []));
      }

      List<WordModel> wordsToUpdate = [];
      List<WordModel> wordsToInsert = [];

      for (var wMap in wordsList) {
        WordModel imported = WordModel.fromJson(json.encode(wMap));
        var existing = await isar.wordModels.filter().wordEqualTo(imported.word, caseSensitive: false).libraryNameEqualTo(imported.libraryName, caseSensitive: false).findFirst();

        if (existing != null) {
          existing.correctCount = imported.correctCount;
          existing.wrongCount = imported.wrongCount;
          existing.listType = imported.listType;
          existing.srsLevel = imported.srsLevel;
          existing.nextReviewDate = imported.nextReviewDate;
          wordsToUpdate.add(existing);
        } else {
          wordsToInsert.add(imported);
        }
      }

      await isar.writeTxn(() async {
        if (wordsToUpdate.isNotEmpty) await isar.wordModels.putAll(wordsToUpdate);
        if (wordsToInsert.isNotEmpty) await isar.wordModels.putAll(wordsToInsert);
      });

      if (mounted) {
        int finalTp = stats?['tayfPoints'] ?? 0;
        int finalShields = stats?['streakFreezes'] ?? 0;
        int finalStreak = stats?['bestStreak'] ?? 0;
        int totalProcessed = wordsToUpdate.length + wordsToInsert.length;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             title: const Row(
               children: [
                 Icon(Icons.check_circle, color: Colors.green, size: 30),
                 SizedBox(width: 8),
                 Text("İşlem Tamamlandı!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
               ],
             ),
             content: Text("Tüm yedek bilgiler cihazınıza işlendi:\n\n💎 $finalTp TP\n❄️ $finalShields Kalkan\n🔥 $finalStreak Ateşli Seri\n📦 $totalProcessed SRS / Özel Liste Kartı\n\nDeğişiklikleri görmek için uygulamayı şimdi yenileyelim mi?", style: const TextStyle(fontSize: 15, height: 1.4)),
             actions: [
               ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                 onPressed: () async {
                   Navigator.pop(ctx);
                   setState(() {
                     _isAppLoading = true;
                     _loadingText = "Yedekler Uygulanıyor. Lütfen Bekleyin...";

                     allWords.clear();
                     learningWords.clear();
                     learnedWords.clear();
                     toRepeatWords.clear();
                     toSRSRepeatWords.clear();
                     wrongWords.clear();
                     reviewWordsPool.clear();
                   });
                   await loadData();
                 },
                 child: const Text("Uygulamayı Yenile", style: TextStyle(fontWeight: FontWeight.bold))
               )
             ]
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Geçmiş birleştirilirken hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'json', 'txt']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.split('.').first;
      String? customLibraryName = await showInputDialog("Kütüphane Adı", fileName);
      if (customLibraryName == null) return;

      showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName aktarılıyor..."))])));

      String? dialogMessage;
      bool isSuccess = false;

      try {
        List<int> bytes = await file.readAsBytes();
        String content;
        try { content = utf8.decode(bytes); } catch (e) { content = String.fromCharCodes(bytes); }

        final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': content, 'extension': result.files.single.extension ?? '', 'libraryName': customLibraryName, 'originalFileName': fileName});

        if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
          dialogMessage = json.decode(parsedJsons.first)['error'];
        } else {
          Set<String> existingWords = {
            ...allWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...learnedWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...toRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...toSRSRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
            ...learningWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          };

          List<WordModel> newWords = [];
          for (var jsonStr in parsedJsons) {
            try {
              var w = WordModel.fromJson(jsonStr)..listType = 'all';
              if (!existingWords.contains(w.word)) {
                newWords.add(w);
                existingWords.add(w.word);
              }
            } catch (e) { continue; }
          }

          setState(() { allWords.addAll(newWords); selectedLibrary = customLibraryName; currentCardIndex = 0; });
          await buildActiveDeck();

          await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
          savePreferencesOnly();
          dialogMessage = "$customLibraryName başarıyla yüklendi!\n\n(${newWords.length} yeni kelime eklendi)";
          isSuccess = true;
        }
      } catch (e) {
        dialogMessage = "Sistem Hatası:\n$e";
      } finally {
        Navigator.pop(context);
        if (dialogMessage != null) {
          Future.delayed(const Duration(milliseconds: 150), () {
            showCenteredDialog(
              title: isSuccess ? "Tebrikler" : "Uyarı",
              message: dialogMessage!,
              icon: isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isSuccess ? Colors.green : Colors.orange
            );
          });
        }
      }
    }
  }

  Future<void> loadPackageFromAssets(String assetPath, String extension, String customLibraryName) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text("$customLibraryName yükleniyor..."))])));

    String? dialogMessage;
    bool isSuccess = false;

    try {
      ByteData data = await rootBundle.load(assetPath);
      List<int> bytes = data.buffer.asUint8List();
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (e) {
        content = String.fromCharCodes(bytes);
      }

      final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {'content': content, 'extension': extension, 'libraryName': customLibraryName, 'originalFileName': assetPath.split('/').last});

      if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
        dialogMessage = json.decode(parsedJsons.first)['error'];
      } else {
        Set<String> existingWords = {
          ...allWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...learnedWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...toRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...toSRSRepeatWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
          ...learningWords.where((w) => w.libraryName == customLibraryName).map((w) => w.word),
        };

        List<WordModel> newWords = [];
        for (var jsonStr in parsedJsons) {
          try {
            var w = WordModel.fromJson(jsonStr)..listType = 'all';
            if (!existingWords.contains(w.word)) {
              newWords.add(w);
              existingWords.add(w.word);
            }
          } catch (e) { continue; }
        }

        setState(() { allWords.addAll(newWords); selectedLibrary = customLibraryName; currentCardIndex = 0; });
        await buildActiveDeck();
        await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
        savePreferencesOnly();
        dialogMessage = "$customLibraryName başarıyla yüklendi!\n\n(${newWords.length} yeni kelime eklendi)";
        isSuccess = true;
      }
    } catch (e) {
      dialogMessage = "Sistem Hatası:\n$e";
    } finally {
      Navigator.pop(context);
      if (dialogMessage != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          showCenteredDialog(
            title: isSuccess ? "Tebrikler" : "Uyarı",
            message: dialogMessage!,
            icon: isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isSuccess ? Colors.green : Colors.orange
          );
        });
      }
    }
  }
}
