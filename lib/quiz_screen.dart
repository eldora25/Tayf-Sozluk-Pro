import 'dart:math';
import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:lottie/lottie.dart'; 
import 'package:isar/isar.dart'; 
import 'models.dart';
import 'main.dart'; 

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int threshold;
  final int questionCount;
  final Function(WordModel) onWordMastered;
  final Function(WordModel) onWrongWord;
  final Function(int timeElapsed, int answered, int wrong, int earnedTP) onQuizFinished;

  const QuizScreen({
    super.key,
    required this.words,
    required this.threshold,
    required this.questionCount,
    required this.onWordMastered,
    required this.onWrongWord,
    required this.onQuizFinished,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List<WordModel> quizWords = [];
  late WordModel currentWord;
  List<String> options = [];
  Set<String> selectedWrongOptions = {};
  bool isAnsweredCorrectly = false;
  late String correctOption;
  
  final Random random = Random();
  
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int answeredQuestions = 0;
  late int totalQuestions;

  Timer? _timer;
  int _secondsElapsed = 0;
  bool isQuizFinished = false;
  bool isAudioEnabled = true;
  bool _isStatsSaved = false;
  
  int _sessionEarnedTP = 0; 

  String _questionSubtext = "";
  late String _displayWordStr; 

  late AnimationController _entranceController; 
  late AnimationController _shakeController;    
  late AnimationController _scaleController;    
  String? _lastWrongOption; 
  
  bool _isCurrentWordNet = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    List<WordModel> reviewPool = widget.words.where((w) => w.listType == 'toRepeat' || w.wrongCount > 0).toList();
    reviewPool.sort((a, b) => b.wrongCount.compareTo(a.wrongCount)); 

    List<WordModel> newPool = widget.words.where((w) => w.listType == 'all' && w.wrongCount == 0).toList();
    newPool.shuffle();

    int targetReviewCount = (widget.questionCount * 0.4).round();
    int targetNewCount = widget.questionCount - targetReviewCount;

    List<WordModel> selectedReview = [];
    List<WordModel> selectedNew = [];

    if (reviewPool.length <= targetReviewCount) {
      selectedReview = reviewPool;
      targetNewCount = widget.questionCount - selectedReview.length; 
      selectedNew = newPool.take(targetNewCount).toList();
    } else {
      selectedReview = reviewPool.take(targetReviewCount).toList()..shuffle(); 
      selectedNew = newPool.take(targetNewCount).toList();
    }

    quizWords = [...selectedReview, ...selectedNew];
    
    if (quizWords.length < widget.questionCount) {
      var remaining = widget.words.where((w) => !quizWords.contains(w)).toList()..shuffle();
      quizWords.addAll(remaining.take(widget.questionCount - quizWords.length));
    }
    
    quizWords.shuffle(); 
    totalQuestions = quizWords.length;

    if (totalQuestions > 0) {
      _startTimer();
      _generateQuestion();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    globalTts.stop(); 
    _entranceController.dispose();
    _shakeController.dispose();
    _scaleController.dispose();
    if (!_isStatsSaved && answeredQuestions > 0) {
      widget.onQuizFinished(_secondsElapsed, answeredQuestions, wrongAnswers, _sessionEarnedTP);
    }
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int d = totalSeconds ~/ (24 * 3600);
    int h = (totalSeconds % (24 * 3600)) ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${d > 0 ? d.toString().padLeft(2, '0') + ':' : ''}${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _speakText(String text, String languageCode) async {
    if (!isAudioEnabled) return;
    try {
      await globalTts.stop(); 
      String cleanText = text.replaceAll(RegExp(r'\[ID:[a-zA-Z0-9\-]+\]'), '')
                             .replaceAll(RegExp(r'[\[\]\{\}\\|_]'), ' ');
      globalTts.setLanguage(languageCode);
      globalTts.setSpeechRate(0.45); 
      globalTts.speak(cleanText);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  void _speakFeedback(bool isCorrect) {
    if (!isAudioEnabled) return;
    String lang = getSmartSourceLanguage(currentWord.libraryName, currentWord.word);
    String text = "";
    if (lang == 'en-US') text = isCorrect ? "Correct" : "Wrong";
    else if (lang == 'tr-TR') text = isCorrect ? "Doğru" : "Yanlış";
    else text = isCorrect ? "Correct" : "Wrong";
    _speakText(text, lang);
  }
  
  void _flyDiamondAnimation() {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000), 
          curve: Curves.easeInBack,
          onEnd: () {
            overlayEntry?.remove();
          },
          builder: (context, value, child) {
            double startX = MediaQuery.of(context).size.width / 2 - 15;
            double startY = MediaQuery.of(context).size.height / 2;
            
            double endX = MediaQuery.of(context).size.width / 2; 
            double endY = MediaQuery.of(context).padding.top + 80; 

            double currentX = startX + (endX - startX) * value;
            double currentY = startY + (endY - startY) * value;

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0), 
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.8), blurRadius: 20, spreadRadius: 4)]
                  ),
                  child: const Icon(Icons.diamond, color: Colors.lightBlueAccent, size: 30)
                )
              ),
            );
          }
        );
      }
    );
    Overlay.of(context).insert(overlayEntry);
  }

  void _generateQuestion() {
    if (!mounted) return; 
    if (answeredQuestions >= totalQuestions) {
      HapticFeedback.heavyImpact(); 
      setState(() { isQuizFinished = true; _timer?.cancel(); });
      if (!_isStatsSaved) {
        _isStatsSaved = true;
        widget.onQuizFinished(_secondsElapsed, answeredQuestions, wrongAnswers, _sessionEarnedTP);
      }
      _speakText("Congratulations", "en-US");
      return;
    }
    
    selectedWrongOptions.clear();
    _lastWrongOption = null;
    isAnsweredCorrectly = false;
    currentWord = quizWords[answeredQuestions];
    
    _isCurrentWordNet = currentWord.pos.isNotEmpty || currentWord.synonyms.isNotEmpty || currentWord.antonyms.isNotEmpty;
    
    // YENİ DİNAMİK SORU MOTORU BAŞLANGICI
    List<String> qTypes = [];
    
    if (currentWord.meanings.isNotEmpty) {
      qTypes.add('word2meaning'); // Kelime -> Anlam
      qTypes.add('meaning2word'); // Anlam -> Kelime
    }
    if (currentWord.examples.isNotEmpty) {
      qTypes.add('word2example'); // Kelime -> Örnek (Örnek -> Kelime YASAK)
    }
    if (currentWord.synonyms.isNotEmpty) {
      qTypes.add('word2synonym'); // Kelime -> Eş Anlam
      qTypes.add('synonym2word'); // Eş Anlam -> Kelime
    }
    if (currentWord.antonyms.isNotEmpty) {
      qTypes.add('word2antonym'); // Kelime -> Zıt Anlam
      qTypes.add('antonym2word'); // Zıt Anlam -> Kelime
    }

    if (qTypes.isEmpty) qTypes.add('word2word'); // Güvenlik yedeği

    String selectedType = qTypes[random.nextInt(qTypes.length)];
    
    String rawWord = currentWord.word;
    if (RegExp(r'^\d{8}-').hasMatch(rawWord) || rawWord.contains('[ID:')) {
        rawWord = currentWord.synonyms.isNotEmpty ? currentWord.synonyms.first : (currentWord.meanings.isNotEmpty ? currentWord.meanings.first : "WordNet Terimi");
    }

    if (selectedType == 'word2meaning') {
      _questionSubtext = "Bu Kelimenin Anlamı Nedir?";
      _displayWordStr = rawWord;
      correctOption = currentWord.meanings[random.nextInt(currentWord.meanings.length)];
    } else if (selectedType == 'meaning2word') {
      _questionSubtext = "Bu Anlama Gelen Kelime Hangisidir?";
      _displayWordStr = currentWord.meanings[random.nextInt(currentWord.meanings.length)];
      correctOption = rawWord;
    } else if (selectedType == 'word2example') {
      _questionSubtext = "Hangi Cümlede Örnek Olarak Kullanılmıştır?";
      _displayWordStr = rawWord;
      correctOption = currentWord.examples[random.nextInt(currentWord.examples.length)];
    } else if (selectedType == 'word2synonym') {
      _questionSubtext = "Bu Kelimenin Eş Anlamlısı (Synonym) Nedir?";
      _displayWordStr = rawWord;
      correctOption = currentWord.synonyms[random.nextInt(currentWord.synonyms.length)];
    } else if (selectedType == 'synonym2word') {
      _questionSubtext = "Bu Kelimenin Eş Anlamlısı (Synonym) Hangisidir?";
      _displayWordStr = currentWord.synonyms[random.nextInt(currentWord.synonyms.length)];
      correctOption = rawWord;
    } else if (selectedType == 'word2antonym') {
      _questionSubtext = "Bu Kelimenin Zıt Anlamlısı (Antonym) Nedir?";
      _displayWordStr = rawWord;
      correctOption = currentWord.antonyms[random.nextInt(currentWord.antonyms.length)];
    } else if (selectedType == 'antonym2word') {
      _questionSubtext = "Bu Kelimenin Zıt Anlamlısı (Antonym) Hangisidir?";
      _displayWordStr = currentWord.antonyms[random.nextInt(currentWord.antonyms.length)];
      correctOption = rawWord;
    } else {
      _questionSubtext = "Doğru Eşleşmeyi Bulun";
      _displayWordStr = rawWord;
      correctOption = rawWord;
    }

    Set<String> wOptions = {};
    int loops = 0;
    while(wOptions.length < 3 && loops < 200) {
      loops++;
      WordModel rw = widget.words[random.nextInt(widget.words.length)];
      
      if (rw.word != currentWord.word) {
        String wOpt = "";
        String rwRawWord = rw.word;
        if (RegExp(r'^\d{8}-').hasMatch(rwRawWord) || rwRawWord.contains('[ID:')) {
            rwRawWord = rw.synonyms.isNotEmpty ? rw.synonyms.first : rw.word;
        }

        if (selectedType == 'word2meaning') {
           if (rw.meanings.isNotEmpty) wOpt = rw.meanings[random.nextInt(rw.meanings.length)];
        } else if (selectedType == 'meaning2word') {
           wOpt = rwRawWord;
        } else if (selectedType == 'word2example') {
           if (rw.examples.isNotEmpty) wOpt = rw.examples[random.nextInt(rw.examples.length)];
        } else if (selectedType == 'word2synonym') {
           if (rw.synonyms.isNotEmpty) wOpt = rw.synonyms[random.nextInt(rw.synonyms.length)];
           else wOpt = rwRawWord; 
        } else if (selectedType == 'synonym2word') {
           wOpt = rwRawWord;
        } else if (selectedType == 'word2antonym') {
           if (rw.antonyms.isNotEmpty) wOpt = rw.antonyms[random.nextInt(rw.antonyms.length)];
           else wOpt = rwRawWord; 
        } else if (selectedType == 'antonym2word') {
           wOpt = rwRawWord;
        } else {
           wOpt = rwRawWord;
        }
        
        if (wOpt.isNotEmpty && wOpt != correctOption && !wOptions.contains(wOpt)) {
          wOptions.add(wOpt);
        }
      }
    }
    
    // Eğer yeterli yanlış cevap bulunamazsa yedek olarak seçenekleri rastgele doldur
    if (wOptions.length < 3) {
      wOptions.addAll(["Entity", "Process", "Attribute", "Event", "Condition", "State"]);
      wOptions = wOptions.take(3).toSet();
    }
    
    options = [correctOption, ...wOptions];
    options.shuffle();
    setState(() {});
    
    _entranceController.forward(from: 0.0); 
    
    _speakText(_displayWordStr, getSmartSourceLanguage(currentWord.libraryName, _displayWordStr));
  }

  String _getReadableLang(String code) {
    if (code.contains('en')) return 'İng';
    if (code.contains('tr')) return 'Tr';
    if (code.contains('de')) return 'Alm';
    if (code.contains('fr')) return 'Fra';
    if (code.contains('es')) return 'İsp';
    if (code.contains('ru')) return 'Rus';
    return code.split('-').first.toUpperCase();
  }

  void _checkAnswer(String option) async {
    if (isAnsweredCorrectly || selectedWrongOptions.contains(option)) return;
    bool isCorrect = (option == correctOption);
    
    String srcCode = getSmartSourceLanguage(currentWord.libraryName, currentWord.word);
    String tgtCode = getSmartTargetLanguage(currentWord.libraryName, correctOption);
    String mitosisLibName = "\u{1F9EC} Mitoz (${_getReadableLang(srcCode)}-${_getReadableLang(tgtCode)})";

    if (isCorrect) {
      setState(() {
        isAnsweredCorrectly = true;
        answeredQuestions++;
        HapticFeedback.mediumImpact(); 
        _scaleController.forward(from: 0.0); 
        _sessionEarnedTP += 3; 
      });
      _flyDiamondAnimation();

      if (selectedWrongOptions.isEmpty) { 
        correctAnswers++; 
        
        if (_isCurrentWordNet) {
          widget.onWordMastered(currentWord);
        } else {
          int totalOptions = currentWord.meanings.length + currentWord.examples.length;
          if (totalOptions > 1) {
            bool isMeaning = currentWord.meanings.contains(correctOption);
            
            if (isMeaning) {
              currentWord.meanings = List.from(currentWord.meanings)..remove(correctOption);
            } else {
              currentWord.examples = List.from(currentWord.examples)..remove(correctOption);
            }

            bool isGhostCard = currentWord.meanings.isEmpty && currentWord.examples.isEmpty;

            WordModel? existingMitosisCard;
            try {
              var matchingWords = await isar.wordModels.filter()
                  .wordEqualTo(currentWord.word, caseSensitive: false)
                  .libraryNameEqualTo(mitosisLibName)
                  .findAll();
              
              String safeCorrect = correctOption.toLowerCase().trim();
              for (var mWord in matchingWords) {
                if (isMeaning && mWord.meanings.map((e)=>e.toLowerCase().trim()).contains(safeCorrect)) {
                   existingMitosisCard = mWord; break;
                } else if (!isMeaning && mWord.examples.map((e)=>e.toLowerCase().trim()).contains(safeCorrect)) {
                   existingMitosisCard = mWord; break;
                }
              }
            } catch(e) { debugPrint("Arama hatası: $e"); }

            if (existingMitosisCard != null) {
              existingMitosisCard.correctCount++;
              isar.writeTxn(() async {
                if (isGhostCard) {
                  await isar.wordModels.delete(currentWord.id);
                } else {
                  await isar.wordModels.put(currentWord);
                }
                await isar.wordModels.put(existingMitosisCard!);
              });
              currentWord = existingMitosisCard;
              if (existingMitosisCard.correctCount >= widget.threshold) widget.onWordMastered(existingMitosisCard);
            } else {
              WordModel splitWord = WordModel(
                word: currentWord.word,
                meanings: isMeaning ? [correctOption] : [],
                examples: !isMeaning ? [correctOption] : [],
                libraryName: mitosisLibName, 
                level: currentWord.level,
                correctCount: currentWord.correctCount + 1, 
                wrongCount: currentWord.wrongCount,
                listType: currentWord.listType,
                srsLevel: currentWord.srsLevel,
                nextReviewDate: currentWord.nextReviewDate,
                sourceLanguage: currentWord.sourceLanguage,
                targetLanguage: currentWord.targetLanguage,
                pos: '', synonyms: [], antonyms: []
              );
              isar.writeTxn(() async {
                if (isGhostCard) {
                  await isar.wordModels.delete(currentWord.id);
                } else {
                  await isar.wordModels.put(currentWord);
                }
                await isar.wordModels.put(splitWord);   
              });
              currentWord = splitWord; 
              if (splitWord.correctCount >= widget.threshold) widget.onWordMastered(splitWord);
            }
          } else {
            currentWord.correctCount++;
            isar.writeTxn(() async { await isar.wordModels.put(currentWord); });
            if (currentWord.correctCount >= widget.threshold) widget.onWordMastered(currentWord);
          }
        }
      }
      
      _speakFeedback(true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _generateQuestion();
      });
      
    } else {
      setState(() {
        selectedWrongOptions.add(option);
        wrongAnswers++; 
        HapticFeedback.heavyImpact(); 
        _lastWrongOption = option; 
        _shakeController.forward(from: 0.0); 
        _sessionEarnedTP = max(0, _sessionEarnedTP - 1); 
      });

      if (selectedWrongOptions.length == 1) { 
        if (_isCurrentWordNet) {
          widget.onWrongWord(currentWord);
        } else {
          int totalOptions = currentWord.meanings.length + currentWord.examples.length;
          if (totalOptions > 1) {
            bool isMeaning = currentWord.meanings.contains(correctOption);
            
            if (isMeaning) {
              currentWord.meanings = List.from(currentWord.meanings)..remove(correctOption);
            } else {
              currentWord.examples = List.from(currentWord.examples)..remove(correctOption);
            }

            bool isGhostCard = currentWord.meanings.isEmpty && currentWord.examples.isEmpty;

            WordModel? existingMitosisCard;
            try {
              var matchingWords = await isar.wordModels.filter()
                  .wordEqualTo(currentWord.word, caseSensitive: false)
                  .libraryNameEqualTo(mitosisLibName)
                  .findAll();
              
              String safeCorrect = correctOption.toLowerCase().trim();
              for (var mWord in matchingWords) {
                if (isMeaning && mWord.meanings.map((e)=>e.toLowerCase().trim()).contains(safeCorrect)) {
                   existingMitosisCard = mWord; break;
                } else if (!isMeaning && mWord.examples.map((e)=>e.toLowerCase().trim()).contains(safeCorrect)) {
                   existingMitosisCard = mWord; break;
                }
              }
            } catch(e) {}

            if (existingMitosisCard != null) {
              existingMitosisCard.wrongCount++;
              isar.writeTxn(() async {
                if (isGhostCard) {
                  await isar.wordModels.delete(currentWord.id);
                } else {
                  await isar.wordModels.put(currentWord);
                }
                await isar.wordModels.put(existingMitosisCard!);
              });
              currentWord = existingMitosisCard;
              widget.onWrongWord(existingMitosisCard);
            } else {
              WordModel splitWord = WordModel(
                word: currentWord.word,
                meanings: isMeaning ? [correctOption] : [],
                examples: !isMeaning ? [correctOption] : [],
                libraryName: mitosisLibName, 
                level: currentWord.level,
                correctCount: currentWord.correctCount,
                wrongCount: currentWord.wrongCount + 1,
                listType: currentWord.listType,
                srsLevel: currentWord.srsLevel,
                nextReviewDate: currentWord.nextReviewDate,
                sourceLanguage: currentWord.sourceLanguage,
                targetLanguage: currentWord.targetLanguage,
                pos: '', synonyms: [], antonyms: []
              );
              isar.writeTxn(() async {
                if (isGhostCard) {
                  await isar.wordModels.delete(currentWord.id);
                } else {
                  await isar.wordModels.put(currentWord);
                }
                await isar.wordModels.put(splitWord);
              });
              currentWord = splitWord;
              widget.onWrongWord(splitWord);
            }
          } else {
            currentWord.wrongCount++;
            isar.writeTxn(() async { await isar.wordModels.put(currentWord); });
            widget.onWrongWord(currentWord);
          }
        }
      }
      _speakFeedback(false);
    }
  }

  void _resetQuiz() {
    HapticFeedback.lightImpact();
    setState(() {
      correctAnswers = 0; wrongAnswers = 0; answeredQuestions = 0; _secondsElapsed = 0; _sessionEarnedTP = 0;
      isQuizFinished = false; _isStatsSaved = false;
      List<WordModel> pool = List.from(widget.words)..shuffle();
      quizWords = pool.take(min(widget.questionCount, pool.length)).toList();
      totalQuestions = quizWords.length;
      if (totalQuestions > 0) { _startTimer(); _generateQuestion(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) return Scaffold(appBar: AppBar(title: const Text("Quiz")), body: const Center(child: Text("Bu kütüphanede yeterli kelime yok.")));

    if (isQuizFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lexis Eldora | Quiz İstatistikleri", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Quiz Tamamlandı! 🎉", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                Lottie.network('https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', height: 180, repeat: true, errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events, size: 80, color: Colors.amber)),
                const SizedBox(height: 10),
                const Text("Congratulations!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Doğru Sayısı:", style: TextStyle(fontSize: 20)), Text("$correctAnswers", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Yanlış Sayısı:", style: TextStyle(fontSize: 20)), Text("$wrongAnswers", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red))]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Geçen Süre:", style: TextStyle(fontSize: 20)), Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue))]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Kazanılan TP:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), 
                          Row(
                            children: [
                              const Icon(Icons.diamond, color: Colors.green, size: 24),
                              const SizedBox(width: 6),
                              Text("+$_sessionEarnedTP", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.green)),
                            ],
                          )
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5), icon: const Icon(Icons.refresh), label: const Text("YENİ QUİZ BAŞLAT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), onPressed: _resetQuiz)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: TextButton.icon(style: TextButton.styleFrom(padding: const EdgeInsets.all(16)), icon: const Icon(Icons.home), label: const Text("ANA EKRANA DÖN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); })),
                const SizedBox(height: 40), 
              ],
            ),
          ),
        ),
      );
    }

    Color borderColor = Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.5);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Lexis Eldora | Quiz", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Theme.of(context).primaryColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isAudioEnabled ? Icons.volume_up : Icons.volume_off), 
            onPressed: () { 
              HapticFeedback.selectionClick(); 
              setState(() => isAudioEnabled = !isAudioEnabled); 
            }
          )
        ]
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor.withOpacity(0.1), Colors.transparent], 
            begin: Alignment.topCenter, end: Alignment.bottomCenter
          )
        ),
        child: ListView(
          // YENİ: Alt kısma 120 padding verilerek uzun metinlerin ve kaydırmanın sorunsuz olması sağlandı.
          padding: EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 120), 
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 5), Text(correctAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]),
                Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueAccent)),
                Row(children: [Text(wrongAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(width: 5), const Icon(Icons.cancel, color: Colors.red)]),
              ],
            ),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Soru: ${min(answeredQuestions + 1, totalQuestions)} / $totalQuestions", 
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.2), blurRadius: 8)]
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.lightBlueAccent, size: 14),
                      const SizedBox(width: 4),
                      Text("$_sessionEarnedTP", style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 8),
            LinearProgressIndicator(value: totalQuestions > 0 ? answeredQuestions / totalQuestions : 0, backgroundColor: Colors.grey[300], color: Theme.of(context).primaryColor, minHeight: 8, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                String readWord = _displayWordStr == "WordNet Kaydı" && currentWord.meanings.isNotEmpty ? currentWord.meanings.first : _displayWordStr;
                _speakText(readWord, getSmartSourceLanguage(currentWord.libraryName, readWord));
              },
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _entranceController.value)),
                    child: Opacity(
                      opacity: _entranceController.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.08), 
                              borderRadius: BorderRadius.circular(20), 
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1.5), 
                              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)]
                            ),
                            child: Column(
                              children: [
                                Text(_displayWordStr, textAlign: TextAlign.center, style: TextStyle(fontSize: _isCurrentWordNet && _questionSubtext.contains("Tanım") ? 22 : 30, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 1.2)),
                                
                                // YENİ: Sorunun türünü açıklayan şık alt başlık rozeti
                                if (_questionSubtext.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 24.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                                      boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.15), blurRadius: 10)]
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.help_outline, color: Colors.orangeAccent.shade700, size: 16),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _questionSubtext, 
                                            textAlign: TextAlign.center, 
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent.shade700)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            
            ...List.generate(options.length, (index) {
              String option = options[index];
              bool isCorrect = option == correctOption;
              bool isWrongSelected = selectedWrongOptions.contains(option);
              
              Color cardColor = Theme.of(context).cardColor;
              Widget? trailingIcon;
              
              if (isAnsweredCorrectly && isCorrect) { cardColor = Colors.green.withOpacity(0.2); trailingIcon = const Icon(Icons.check_circle, color: Colors.green); } 
              else if (isWrongSelected) { cardColor = Colors.red.withOpacity(0.2); trailingIcon = const Icon(Icons.cancel, color: Colors.red); }

              Widget tile = Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor, 
                  border: Border.all(color: isAnsweredCorrectly && isCorrect ? Colors.green : (isWrongSelected ? Colors.red : borderColor.withOpacity(0.3)), width: 2), 
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4), spreadRadius: 1)]
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _checkAnswer(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            // YENİ: Sınır (maxLines) kaldırılarak uzun paragrafların tamamen görünmesi sağlandı.
                            child: Text(option, style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500)),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 12),
                            trailingIcon,
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );

              if (isWrongSelected && option == _lastWrongOption) tile = AnimatedBuilder(animation: _shakeController, builder: (c, ch) => Transform.translate(offset: Offset(sin(_shakeController.value * pi * 6) * 10, 0), child: ch), child: tile);
              if (isAnsweredCorrectly && isCorrect) tile = AnimatedBuilder(animation: _scaleController, builder: (c, ch) => Transform.scale(scale: 1.0 + (_scaleController.value * 0.05), child: ch), child: tile);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 150)), 
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut))), 
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut))), 
                    child: tile
                  )
                )
              );
            }),
          ],
        ),
      ),
    );
  }
}
