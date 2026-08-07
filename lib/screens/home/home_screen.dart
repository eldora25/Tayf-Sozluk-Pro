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
import '../../logger_screen.dart';
import '../../match_game_screen.dart';
import '../../pronunciation_screen.dart';
import '../../info_screen.dart'; 
import '../../wordnet_search_screen.dart'; 
import '../../demo_screen.dart'; 
import '../../report_screen.dart'; 

part 'home_logic.dart';
part 'home_cloud.dart';

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

  Widget _buildCrown(int level, bool isMitosis) {
    if (level == 0) return const SizedBox.shrink();
    List<Widget> pieces = [];

    if (level == 1) {
      pieces = [const Icon(Icons.change_history, size: 16, color: Color(0xFFFFEA00))]; 
    } else if (level == 2) {
      pieces = [
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
        const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFFD500F9)),
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
      ];
    } else if (level == 3) {
      pieces = [
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.workspace_premium, size: 24, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
      ];
    } else if (level == 4) {
      pieces = [
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.military_tech, size: 28, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
      ];
    } else if (level == 5) {
      pieces = [
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.diamond, size: 32, color: Colors.white),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
      ];
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: pieces);
  }

  BoxDecoration _getPremiumCardDecoration(BuildContext context, bool isDark, {bool isMitosis = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
            ? [
                isMitosis ? Colors.purpleAccent.shade400.withOpacity(0.15) : Theme.of(context).cardColor, 
                Theme.of(context).cardColor.withOpacity(0.8)
              ]
            : [
                isMitosis ? Colors.purpleAccent.shade100.withOpacity(0.1) : Colors.white, 
                Theme.of(context).scaffoldBackgroundColor
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))
      ]
    );
  }

  Color _getTextColor(BuildContext context, bool isDark, bool isMitosis) {
    if (isMitosis) {
      return isDark ? Colors.white : Colors.purple.shade900;
    }
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Widget _buildTopBadge(int level, bool isMitosis, bool isWordNet, String pos) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(vertical: 8), 
      decoration: BoxDecoration(
        color: isWordNet ? Colors.indigo.withOpacity(0.15) : (isMitosis ? Colors.purpleAccent.withOpacity(0.15) : (level > 0 ? distinctColors[level - 1].withOpacity(0.15) : Colors.blueGrey.withOpacity(0.15))), 
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: isWordNet ? Colors.indigo.withOpacity(0.5) : (isMitosis ? Colors.purpleAccent.withOpacity(0.5) : (level > 0 ? distinctColors[level - 1].withOpacity(0.5) : Colors.blueGrey.withOpacity(0.5))), width: 2))
      ), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (level > 0 && !isWordNet) _buildCrown(level, isMitosis), 
          if (level > 0 && !isWordNet) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWordNet) ...[
                const Icon(Icons.language, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Text("WORDNET SÖZLÜK ${pos.isNotEmpty ? '[${pos.toUpperCase()}]' : ''}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else if (isMitosis) ...[
                const Icon(Icons.biotech, size: 16, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(level > 0 ? "MİTOZ (SAF KART) • SRS: $level/5" : "YENİ MİTOZ (SAF KART)", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else ...[
                Icon(Icons.menu_book, size: 16, color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey),
                const SizedBox(width: 8),
                Text(level > 0 ? "STANDART KART • SRS: $level/5" : "YENİ STANDART KART", style: TextStyle(color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ]
            ],
          ),
        ],
      )
    );
  }

  Widget _buildCardFront(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 
    bool isWordNet = word.libraryName == 'WordNet Veritabanı';

    String displayWord = word.word;
    if (RegExp(r'^\d{8}-').hasMatch(displayWord) || displayWord.contains('[ID:')) {
        displayWord = word.synonyms.isNotEmpty ? word.synonyms.first : "WordNet Terimi";
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320, 
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                _buildTopBadge(level, isMitosis, isWordNet, word.pos),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80, top: 40, left: 16, right: 16),
                        child: Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(displayWord, textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _getTextColor(context, isDark, isMitosis)))))), 
                      ),
                      Positioned(right: 5, top: 5, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => speakWord(word, isMeaning: false))), 
                      Positioned(left: 5, top: 5, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => openEditScreen(word))),
                      
                      if (isMitosis && !isWordNet)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: -0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white30, width: 1), boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)), BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0))]),
                                    child: Transform.rotate(angle: 0.5, child: const Text("\u{1F9EC}", style: TextStyle(fontSize: 16, shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15), Shadow(color: Colors.purpleAccent, blurRadius: 15)]))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text("DNA-" + word.id.toString().padLeft(6, '0'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;
          if (level > 0 && !isWordNet) {
            for (int i = 0; i < level; i++) {
              double thickness = 2.0 + (i * 1.5); 
              current = Container(
                padding: EdgeInsets.all(thickness), 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 + ((i + 1) * thickness)),
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.0 + (i * 0.5)), 
                  gradient: LinearGradient(colors: [distinctColors[i].withOpacity(0.9), distinctColors[i]], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: (i == level - 1) ? [BoxShadow(color: distinctColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)), blurRadius: 25 * _glowAnimation.value, spreadRadius: 6 * _glowAnimation.value)] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(3),
               decoration: BoxDecoration(
                 color: isWordNet ? Colors.indigo : (isMitosis ? Colors.purpleAccent : Theme.of(context).primaryColor),
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isWordNet ? Colors.indigo.withOpacity(0.4) : (isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.4)), blurRadius: 15, offset: const Offset(0, 5))]
               ),
               child: current,
             );
          }
          return current;
        }
      ),
    );
  }

  Widget _buildCardBack(WordModel word) {
    int level = word.srsLevel.clamp(0, 5);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 
    bool isWordNet = word.libraryName == 'WordNet Veritabanı';

    String displayWord = word.word;
    if (RegExp(r'^\d{8}-').hasMatch(displayWord) || displayWord.contains('[ID:')) {
        displayWord = word.synonyms.isNotEmpty ? word.synonyms.first : "WordNet Terimi";
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320,
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis: isMitosis), 
            child: Column(
              children: [
                _buildTopBadge(level, isMitosis, isWordNet, word.pos),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0, left: 20, right: 20, bottom: 100), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Text(displayWord, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _getTextColor(context, isDark, isMitosis)))), 
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: _getTextColor(context, isDark, isMitosis).withOpacity(0.3))), 
                              
                              if (isWordNet) ...[
                                Row(children: [const Icon(Icons.menu_book, size: 14, color: Colors.indigo), const SizedBox(width: 6), Text("Definition:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo.shade300))]),
                                ...word.meanings.map((m) => Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 6), child: Text(m, style: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                
                                if (word.synonyms.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.link, size: 14, color: Colors.teal), const SizedBox(width: 6), Text("Synonyms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade300))]),
                                  Padding(padding: const EdgeInsets.only(top: 4.0, left: 6), child: Wrap(spacing: 6, runSpacing: 6, children: word.synonyms.take(6).map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.withOpacity(0.3))), child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)))).toList())),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (word.antonyms.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.link_off, size: 14, color: Colors.redAccent), const SizedBox(width: 6), Text("Antonyms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent.shade200))]),
                                  Padding(padding: const EdgeInsets.only(top: 4.0, left: 6), child: Wrap(spacing: 6, runSpacing: 6, children: word.antonyms.take(6).map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: Text(a, style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold)))).toList())),
                                  const SizedBox(height: 8),
                                ],

                                if (word.examples.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.format_quote, size: 14, color: Colors.orange), const SizedBox(width: 6), Text("Examples:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orange.shade300))]),
                                  ...word.examples.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                                    child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)),
                                  )),
                                ]
                              ] else ...[
                                ...word.meanings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text("• " + m, style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                if (word.examples.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text("Örnekler:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isMitosis ? Colors.pinkAccent : Theme.of(context).colorScheme.secondary)),
                                  const SizedBox(height: 6),
                                  ...word.examples.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text("» " + e, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4, color: _getTextColor(context, isDark, isMitosis))))),
                                ]
                              ]
                            ]
                          )
                        )
                      ), 
                      Positioned(right: 5, top: 0, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: () => speakWord(word, isMeaning: true))), 
                      Positioned(left: 5, top: 0, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: () => openEditScreen(word))),
                      
                      if (isMitosis && !isWordNet)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: -0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white30, width: 1), boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(-3, 0)), BoxShadow(color: Colors.purpleAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2, offset: const Offset(3, 0))]),
                                    child: Transform.rotate(angle: 0.5, child: const Text("\u{1F9EC}", style: TextStyle(fontSize: 16, shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15), Shadow(color: Colors.purpleAccent, blurRadius: 15)]))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text("DNA-" + word.id.toString().padLeft(6, '0'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;
          if (level > 0 && !isWordNet) {
            for (int i = 0; i < level; i++) {
              double thickness = 2.0 + (i * 1.5);
              current = Container(
                padding: EdgeInsets.all(thickness),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 + ((i + 1) * thickness)),
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.0 + (i * 0.5)),
                  gradient: LinearGradient(colors: [distinctColors[i].withOpacity(0.9), distinctColors[i]], begin: Alignment.bottomRight, end: Alignment.topLeft),
                  boxShadow: (i == level - 1) ? [BoxShadow(color: distinctColors[i].withOpacity((0.6 * _glowAnimation.value).clamp(0.0, 1.0)), blurRadius: 25 * _glowAnimation.value, spreadRadius: 6 * _glowAnimation.value)] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(3),
               decoration: BoxDecoration(
                 color: isWordNet ? Colors.indigo : (isMitosis ? Colors.purpleAccent : Colors.green), 
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isWordNet ? Colors.indigo.withOpacity(0.4) : (isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Colors.green.withOpacity(0.4)), blurRadius: 15, offset: const Offset(0, 5))]
               ),
               child: current,
             );
          }
          return current;
        }
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      elevation: 10,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), 
      child: RepaintBoundary( 
        child: _isLowPowerMode 
          ? Container(color: Theme.of(context).scaffoldBackgroundColor)
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
              child: SafeArea(
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
                                    colors: [
                                      Theme.of(context).primaryColor, 
                                      Theme.of(context).colorScheme.secondary,
                                      Colors.indigoAccent
                                    ],
                                    stops: [
                                      0.0,
                                      _bgGradientController.value,
                                      1.0
                                    ],
                                    begin: Alignment.topLeft, 
                                    end: Alignment.bottomRight
                                  )
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                        image: const DecorationImage(image: AssetImage('assets/ic_launcher.png'), fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text("Lexis Eldora", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    Text("Build v2.4.$buildNo", style: const TextStyle(color: Colors.white70, fontSize: 13))
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
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15)))
                                ),
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
                          
                          ListTile(
                            leading: const Icon(Icons.travel_explore, color: Colors.indigoAccent), 
                            title: const Text("WordNet Browser", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)), 
                            subtitle: const Text("Gelişmiş İng-İng Sözlük Arama"), 
                            onTap: () { 
                              HapticFeedback.lightImpact(); 
                              Navigator.pop(context); 
                              Navigator.push(context, MaterialPageRoute(builder: (context) => WordNetSearchScreen(words: [...allWords, ...learnedWords, ...learningWords, ...toRepeatWords, ...toSRSRepeatWords])));
                            }
                          ),
                          
                          ListTile(leading: const Icon(Icons.add_box), title: const Text("Kelime Ekle"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddWordScreen(availableLibraries: safeLibraries(), onSave: (w) { setState(() => allWords.add(w)); buildActiveDeck(); savePreferencesOnly(); }))); }),
                          ListTile(leading: const Icon(Icons.list_alt), title: const Text("Kelime Listesi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(words: _activeDeck, onDelete: (w) { setState(() { allWords.remove(w); toRepeatWords.remove(w); toSRSRepeatWords.remove(w); _activeDeck.remove(w); }); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onLearned: markAsLearned))); }),
                          
                          ListTile(
                            leading: const Icon(Icons.settings), 
                            title: const Text("Ayarlar, Temalar, Seçimler"), 
                            onTap: () { 
                              HapticFeedback.lightImpact();
                              Navigator.pop(context); 
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                                currentGoal: dailyGoal, currentThreshold: quizThreshold, currentQuestionCount: quizQuestionCount, currentThemeIndex: widget.themeIndex, selectedLibrary: selectedLibrary, selectedLevel: selectedLevel, isGlobalSrsEnabled: _globalSrs, isLowPowerMode: _isLowPowerMode, availableLibraries: safeLibraries(), 
                                onSaveSettings: (nG, nT, nQC, nTI, nL, nLv, glSrs, lowPow) async { 
                                  // YENİ: Anında Yükleme Ekranı Tetikleyicisi
                                  setState(() { 
                                    dailyGoal = nG; quizThreshold = nT; quizQuestionCount = nQC; 
                                    widget.onThemeChanged(nTI); 
                                    selectedLibrary = nL; selectedLevel = nLv; 
                                    _globalSrs = glSrs; _isLowPowerMode = lowPow; 
                                    
                                    _isAppLoading = true;
                                    if (selectedLibrary == 'WordNet Veritabanı') {
                                        _loadingText = "Devasa WordNet veritabanından en iyi kelimeler hazırlanıyor, lütfen sabırlı olun...";
                                    } else {
                                        _loadingText = "Kütüphane değiştiriliyor...";
                                    }
                                  }); 

                                  // YENİ: UI'ın yükleme ekranını gösterebilmesi için frame atlamasına izin ver
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  
                                  await buildActiveDeck(); 
                                  await savePreferencesOnly(); // Ensure it saves completely
                                  
                                  if (mounted) {
                                    setState(() {
                                      _isAppLoading = false; // Yükleme bitti
                                    });
                                    showCenteredDialog(
                                      title: "Harika!", 
                                      message: "Ayarlar başarıyla kalıcı olarak kaydedildi.", 
                                      icon: Icons.verified_user, 
                                      color: Colors.green
                                    );
                                  }
                                }, 
                                onAddPackage: loadPackageFromAssets
                              ))); 
                            }
                          ),
                          
                          const Divider(),
                          ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: const Text("Öğrenilen Kelimeler"), subtitle: Text("${learnedWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Öğrenilen Kelimeler", words: learnedWords, onDelete: (w) { setState(() => learnedWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => learnedWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                          ListTile(leading: const Icon(Icons.repeat, color: Colors.orange), title: const Text("Tekrar Listesi (Normal)"), subtitle: Text("${toRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Tekrar Listesi", words: toRepeatWords, onDelete: (w) { setState(() => toRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => toRepeatWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                          ListTile(leading: const Icon(Icons.schedule, color: Colors.blue), title: const Text("SRS Tekrar Listesi"), subtitle: Text("${toSRSRepeatWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "SRS Tekrar Listesi", words: toSRSRepeatWords, showSrsLevel: true, onDelete: (w) { setState(() => toSRSRepeatWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => toSRSRepeatWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                          ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text("Yanlış Kelimeler"), subtitle: Text("${wrongWords.length} kelime"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Yanlış Kelimeler", words: wrongWords, showWrongCount: true, onDelete: (w) { setState(() => wrongWords.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => wrongWords.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); }),
                          
                          ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber), 
                            title: const Text("Karantina & Hata Havuzu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)), 
                            subtitle: Text("${reviewWordsPool.length} kelime (İncelenecek)"), 
                            onTap: () { 
                              HapticFeedback.lightImpact(); 
                              Navigator.pop(context); 
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(title: "Karantina & Hata Havuzu", words: reviewWordsPool, onDelete: (w) { setState(() => reviewWordsPool.remove(w)); isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); savePreferencesOnly(); }, onClearAll: () { setState(() => reviewWordsPool.clear()); savePreferencesOnly(); }, onEdit: openEditScreen))).then((_) => setState((){})); 
                            }
                          ),

                          ListTile(
                            leading: const Icon(Icons.dangerous, color: Colors.redAccent), 
                            title: const Text("Bir daha görmek istemiyorum", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)), 
                            subtitle: const Text("Kara liste (İzole edilmiş kelimeler)"), 
                            onTap: () async { 
                              HapticFeedback.lightImpact(); 
                              Navigator.pop(context); 
                              
                              List<WordModel> blacklistWords = await isar.wordModels.filter().listTypeEqualTo('blacklist').findAll();

                              if (mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageListScreen(
                                  title: "Kara Liste", 
                                  words: blacklistWords, 
                                  availableLibraries: safeLibraries(),
                                  onDelete: (w) { 
                                    setState(() { }); 
                                    isar.writeTxnSync(() { isar.wordModels.deleteSync(w.id); }); 
                                    savePreferencesOnly(); 
                                  }, 
                                  onClearAll: () { 
                                    setState(() { }); 
                                    savePreferencesOnly(); 
                                  }, 
                                  onEdit: openEditScreen
                                ))).then((_) { 
                                   setState((){}); 
                                   loadData(); 
                                });
                              }
                            }
                          ),

                          const Divider(),
                          ListTile(leading: const Icon(Icons.my_library_books), title: const Text("Kütüphane Yönetimi"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryManagerScreen(allWords: allWords, learningWords: learningWords, learnedWords: learnedWords, toRepeatWords: [...toRepeatWords, ...toSRSRepeatWords], wrongWords: wrongWords, onRename: renameLibrary, onDelete: deleteLibrary, onExport: exportLibrary, onPointsEarned: (points) => recordActivity(points)))); }),
                          
                          ListTile(leading: const Icon(Icons.extension, color: Colors.purpleAccent), title: const Text("Eşleştirme Oyunu"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MatchGameScreen(words: _activeDeck, isWordNet: selectedLibrary == 'WordNet Veritabanı', onGameFinished: (points) { recordActivity(points); savePreferencesOnly(); }))); }),
                          ListTile(leading: const Icon(Icons.mic, color: Colors.teal), title: const Text("Telaffuz Sınavı"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => PronunciationScreen(words: _activeDeck, isWordNet: selectedLibrary == 'WordNet Veritabanı', onGameFinished: (points) { recordActivity(points); savePreferencesOnly(); }))); }),
                          
                          ListTile(leading: const Icon(Icons.quiz), title: const Text("Quiz Modu"), onTap: () async { 
                            HapticFeedback.lightImpact();
                            Navigator.pop(context); 
                            List<WordModel> fullPool = [];
                            if (selectedLibrary == 'WordNet Veritabanı') {
                              var wnList = allWords.where((w) => w.libraryName == 'WordNet Veritabanı').toList();
                              wnList.shuffle();
                              fullPool = wnList.take(200).toList();
                            } else {
                              fullPool = [...allWords, ...toRepeatWords, ...toSRSRepeatWords, ...learningWords, ...wrongWords].where((w) => selectedLibrary == 'Varsayılan' ? true : w.libraryName == selectedLibrary).toSet().toList();
                            }
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                              words: fullPool, threshold: quizThreshold, questionCount: quizQuestionCount, 
                              isWordNet: selectedLibrary == 'WordNet Veritabanı',
                              currentBestTime: bestQuizTime,
                              currentBestCorrect: bestQuizCorrect,
                              isLowPowerMode: _isLowPowerMode,
                              onWordMastered: (w) => markAsLearned(w, fromQuiz: true), 
                              onWrongWord: (w) => markAsToRepeat(w, fromQuiz: true), 
                              onQuizFinished: (t, a, w, tp, firstTryCorrect, isNewRecord) { 
                                setState(() { 
                                  totalCompletedQuizzes++; 
                                  totalQuizTimeSeconds += t; 
                                  totalQuizQuestions += a; 
                                  totalQuizWrong += w; 
                                  tayfPoints += tp; 
                                  completedQuizTimestamps.add(DateTime.now().millisecondsSinceEpoch.toString()); 
                                  
                                  if (isNewRecord) {
                                    bestQuizTime = t;
                                    bestQuizCorrect = firstTryCorrect;
                                    final now = DateTime.now();
                                    bestQuizDate = "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}";
                                  }
                                });
                                savePreferencesOnly(); 
                              }
                            )));
                            
                            // YENİ: Quiz dönüşünde loadData() yerine doğrudan UI güncellemesi yapılarak 
                            // Tayf Puanı ve istatistiklerin "Race Condition" nedeniyle ezilmesi engellendi
                            setState(() {}); 
                            await buildActiveDeck();
                          }),
                          
                          ListTile(leading: const Icon(Icons.analytics), title: const Text("İstatistikler & Rozetler"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(allWords: allWords, learningWords: learningWords, toRepeatWords: toRepeatWords, toSRSRepeatWords: toSRSRepeatWords, learnedWords: learnedWords, wrongWords: wrongWords, availableLibraries: safeLibraries(), totalCompletedQuizzes: totalCompletedQuizzes, totalQuizTimeSeconds: totalQuizTimeSeconds, totalQuizQuestions: totalQuizQuestions, totalQuizWrong: totalQuizWrong, learnedWordTimestamps: learnedWordTimestamps, completedQuizTimestamps: completedQuizTimestamps, viewedCardTimestamps: viewedCardTimestamps, wrongAnswerTimestamps: wrongAnswerTimestamps, firstUseTimestamp: firstUseTimestamp, bestStreak: bestStreak, tayfPoints: tayfPoints, bestQuizTime: bestQuizTime, bestQuizCorrect: bestQuizCorrect, bestQuizDate: bestQuizDate))); }), 
                          const Divider(),
                          ListTile(leading: const Icon(Icons.science, color: Colors.purple), title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)), subtitle: const Text("Görünüm ve fonksiyon testleri", style: TextStyle(fontSize: 12)), onTap: () async { 
                            HapticFeedback.lightImpact(); 
                            Navigator.pop(context); 
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const DemoScreen()));
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selectedLibrary', 'Tekrarlanması Gerekenler');
                            await prefs.setInt('currentCardIndex', 0);
                            setState(() { selectedLibrary = 'Tekrarlanması Gerekenler'; currentCardIndex = 0; isFlipped = false; });
                            loadData();
                          }),
                          ListTile(leading: const Icon(Icons.bug_report, color: Colors.orange), title: const Text("Hata Kayıtları (Log)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LoggerScreen())); }),
                          const Divider(),
                          ListTile(leading: const Icon(Icons.info_outline, color: Colors.indigo), title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen())); }),
                          ListTile(leading: const Icon(Icons.download), title: const Text("İçe Aktar (Ham Veri)"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); importFile(); }),
                          ListTile(leading: const Icon(Icons.share), title: const Text("Paylaş / Dışa Aktar"), onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); exportLibrary(selectedLibrary); }),
                          
                          ListTile(
                            leading: const Icon(Icons.cloud_upload, color: Colors.blueAccent), 
                            title: const Text("Buluta Yedekle", style: TextStyle(fontWeight: FontWeight.bold)), 
                            subtitle: const Text("SRS, TP, Rozetler ve özel kartları dışa aktar", style: TextStyle(fontSize: 12)), 
                            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); cloudBackupProgress(); }
                          ),
                          ListTile(
                            leading: const Icon(Icons.cloud_download, color: Colors.green), 
                            title: const Text("Buluttan Geri Yükle", style: TextStyle(fontWeight: FontWeight.bold)), 
                            subtitle: const Text("Buluttaki yedeği cihazınıza çekin", style: TextStyle(fontSize: 12)), 
                            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); cloudRestoreProgress(); }
                          ),
                          
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
                                  Text("V2.4.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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
              ),
            ),
      ),
    );
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

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: false,
        backgroundColor: Colors.transparent, 
        elevation: 0,
        flexibleSpace: _isLowPowerMode 
          ? Container(color: Theme.of(context).scaffoldBackgroundColor)
          : RepaintBoundary( 
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
      drawer: _buildDrawer(),
      body: _isLowPowerMode 
        ? Container(
            color: Theme.of(context).scaffoldBackgroundColor, 
            child: _buildMainContent(currentWord, isSrsMode, isFlipped), 
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
            child: _buildMainContent(currentWord, isSrsMode, isFlipped),
          ),
    );
  }
  
  Widget _buildMainContent(WordModel? currentWord, bool isSrsMode, bool isFlipped) {
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
                                   return Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle), alignment: Alignment.center, child: angle < (pi / 2) ? _buildCardFront(currentWord) : Transform(transform: Matrix4.identity()..rotateX(pi), alignment: Alignment.center, child: _buildCardBack(currentWord)));
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
                                     // YENİ: PREMIUM BİOHAZARD İKONU (WebP)
                                     GestureDetector(
                                       onTap: () => moveToBlacklist(currentWord),
                                       child: Container(
                                         width: 50, height: 50,
                                         decoration: BoxDecoration(
                                           shape: BoxShape.circle,
                                           color: Colors.yellowAccent.shade700,
                                           border: Border.all(color: Colors.black, width: 2),
                                           boxShadow: [
                                             BoxShadow(color: Colors.yellowAccent.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)
                                           ]
                                         ),
                                         child: ClipOval(
                                           child: Image.asset(
                                             'assets/biohazardicon.webp', // YENİ WEBP FORMATI
                                             fit: BoxFit.cover,
                                             errorBuilder: (context, error, stackTrace) => const Icon(Icons.coronavirus, color: Colors.black, size: 28),
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
                                       Text("V2.4.$buildNo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.6))),
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
