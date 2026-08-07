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

import '../../models.dart';
import '../../core/db_helper.dart'; 
import '../../core/tts_manager.dart'; 
import '../../core/srs_engine.dart'; 
import '../../core/data_parser.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/premium_word_card.dart'; // YENİ: Parçalanmış (Refactored) Kart Modülü
import '../../firebase_sync_service.dart';
import '../../wordnet.dart'; 
import '../../notification_service.dart'; 

import '../../quiz_screen.dart';
import '../../add_word_screen.dart';
import '../../word_list_screen.dart';
import '../../settings_screen.dart';
import '../../statistics_screen.dart';
import '../../edit_word_screen.dart';
import '../../library_manager_screen.dart';
import '../../manage_list_screen.dart';
import '../import_wizard_screen.dart'; // YENİ: İçe Aktarma Sihirbazı Modülü
import '../../logger_screen.dart';
import '../../match_game_screen.dart';
import '../../pronunciation_screen.dart';
import '../../info_screen.dart'; 
import '../../wordnet_search_screen.dart'; 
import '../../demo_screen.dart'; 
import '../../report_screen.dart'; 

part 'home_logic.dart';
part 'home_cloud.dart';
part 'home_drawer.dart'; // YENİ: Parçalanmış Menü Modülü

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
  
  List<WordModel> _activeDeck = [];
  Map<String, int> _cardMistakes = {};

  String selectedLibrary = 'Test Paketi'; 
  String selectedLevel = 'Genel';
  bool _globalSrs = false; 
  bool _isLowPowerMode = false; 
  int dailyGoal = 10, quizThreshold = 10, quizQuestionCount = 10, currentCardIndex = 0;
  bool isFlipped = false;
  
  int totalCompletedQuizzes = 0, totalQuizTimeSeconds = 0, totalQuizQuestions = 0, totalQuizWrong = 0;
  List<String> learnedWordTimestamps = [], completedQuizTimestamps = [], viewedCardTimestamps = [], wrongAnswerTimestamps = [];
  int firstUseTimestamp = 0, currentStreak = 0, bestStreak = 0, tayfPoints = 0, streakFreezes = 0;

  int bestQuizTime = 999999;
  int bestQuizCorrect = 0;
  String bestQuizDate = "Henüz rekor yok";

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

    NotificationService.requestPermission();
    loadData(); 
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

  Widget _buildNeonBadge(IconData icon, String value, Color color, int count, AnimationController? flashController) {
    return AnimatedBuilder(
      animation: Listenable.merge([_neonPulseController, if (flashController != null) flashController]),
      builder: (context, child) {
        double baseSpread = (count * 0.3).clamp(2.0, 20.0); 
        double pulseSpread = baseSpread * _neonPulseAnim.value;
        double flashValue = flashController?.value ?? 0.0;
        double flashSpread = flashValue * 30.0; 
        double flashOpacity = (0.6 + (flashValue * 0.4)).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity((0.8 + (flashValue * 0.2)).clamp(0.0, 1.0)), width: 2 + (flashValue * 2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(flashOpacity),
                blurRadius: max(0.0, (baseSpread * 1.5) + flashSpread), 
                spreadRadius: max(0.0, pulseSpread + flashSpread),       
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20 + (flashValue * 8)),
              const SizedBox(width: 6),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16 + (flashValue * 4), color: Colors.white, shadows: [Shadow(color: color, blurRadius: max(0.0, flashValue * 15))])), 
            ]
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return PremiumShimmerLoading(loadingText: _loadingText);
    }

    var deck = _activeDeck; 
    if (currentCardIndex >= deck.length) currentCardIndex = 0;
    WordModel? currentWord = deck.isNotEmpty ? deck[currentCardIndex] : null;
    bool isSrsMode = currentWord != null && currentWord.listType == 'toSRSRepeat';

    int totalLibWords = allWords.where((w) => w.libraryName == selectedLibrary).length +
                        learningWords.where((w) => w.libraryName == selectedLibrary).length +
                        toRepeatWords.where((w) => w.libraryName == selectedLibrary).length +
                        toSRSRepeatWords.where((w) => w.libraryName == selectedLibrary).length +
                        learnedWords.where((w) => w.libraryName == selectedLibrary).length;
    int learnedLibWords = learnedWords.where((w) => w.libraryName == selectedLibrary).length;
    double progress = totalLibWords > 0 ? (learnedLibWords / totalLibWords) : 0.0;
    double bottomHeight = selectedLibrary != 'Tekrarlanması Gerekenler' ? 90.0 : 60.0;

    int pendingGlobalSrs = 0;
    if (!_globalSrs && selectedLibrary != 'Tekrarlanması Gerekenler') {
       pendingGlobalSrs = toSRSRepeatWords.where((w) => w.libraryName != selectedLibrary).length + 
                          toRepeatWords.where((w) => w.libraryName != selectedLibrary).length;
    }

    Widget mainContent = _buildMainContent(currentWord, isSrsMode, isFlipped, deck, totalLibWords, learnedLibWords, progress, bottomHeight);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: false,
        backgroundColor: Colors.transparent, 
        elevation: 0,
        flexibleSpace: RepaintBoundary( 
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.7), Theme.of(context).colorScheme.secondary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lexis Eldora", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(isSrsMode ? "SRS Tekrar Modu" : "$selectedLibrary - $selectedLevel (${deck.length})", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (pendingGlobalSrs > 0)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Dikkat! Diğer kütüphanelerde süresi gelmiş $pendingGlobalSrs SRS kartınız var. Ayarlardan Global SRS'i açarak onları buraya çekebilirsiniz."),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 4),
                  )
                );
              },
              child: AnimatedBuilder(
                animation: _warningPulseController,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.6 * _warningPulseController.value), blurRadius: 10, spreadRadius: 2)]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text("$pendingGlobalSrs", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                }
              ),
            )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children: [
                  _buildNeonBadge(Icons.local_fire_department, "$currentStreak", Colors.orangeAccent, currentStreak, _streakFlashController),
                  _buildNeonBadge(Icons.ac_unit, "$streakFreezes", Colors.cyanAccent, streakFreezes * 10, _freezeFlashController),
                  _buildNeonBadge(Icons.diamond, "$tayfPoints", Colors.lightBlueAccent, tayfPoints, _tpFlashController),
                ],
              ),
              const SizedBox(height: 12),
              if (selectedLibrary != 'Tekrarlanması Gerekenler') 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("İlerleme:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$learnedLibWords / $totalLibWords Öğrenildi", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent), minHeight: 4),
                      )
                    ]
                  )
                )
            ]
          )
        ),
      ),
      drawer: buildDrawer(), // ÇÖZÜM: Parçalanmış HomeDrawer modülünden çağrılır
      body: _isLowPowerMode
        ? Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: mainContent,
          )
        : AnimatedBuilder(
            animation: _auroraController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.01)], 
                    begin: Alignment(-1.0 + (_auroraController.value * 2), -1.0), 
                    end: Alignment(1.0 - (_auroraController.value * 2), 1.0)
                  )
                ),
                child: child,
              );
            },
            child: mainContent,
          ),
    );
  }

  Widget _buildMainContent(WordModel? currentWord, bool isSrsMode, bool isFlipped, List<WordModel> deck, int totalLibWords, int learnedLibWords, double progress, double bottomHeight) {
    return currentWord == null 
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity((0.3 * _glowAnimation.value).clamp(0.0, 1.0)), 
                            blurRadius: 30 * _glowAnimation.value, 
                            spreadRadius: 10 * _glowAnimation.value
                          )
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amberAccent.withOpacity(0.3), size: 100 * _glowAnimation.value),
                              const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 70),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("Mükemmel İş Çıkardın!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          const Text("Bu filtredeki tüm kelimelerle çalıştın.\nGünün hedefini başarıyla tamamladın! 🎉", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        )
      : SafeArea(
          bottom: false, 
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        if (isSrsMode)
                          Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.redAccent.shade100.withOpacity(0.2), Colors.orangeAccent.shade100.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 8), Text("SRS Tekrar Zamanı!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))])),
                        const Spacer(),
                        Center(
                          child: Dismissible(
                            key: ValueKey('${currentWord.word}_${DateTime.now()}'), 
                            direction: isFlipped ? DismissDirection.horizontal : DismissDirection.none,
                            background: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.green.withOpacity(0.8),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle, color: Colors.white, size: 50), Text("BİLİYORUM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                                ),
                              ),
                            ),
                            secondaryBackground: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.repeat, color: Colors.white, size: 50), Text("TEKRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                                ),
                              ),
                            ),
                            onDismissed: (direction) { if (direction == DismissDirection.startToEnd) markAsLearned(currentWord); else if (direction == DismissDirection.endToStart) markAsToRepeat(currentWord); },
                            child: GestureDetector(
                              onTap: () => flipCard(currentWord), 
                              child: AnimatedBuilder(
                                animation: _flipAnimation,
                                builder: (context, child) {
                                  final angle = _flipAnimation.value * pi;
                                  // ÇÖZÜM: Yüzlerce satırlık kart kodu parçalandı ve tek satıra indirgendi
                                  return Transform(
                                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle), 
                                    alignment: Alignment.center, 
                                    child: angle < (pi / 2) 
                                      ? PremiumWordCard(word: currentWord, isFront: true, glowAnimation: _glowAnimation, onSpeak: () => speakWord(currentWord, isMeaning: false), onEdit: () => openEditScreen(currentWord)) 
                                      : Transform(
                                          transform: Matrix4.identity()..rotateX(pi), 
                                          alignment: Alignment.center, 
                                          child: PremiumWordCard(word: currentWord, isFront: false, glowAnimation: _glowAnimation, onSpeak: () => speakWord(currentWord, isMeaning: true), onEdit: () => openEditScreen(currentWord))
                                        )
                                  );
                                }
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (isFlipped) 
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]),
                                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent, 
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white, 
                                        padding: const EdgeInsets.symmetric(vertical: 14), 
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                      ), 
                                      icon: const Icon(Icons.repeat), 
                                      label: const Text("Tekrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                                      onPressed: () => markAsToRepeat(currentWord)
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _warningPulseController,
                                      builder: (context, child) {
                                        return GestureDetector(
                                          onTap: () => moveToReview(currentWord),
                                          child: Container(
                                            width: 55, height: 55,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                              border: Border.all(color: Colors.redAccent, width: 3.5),
                                              boxShadow: [
                                                BoxShadow(color: Colors.yellowAccent.withOpacity(0.7 * _warningPulseController.value), blurRadius: 15, spreadRadius: 3)
                                              ]
                                            ),
                                            child: const Center(
                                              child: Text(
                                                "!", 
                                                style: TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 10)])
                                              )
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => moveToBlacklist(currentWord),
                                      child: Container(
                                        width: 45, height: 45,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                          border: Border.all(color: Colors.yellowAccent.shade700, width: 2),
                                          boxShadow: [
                                            BoxShadow(color: Colors.yellowAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                                          ]
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/acd21dcc2efa6d403b570d2bcaa10ef5.webp', // ÇÖZÜM: Image Optimization WebP
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.coronavirus, color: Colors.yellowAccent, size: 28),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(colors: [Colors.green.shade400, Colors.teal]),
                                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent, 
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white, 
                                        padding: const EdgeInsets.symmetric(vertical: 14), 
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                      ), 
                                      icon: const Icon(Icons.check), 
                                      label: const Text("Biliyorum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                                      onPressed: () => markAsLearned(currentWord)
                                    ),
                                  ),
                                )
                              ]
                            ),
                          ),
                        const Spacer(),
                        
                        ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.only(top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
                              width: double.infinity,
                              color: Theme.of(context).primaryColor.withOpacity(0.05),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("V2.4.${_HomeScreenState.buildNo}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                      const SizedBox(width: 16),
                                      Text("Tayfun YAMAK©", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("✨ Tayfun (Eldora) ✨", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor.withOpacity(0.5))),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
  }
}
