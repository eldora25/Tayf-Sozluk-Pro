import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:lottie/lottie.dart';

import '../models.dart';
import '../core/db_helper.dart'; 
import '../core/tts_manager.dart'; 
import '../core/srs_engine.dart'; 
import '../core/data_parser.dart';
import '../widgets/shimmer_loading.dart';
import '../firebase_sync_service.dart';
import '../wordnet.dart'; 

import '../quiz_screen.dart';
import '../add_word_screen.dart';
import '../word_list_screen.dart';
import '../settings_screen.dart';
import '../statistics_screen.dart';
import '../edit_word_screen.dart';
import '../library_manager_screen.dart';
import '../manage_list_screen.dart';
import '../logger_screen.dart';
import '../match_game_screen.dart';
import '../pronunciation_screen.dart';
import '../info_screen.dart'; 
import '../wordnet_search_screen.dart'; 
import '../demo_screen.dart'; 
import '../report_screen.dart'; 

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
  late AnimationController _bgGradientController; 
  late AnimationController _auroraController; 
  late AnimationController _neonPulseController;
  late Animation<double> _neonPulseAnim;
  late AnimationController _tpFlashController;
  late AnimationController _freezeFlashController;
  late AnimationController _streakFlashController;
  late AnimationController _warningPulseController;

  bool _isAppLoading = true;
  String _loadingText = "Uygulama Hazırlanıyor...";

  List<WordModel> allWords = [];
  List<WordModel> learningWords = []; 
  List<WordModel> learnedWords = [];
  List<WordModel> toRepeatWords = [];
  List<WordModel> toSRSRepeatWords = []; 
  List<WordModel> wrongWords = []; 
  List<WordModel> reviewWordsPool = []; 
  
  List<WordModel> _cachedWordNetDeck = [];
  List<WordModel> _activeDeck = [];
  Map<String, int> _cardMistakes = {};

  String selectedLibrary = 'Test Paketi'; 
  String selectedLevel = 'Genel';
  int dailyGoal = 10, quizThreshold = 10, quizQuestionCount = 10, currentCardIndex = 0;
  bool isFlipped = false;
  
  int totalCompletedQuizzes = 0, totalQuizTimeSeconds = 0, totalQuizQuestions = 0, totalQuizWrong = 0;
  List<String> learnedWordTimestamps = [], completedQuizTimestamps = [], viewedCardTimestamps = [], wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0, currentStreak = 0, bestStreak = 0, tayfPoints = 0, streakFreezes = 0;

  int bestQuizTime = 999999;
  int bestQuizCorrect = 0;
  String bestQuizDate = "Henüz rekor yok";

  final List<Color> distinctColors = const [
    Color(0xFFFFEA00), Color(0xFFD500F9), Color(0xFF00E5FF), Color(0xFFFF3D00), Color(0xFF00E676)
  ];

  String _username = 'Eldora25';

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _bgGradientController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true); 
    _auroraController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true); 
    _neonPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _neonPulseAnim = Tween<double>(begin: 0.6, end: 1.4).animate(CurvedAnimation(parent: _neonPulseController, curve: Curves.easeInOutCubic));
    _tpFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _freezeFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _streakFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _warningPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _bgGradientController.dispose(); 
    _auroraController.dispose(); 
    _neonPulseController.dispose();
    _tpFlashController.dispose();
    _freezeFlashController.dispose();
    _streakFlashController.dispose();
    _warningPulseController.dispose();
    globalTts.stop();
    super.dispose();
  }

  Future<void> _buildActiveDeck() async {
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
        
        while(selectedIds.length < targetCount) {
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

  Future<void> _loadData() async {
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
               try { newWords.add(WordModel.fromJson(jsonStr)..listType = 'all'); } catch(e) {}
             }
             await isar.writeTxn(() async { await isar.wordModels.putAll(newWords); });
           } catch(e) { debugPrint("Test paketi yüklenemedi: $e"); }
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
        _createDefaultLibrary();
      }

      await _buildActiveDeck(); 

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
          if (mounted) _showInitialImportPrompt();
        });
      }

    } catch (e) {
      debugPrint("Load Data Error: $e");
      GlobalLogger.addLog("Load Data Error: $e");
      setState(() { _isAppLoading = false; });
    }
  }

  Future<void> _savePreferencesOnly() async {
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
  void _showCenteredDialog({required String title, required String message, required IconData icon, required Color color}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 70),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ]
        )
      )
    );
  }

  void _changeUsernameDialog() {
    TextEditingController userCtrl = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.badge, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 10),
            const Text("Kullanıcı Adı", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: userCtrl,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), 
          ],
          decoration: InputDecoration(
            hintText: "Örn: Tayfun25",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String newName = userCtrl.text.trim();
              if (newName.length >= 3 && newName.length <= 11) {
                setState(() => _username = newName);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', newName);
                if (mounted) Navigator.pop(context);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı adı en az 3, en fazla 11 karakter olmalıdır!")));
              }
            },
            child: const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cloudBackupProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int lastBackupTime = prefs.getInt('last_cloud_backup_time') ?? 0;
    int now = DateTime.now().millisecondsSinceEpoch;
    int sixHoursInMillis = 6 * 60 * 60 * 1000;
    
    if (now - lastBackupTime < sixHoursInMillis) {
      int remainingMillis = sixHoursInMillis - (now - lastBackupTime);
      int hours = remainingMillis ~/ (1000 * 60 * 60);
      int minutes = (remainingMillis % (1000 * 60 * 60)) ~/ (1000 * 60);
      
      _showCenteredDialog(
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
              _showCenteredDialog(
                title: "Yedekleme Başarılı!", 
                message: result["message"], 
                icon: Icons.cloud_done, 
                color: Colors.green
              );
            }
         } else {
            if (mounted) {
              _showCenteredDialog(
                title: "Hata", 
                message: result["message"], 
                icon: Icons.error_outline, 
                color: Colors.red
              );
            }
         }
      });

    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yedekleme başarısız: $e"), backgroundColor: Colors.red));
      }
    }
  }

  static String _encodeWordsJson(List<Map<String, dynamic>> words) {
    return json.encode(words);
  }

  Future<void> _exportProgress() async {
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

      String jsonStr = await compute(_encodeWordsJson, [backupData]); 
      final dir = await getTemporaryDirectory();
      String dateStr = DateTime.now().toIso8601String().split('T').first;
      File file = File('${dir.path}/${_username}_ilerleme_$dateStr.json');
      await file.writeAsString(jsonStr.substring(1, jsonStr.length - 1));

      await Share.shareXFiles([XFile(file.path)], subject: 'Lexis Eldora İlerleme Yedeği');

    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dışa aktarma başarısız: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _cloudRestoreProgress() async {
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
        if (mounted) _showCenteredDialog(title: "Bulunamadı", message: "'$targetUser' adlı kullanıcıya ait bir bulut yedeği bulunamadı.", icon: Icons.cloud_off, color: Colors.orange);
        return;
      }

      int timestamp = metaData['backup_timestamp_ms'] ?? 0;
      String backupDate = "Bilinmeyen Tarih";
      if (timestamp > 0) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        backupDate = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
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
                              _executeCloudRestore(targetUser, metaData); 
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

  Future<void> _executeCloudRestore(String targetUser, Map<String, dynamic> metadata) async {
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
        await _executeImportMerge(fullData, isCloud: true);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime verileri indirilemedi."), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İndirme hatası: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _importProgress() async {
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
          backupDate = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
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
                                await _executeImportMerge(data);
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

  Future<void> _executeImportMerge(Map<String, dynamic> data, {bool isCloud = false}) async {
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

      for(var wMap in wordsList) {
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
        if(wordsToUpdate.isNotEmpty) await isar.wordModels.putAll(wordsToUpdate);
        if(wordsToInsert.isNotEmpty) await isar.wordModels.putAll(wordsToInsert);
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
                   await _loadData(); 
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

  void _showInitialImportPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Kapat",
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - a1.value)),
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network('https://assets2.lottiefiles.com/packages/lf20_q5pk6p1k.json', height: 120, repeat: false, errorBuilder: (c, e, s) => Icon(Icons.cloud_sync, size: 80, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 16),
                  const Text("Geri Döndünüz!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text("Daha önce kaydettiğiniz bir ilerleme geçmişiniz (Tayf Puanı, Buz Kalkanı, SRS Seviyeleri, Ateşli Seri ve Rozetler) varsa, şimdi cihazınıza aktarabilirsiniz.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text("GEÇMİŞİ BULUTTAN İNDİR", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        Navigator.pop(context);
                        _cloudRestoreProgress();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Sıfırdan Başla", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _triggerLevel5Celebration() {
    for (int i = 0; i < 40; i++) { 
      Future.delayed(Duration(milliseconds: i * 50), () {
        List<Color> confettiColors = [Colors.redAccent, Colors.greenAccent, Colors.blueAccent, Colors.yellowAccent, Colors.purpleAccent, Colors.pinkAccent, Colors.orangeAccent];
        Color randomColor = confettiColors[Random().nextInt(confettiColors.length)];
        
        _showFlyingParticle(Icons.star, randomColor, () {
          HapticFeedback.lightImpact();
        }, targetIndex: Random().nextInt(3), isConfetti: true);
      });
    }
  }

  void _showFlyingParticle(IconData icon, Color color, VoidCallback onArrived, {int targetIndex = 2, bool isConfetti = false}) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: isConfetti ? 1200 + Random().nextInt(600) : 1000), 
          curve: isConfetti ? Curves.easeOutCirc : Curves.easeInOutCubic,
          onEnd: () {
            overlayEntry?.remove();
            onArrived(); 
          },
          builder: (context, value, child) {
            double startX = MediaQuery.of(context).size.width / 2 - 20 + (isConfetti ? (Random().nextDouble() * 150 - 75) : 0);
            double startY = MediaQuery.of(context).size.height / 2 + (isConfetti ? (Random().nextDouble() * 150 - 75) : 0);
            
            double endX;
            if (isConfetti) {
              endX = startX + (Random().nextDouble() * 300 - 150);
            } else {
              if (targetIndex == 0) endX = MediaQuery.of(context).size.width * 0.2;
              else if (targetIndex == 1) endX = MediaQuery.of(context).size.width * 0.5 - 20;
              else endX = MediaQuery.of(context).size.width * 0.8;
            }
            
            double endY = isConfetti ? MediaQuery.of(context).size.height + 50 : (MediaQuery.of(context).padding.top + 40.0); 

            double currentX = startX + (endX - startX) * value;
            double currentY = startY + (endY - startY) * value;

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: isConfetti ? (1.0 - value).clamp(0.0, 1.0) : (value < 0.8 ? 1.0 : (1.0 - ((value - 0.8) * 5)).clamp(0.0, 1.0)), 
                child: Transform.scale(
                  scale: isConfetti ? (1.0 - (value * 0.5)) : (1.0 + (sin(value * pi) * 1.5)), 
                  child: Transform.rotate(
                    angle: isConfetti ? value * pi * 4 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.9), blurRadius: 25, spreadRadius: 5)]
                      ),
                      child: Icon(icon, color: color, size: isConfetti ? 20 : 30)
                    ),
                  )
                )
              ),
            );
          }
        );
      }
    );
    Overlay.of(context).insert(overlayEntry);
  }

  void _recordActivity(int pointsEarned) {
    if (pointsEarned > 0) {
      int particles = pointsEarned > 5 ? 5 : pointsEarned;
      int pointsPerParticle = pointsEarned ~/ particles;
      int remainder = pointsEarned % particles;

      for (int i = 0; i < particles; i++) {
        Future.delayed(Duration(milliseconds: i * 250), () {
          _showFlyingParticle(Icons.diamond, Colors.lightBlueAccent, () {
            if (mounted) {
              setState(() => tayfPoints += pointsPerParticle + (i == particles - 1 ? remainder : 0));
              _savePreferencesOnly();
              _tpFlashController.forward(from: 0.0).then((_) => _tpFlashController.reverse());
            }
          }, targetIndex: 2); 
        });
      }
    } else {
      _savePreferencesOnly();
    }
  }

  void _buyFreeze() {
    HapticFeedback.heavyImpact(); 
    if (tayfPoints >= 100) {
      setState(() { tayfPoints -= 100; });
      _savePreferencesOnly();
      
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
              content: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 50, spreadRadius: 20)]),
                  ),
                  const Icon(Icons.ac_unit, size: 100, color: Colors.white),
                  const Positioned(
                    bottom: 0, 
                    child: Text("KALKAN ALINDI!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.cyanAccent)]))
                  )
                ],
              )
            ),
          );
        }
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        _showFlyingParticle(Icons.ac_unit, Colors.cyanAccent, () {
          if (mounted) {
            setState(() { streakFreezes++; });
            _savePreferencesOnly();
            _freezeFlashController.forward(from: 0.0).then((_) => _freezeFlashController.reverse());
          }
        }, targetIndex: 1); 
      });

    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Kapat",
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, a1, a2) => const SizedBox(),
        transitionBuilder: (context, a1, a2, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(a1.value),
            child: AlertDialog(
              backgroundColor: Colors.redAccent.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Icon(Icons.warning, color: Colors.white, size: 50)),
              content: const Text("Yetersiz Tayf Puanı (TP). Kalkan için 100 TP gereklidir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        }
      );
    }
  }

  void _createDefaultLibrary() {
    allWords = [
      WordModel(word: 'Apple', meanings: ['Elma', 'Meyve'], examples: ['I ate an apple.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
      WordModel(word: 'Book', meanings: ['Kitap', 'Ayırtmak'], examples: ['Read a book.'], libraryName: 'Varsayılan (İng-Tr)', level: 'Genel', listType: 'all'),
    ];
    isar.writeTxnSync(() { isar.wordModels.putAllSync(allWords); });
    _savePreferencesOnly();
  }

  List<String> _safeLibraries() {
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

  Future<void> _speakWord(WordModel word, {bool isMeaning = false}) async {
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

  void _nextCard({bool increment = false}) {
    HapticFeedback.lightImpact(); 
    globalTts.stop();
    setState(() {
      isFlipped = false;
      _flipController.reset();
      if (increment) {
        currentCardIndex++;
      }
    });
    
    _savePreferencesOnly();
    if (_activeDeck.isNotEmpty) {
      if (currentCardIndex >= _activeDeck.length) currentCardIndex = 0;
      _speakWord(_activeDeck[currentCardIndex], isMeaning: false);
    }
  }

  void _flipCard(WordModel word) {
    HapticFeedback.selectionClick(); 
    if (isFlipped) { 
      _flipController.reverse(); 
      _speakWord(word, isMeaning: false); 
    } else { 
      _flipController.forward(); 
      _speakWord(word, isMeaning: true); 
      viewedCardTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); 
      _savePreferencesOnly();
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _checkDailyGoalBonus() async {
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
      _savePreferencesOnly();

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

  void _markAsLearned(WordModel word, {bool fromQuiz = false}) {
    HapticFeedback.heavyImpact(); 
    learnedWordTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    
    _checkDailyGoalBonus();

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
          _triggerLevel5Celebration();
          _recordActivity(10); 
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
         _recordActivity(1); 
      } else {
         _recordActivity(0); 
      }

      _activeDeck.removeWhere((w) => w.id == word.id);
    });

    if (word.id != Isar.autoIncrement && word.libraryName != 'WordNet Veritabanı') {
       Future.microtask(() async {
         await isar.writeTxn(() async { await isar.wordModels.put(word); });
       });
    }

    if (!fromQuiz) _nextCard(increment: false); 
    else _savePreferencesOnly(); 
  }

  void _markAsToRepeat(WordModel word, {bool fromQuiz = false}) {
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

    if (!fromQuiz) _nextCard(increment: false); 
    else _savePreferencesOnly();
  }

  void _moveToReview(WordModel word) {
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
    
    _nextCard(increment: false);
  }

  void _moveToBlacklist(WordModel word) {
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
    
    _nextCard(increment: false);
  }
