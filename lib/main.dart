import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_sync_service.dart';

import 'models.dart';
import 'wordnet.dart'; 
import 'quiz_screen.dart';
import 'add_word_screen.dart';
import 'word_list_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'edit_word_screen.dart';
import 'library_manager_screen.dart';
import 'manage_list_screen.dart';
import 'logger_screen.dart';
import 'notification_service.dart';
import 'match_game_screen.dart';
import 'pronunciation_screen.dart';
import 'info_screen.dart'; 
import 'wordnet_search_screen.dart'; 
import 'demo_screen.dart'; 
import 'report_screen.dart'; 

late Isar isar;
final FlutterTts globalTts = FlutterTts();

String getSmartSourceLanguage(String libraryName, String wordText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'en-US';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'tr-TR';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(wordText)) return 'tr-TR';
  return 'en-US'; 
}

String getSmartTargetLanguage(String libraryName, String meaningText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'tr-TR';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'en-US';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(meaningText)) return 'tr-TR';
  return 'tr-TR'; 
}

int getNextReviewOffset(int level) {
  const int oneDay = 24 * 60 * 60 * 1000;
  switch (level) {
    case 1: return 1 * oneDay;
    case 2: return 2 * oneDay;
    case 3: return 4 * oneDay; 
    case 4: return 9 * oneDay;
    case 5: return 14 * oneDay;
    default: return 0;
  }
}

List<String> cleanAndSplit(String rawText) {
  List<String> results = [];
  String text = rawText.replaceAll('-III', '').replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').replaceAll('\"', '');
  var parts = text.split(RegExp(r'\|\|\||;|\n|,|\.\s+'));
  for (var p in parts) {
    String clean = p.trim();
    clean = clean.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ(]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length > 1 && !['n', 'v', 'adj', 'adv', 'prep', 'conj', 'pron'].contains(clean.toLowerCase())) {
      results.add(clean);
    }
  }
  return results.toSet().toList(); 
}

List<List<String>> parseCsvMultiline(String text) {
  List<List<String>> rows = [];
  List<String> currentRow = [];
  StringBuffer currentCell = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < text.length; i++) {
    String c = text[i];
    if (c == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') { currentCell.write('"'); i++; } 
      else { inQuotes = !inQuotes; }
    } else if (c == ',' && !inQuotes) {
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
    } else if ((c == '\n' || c == '\r') && !inQuotes) {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++; 
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
      if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
      currentRow = [];
    } else { currentCell.write(c); }
  }
  if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(currentCell.toString().trim());
    if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
  }
  return rows;
}

List<String> parseLibraryDataInBackground(Map<String, dynamic> params) {
  String content = params['content'];
  String extension = params['extension'];
  String customLibraryName = params['libraryName'];
  String originalFileName = (params['originalFileName'] ?? '').toLowerCase();
  List<String> parsedList = [];

  if (content.startsWith('\uFEFF')) content = content.substring(1);

  try {
    if (extension == 'json') {
      var decoded = json.decode(content);
      List list = decoded is Map ? (decoded['words'] ?? decoded) : decoded;
      for (var item in list) {
        if (item is Map) {
          bool isWordNet = item.containsKey('pos') || item.containsKey('antonyms') || item.containsKey('lemmas') || item.containsKey('synonyms');
          
          if (isWordNet) {
             String wordStr = item['word']?.toString().trim() ?? '';
             String posStr = item['pos']?.toString().trim() ?? '';
             String defStr = item['definition']?.toString().trim() ?? '';
             
             List<String> examplesList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             
             List<String> synonymsList = [];
             if (item['synonyms'] is List) synonymsList.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) synonymsList.addAll((item['lemmas'] as List).map((e) => e.toString()));
             synonymsList = synonymsList.toSet().toList(); 
             
             List<String> antonymsList = item['antonyms'] is List ? (item['antonyms'] as List).map((e) => e.toString()).toList() : [];

             if (wordStr.isEmpty || RegExp(r'^\d{8}-').hasMatch(wordStr) || wordStr.contains('[ID:')) {
                 if (synonymsList.isNotEmpty) {
                     wordStr = synonymsList.first;
                 } else {
                     wordStr = "WordNet Term";
                 }
             }

             if (wordStr.isNotEmpty && defStr.isNotEmpty) {
                parsedList.add(json.encode({
                  'word': wordStr,
                  'meanings': [defStr], 
                  'examples': examplesList,
                  'level': 'Genel', 
                  'libraryName': customLibraryName,
                  'correctCount': 0,
                  'wrongCount': 0,
                  'listType': 'all',
                  'srsLevel': 0,
                  'nextReviewDate': 0,
                  'pos': posStr,
                  'synonyms': synonymsList,
                  'antonyms': antonymsList
                }));
             }
          } else {
             List<String> subWords = [];
             String w = item['word']?.toString().trim() ?? '';
             if (!RegExp(r'^\d{8}-').hasMatch(w) && w.isNotEmpty) subWords.add(w);
             if (item['synonyms'] is List) subWords.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) subWords.addAll((item['lemmas'] as List).map((e) => e.toString()));
             String def = item['definition']?.toString() ?? '';
             List<String> mList = item['meanings'] is List ? (item['meanings'] as List).map((e) => e.toString()).toList() : (def.isNotEmpty ? [def] : []);
             List<String> eList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             List<String> cleanM = cleanAndSplit(mList.join('|||'));
             List<String> cleanE = cleanAndSplit(eList.join('|||'));

             for (String sw in subWords) {
               sw = sw.replaceAll('_', ' ').trim(); 
               if (sw.length > 1 && cleanM.isNotEmpty) {
                 parsedList.add(json.encode({
                    'word': sw, 
                    'meanings': cleanM, 
                    'examples': cleanE, 
                    'level': item['level']?.toString() ?? 'Genel', 
                    'libraryName': customLibraryName, 
                    'correctCount': 0, 
                    'wrongCount': 0, 
                    'listType': 'all', 
                    'srsLevel': 0, 
                    'nextReviewDate': 0,
                    'pos': '',
                    'synonyms': [],
                    'antonyms': []
                 }));
               }
             }
          }
        }
      }
      return parsedList;
    }

    if (originalFileName.contains('tayf') && extension == 'txt') {
      List<String> lines = const LineSplitter().convert(content);
      for (String line in lines) {
        int colonIdx = line.indexOf(':');
        if (colonIdx != -1) {
          List<String> subWords = line.substring(0, colonIdx).split(RegExp(r'[,/]'));
          List<String> meanings = cleanAndSplit(line.substring(colonIdx + 1));
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            if (w.length > 1 && meanings.isNotEmpty) {
              parsedList.add(json.encode({'word': w, 'meanings': meanings, 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
      return parsedList;
    }

    List<List<String>> rows = parseCsvMultiline(content);
    for (List<String> row in rows) {
      if (row.length >= 2) {
        List<String> subWords = row[0].split(RegExp(r'[,/|]'));
        List<String> mList = cleanAndSplit(row[1]);
        List<String> eList = row.length > 2 ? cleanAndSplit(row[2]) : [];
        String level = row.length > 3 ? row[3].replaceAll('"', '').trim() : 'Genel';
        if (level.isEmpty) level = 'Genel';

        if (mList.isNotEmpty) {
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            w = w.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
            if (w.length > 1) {
              parsedList.add(json.encode({'word': w, 'meanings': mList, 'examples': eList, 'level': level, 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
    }
  } catch (e) {
    parsedList.add(json.encode({'error': "Dosya Okuma Hatası:\n$e"}));
  }
  return parsedList;
}

class Premium120FPSPageTransitionsBuilder extends PageTransitionsBuilder {
  const Premium120FPSPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.fastLinearToSlowEaseIn),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }
}

class SlideGradientTransform extends GradientTransform {
  final double percent;
  const SlideGradientTransform({required this.percent});
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}

class PremiumShimmerLoading extends StatefulWidget {
  final String loadingText;
  const PremiumShimmerLoading({super.key, required this.loadingText});

  @override
  State<PremiumShimmerLoading> createState() => _PremiumShimmerLoadingState();
}

class _PremiumShimmerLoadingState extends State<PremiumShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color baseColor = isDark ? Colors.white24 : Colors.black12;
    Color highlightColor = isDark ? Colors.white54 : Colors.black26;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [baseColor, highlightColor, baseColor],
                        stops: const [0.1, 0.5, 0.9],
                        begin: const Alignment(-1.0, -0.3),
                        end: const Alignment(1.0, 0.3),
                        transform: SlideGradientTransform(percent: _shimmerController.value),
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: _buildSkeletonLayout(context, baseColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Theme.of(context).primaryColor, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    widget.loadingText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLayout(BuildContext context, Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 24, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12)))),
              const SizedBox(height: 8),
              Container(width: 100, height: 16, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8)))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => Container(width: 80, height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))))),
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 290,
            height: 380,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
                const Spacer(),
                Container(width: 180, height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20)))),
                const SizedBox(height: 20),
                Container(width: 220, height: 20, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10)))),
                const SizedBox(height: 10),
                Container(width: 160, height: 20, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10)))),
                const Spacer(),
              ],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: Container(height: 50, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(25))))),
              const SizedBox(width: 12),
              Container(width: 55, height: 55, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 50, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(25))))),
            ],
          ),
        )
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([WordModelSchema], directory: dir.path);
  runApp(const TayfSozlukApp());
}

class TayfSozlukApp extends StatefulWidget {
  const TayfSozlukApp({super.key});
  @override
  State<TayfSozlukApp> createState() => _TayfSozlukAppState();
}

class _TayfSozlukAppState extends State<TayfSozlukApp> {
  int themeIndex = 0;
  @override
  void initState() { super.initState(); _loadTheme(); }
  void _loadTheme() async { final prefs = await SharedPreferences.getInstance(); setState(() => themeIndex = prefs.getInt('themeIndex') ?? 0); }
  
  void _toggleTheme(int value) async { 
    final prefs = await SharedPreferences.getInstance(); 
    prefs.setInt('themeIndex', value);
    setState(() => themeIndex = value); 
  }

  ThemeData _getTheme() {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();
    
    final PageTransitionsTheme smoothTransitions = const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: Premium120FPSPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), 
      },
    );

    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, scaffoldBackgroundColor: const Color(0xFFF8F9FA), colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[600], scaffoldBackgroundColor: const Color(0xFFE3F2FD), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: AppBarTheme(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[600], scaffoldBackgroundColor: const Color(0xFFE0F2F1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: AppBarTheme(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 4: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: const Color(0xFFEDE7F6), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 5: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: const Color(0xFFFBE9E7), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 6: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.pink, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: const Color(0xFFFCE4EC), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.pink), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 7: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.cyan, primaryColor: Colors.cyan[700], scaffoldBackgroundColor: const Color(0xFFE0F7FA), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.cyan, secondary: Colors.cyanAccent), appBarTheme: AppBarTheme(backgroundColor: Colors.cyan[700], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 8: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF2C3E50), scaffoldBackgroundColor: const Color(0xFF1E272E), colorScheme: const ColorScheme.dark(primary: Color(0xFF2C3E50), secondary: Color(0xFF546E7A)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 9: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF607D8B), scaffoldBackgroundColor: const Color(0xFFECEFF1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF607D8B), secondary: Color(0xFF90A4AE)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF607D8B), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 10: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF8D6E63), scaffoldBackgroundColor: const Color(0xFFF4ECD8), cardColor: const Color(0xFFFDFBF7), colorScheme: const ColorScheme.light(primary: Color(0xFF8D6E63), secondary: Color(0xFFA1887F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF8D6E63), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 11: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF5C6BC0), scaffoldBackgroundColor: const Color(0xFFE8F4F8), cardColor: const Color(0xFFF5FAFD), colorScheme: const ColorScheme.light(primary: Color(0xFF5C6BC0), secondary: Color(0xFF7986CB)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF5C6BC0), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 12: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF9E9D24), scaffoldBackgroundColor: const Color(0xFFF5F5DC), cardColor: const Color(0xFFFCFDF2), colorScheme: const ColorScheme.light(primary: Color(0xFF9E9D24), secondary: Color(0xFFAED581)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF9E9D24), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 13: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF4E342E), scaffoldBackgroundColor: const Color(0xFF3E2723), colorScheme: const ColorScheme.dark(primary: Color(0xFF4E342E), secondary: Color(0xFF8D6E63)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 14: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF263238), scaffoldBackgroundColor: const Color(0xFF101416), colorScheme: const ColorScheme.dark(primary: Color(0xFF263238), secondary: Color(0xFF455A64)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 15: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF33691E), scaffoldBackgroundColor: const Color(0xFFF1F8E9), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF33691E), secondary: Color(0xFF558B2F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF33691E), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), pageTransitionsTheme: smoothTransitions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexis Eldora',
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      themeAnimationDuration: const Duration(milliseconds: 300), 
      home: HomeScreen(themeIndex: themeIndex, onThemeChanged: _toggleTheme),
    );
  }
}

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

    NotificationService.requestPermission();
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
