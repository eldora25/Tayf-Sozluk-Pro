import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // YENİ: HapticFeedback (Titreşim) için eklendi
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart'; 
import 'models.dart';

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int threshold;
  final int questionCount;
  final Function(WordModel) onWordLearned;
  final Function(WordModel) onWordWrong;
  final Function(int timeElapsed, int answered, int wrong) onQuizFinished; 

  const QuizScreen({
    super.key,
    required this.words,
    required this.threshold,
    required this.questionCount,
    required this.onWordLearned,
    required this.onWordWrong,
    required this.onQuizFinished,
  });

  @override
  // YENİ: Birden fazla animasyon motorunu çalıştırmak için TickerProviderStateMixin eklendi
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
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

  // YENİ: ANİMASYON KONTROLCÜLERİ
  late AnimationController _entranceController; // Şıkların süzülerek gelmesi için
  late AnimationController _shakeController;    // Yanlış cevaptaki sarsıntı için
  late AnimationController _scaleController;    // Doğru cevaptaki büyüme (pop-up) için
  String? _lastWrongOption; // Hangi şıkkın sarsılacağını bilmek için

  @override
  void initState() {
    super.initState();
    
    // YENİ: Animasyon motorları başlatılıyor
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    List<WordModel> pool = List.from(widget.words)..shuffle();
    quizWords = pool.take(min(widget.questionCount, pool.length)).toList();
    totalQuestions = quizWords.length;

    if (totalQuestions > 0) {
      _startTimer();
      _generateQuestion();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    flutterTts.stop();
    _entranceController.dispose();
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _speakWord(String text, String libraryName) async {
    if (!isAudioEnabled) return;
    String lang = getSourceLanguage(libraryName);
    await flutterTts.setLanguage(lang);
    await flutterTts.speak(text);
  }

  void _speakFeedback(bool isCorrect, WordModel word) {
    if (!isAudioEnabled) return;
    String lang = getSourceLanguage(word.libraryName);
    if (lang == 'tr-TR') {
      flutterTts.speak(isCorrect ? "Doğru" : "Yanlış");
    } else {
      flutterTts.speak(isCorrect ? "Correct" : "Wrong");
    }
  }

  void _speakCompletion() {
    if (!isAudioEnabled || quizWords.isEmpty) return;
    String lang = getSourceLanguage(quizWords.first.libraryName);
    if (lang == 'tr-TR') {
      flutterTts.speak("Tebrikler");
    } else {
      flutterTts.speak("Congratulations");
    }
  }

  void _generateQuestion() {
    if (answeredQuestions >= totalQuestions) {
      setState(() {
        isQuizFinished = true;
        _timer?.cancel();
      });
      if (!_isStatsSaved) {
        _isStatsSaved = true;
        widget.onQuizFinished(_secondsElapsed, answeredQuestions, wrongAnswers);
      }
      _speakCompletion();
      return;
    }
    
    selectedWrongOptions.clear();
    _lastWrongOption = null;
    isAnsweredCorrectly = false;
    currentWord = quizWords[answeredQuestions];
    
    correctOption = currentWord.meanings[random.nextInt(currentWord.meanings.length)];
    Set<String> wrongOptions = {};
    
    while (wrongOptions.length < 3 && wrongOptions.length < widget.words.length - 1) {
      WordModel randomWord = widget.words[random.nextInt(widget.words.length)];
      if (randomWord.word != currentWord.word && randomWord.meanings.isNotEmpty) {
        String randomMeaning = randomWord.meanings[random.nextInt(randomWord.meanings.length)];
        wrongOptions.add(randomMeaning);
      }
    }
    
    options = [correctOption, ...wrongOptions];
    options.shuffle();
    
    setState(() {});
    
    // YENİ: Yeni soru geldiğinde süzülme animasyonunu baştan başlatır
    _entranceController.forward(from: 0.0);
    
    _speakWord(currentWord.word, currentWord.libraryName);
  }

  void _checkAnswer(String option) {
    if (isAnsweredCorrectly || selectedWrongOptions.contains(option)) return;
    
    setState(() {
      if (option == correctOption) {
        isAnsweredCorrectly = true;
        answeredQuestions++;
        
        // YENİ: Doğru cevapta Cihaz Hafif Titrer ve Pop-up (Büyüme) Animasyonu başlar
        HapticFeedback.mediumImpact();
        _scaleController.forward(from: 0.0);
        
        if (selectedWrongOptions.isEmpty) {
          correctAnswers++;
          currentWord.correctCount++;
        }
      } else {
        selectedWrongOptions.add(option);
        wrongAnswers++;
        currentWord.wrongCount++;
        
        // YENİ: Yanlış cevapta Cihaz Güçlü Titrer ve Sarsıntı Animasyonu başlar
        HapticFeedback.heavyImpact();
        _lastWrongOption = option;
        _shakeController.forward(from: 0.0);
      }
    });

    if (option == correctOption) {
      _speakFeedback(true, currentWord);
      if (currentWord.correctCount >= widget.threshold) {
         widget.onWordLearned(currentWord);
      }
      // YENİ: Pop-up animasyonunun keyfini çıkarmak için bekleme süresi 1 saniyeye çıkarıldı
      Future.delayed(const Duration(milliseconds: 1000), _generateQuestion);
    } else {
      widget.onWordWrong(currentWord);
      _speakFeedback(false, currentWord);
    }
  }

  void _resetQuiz() {
    setState(() {
      correctAnswers = 0;
      wrongAnswers = 0;
      answeredQuestions = 0;
      _secondsElapsed = 0;
      isQuizFinished = false;
      _isStatsSaved = false;
      List<WordModel> pool = List.from(widget.words)..shuffle();
      quizWords = pool.take(min(widget.questionCount, pool.length)).toList();
      totalQuestions = quizWords.length;
      if (totalQuestions > 0) {
        _startTimer();
        _generateQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: const Center(child: Text("Bu kütüphanede yeterli kelime yok.")),
      );
    }

    if (isQuizFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz İstatistikleri")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Quiz Tamamlandı!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', 
                  height: 180,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text("🎉", style: TextStyle(fontSize: 80)); 
                  },
                ),
                const SizedBox(height: 10),
                Text(getSourceLanguage(quizWords.first.libraryName) == 'tr-TR' ? "Tebrikler!" : "Congratulations!", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Doğru Sayısı:", style: TextStyle(fontSize: 20)),
                          Text("$correctAnswers", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                        ]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Yanlış Sayısı:", style: TextStyle(fontSize: 20)),
                          Text("$wrongAnswers", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        ]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Geçen Süre:", style: TextStyle(fontSize: 20)),
                          Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    icon: const Icon(Icons.refresh),
                    label: const Text("YENİ QUİZ BAŞLAT", style: TextStyle(fontSize: 18)),
                    onPressed: _resetQuiz,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
                    icon: const Icon(Icons.home),
                    label: const Text("ANA EKRANA DÖN", style: TextStyle(fontSize: 18)),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color borderColor = isDarkMode ? Theme.of(context).primaryColor : Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Modu"),
        actions: [
          IconButton(
            icon: Icon(isAudioEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: "Sesi Aç/Kapat",
            onPressed: () => setState(() => isAudioEnabled = !isAudioEnabled),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 5), Text(correctAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Row(children: [Text(wrongAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 5), const Icon(Icons.cancel, color: Colors.red)]),
            ],
          ),
          const SizedBox(height: 10),
          Text("Soru: ${answeredQuestions + 1} / $totalQuestions", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: totalQuestions > 0 ? answeredQuestions / totalQuestions : 0,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).primaryColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 20),
          
          GestureDetector(
            onTap: () => _speakWord(currentWord.word, currentWord.libraryName),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(currentWord.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          
          // ŞIKLARIN OLUŞTURULMASI VE ANİMASYONLARI
          ...List.generate(options.length, (index) {
            String option = options[index];
            bool isCorrect = option == correctOption;
            bool isWrongSelected = selectedWrongOptions.contains(option);
            
            Color cardColor = Theme.of(context).cardColor;
            Widget? trailingIcon;
            
            if (isAnsweredCorrectly && isCorrect) {
              cardColor = Colors.green.withOpacity(0.3);
              trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
            } else if (isWrongSelected) {
              cardColor = Colors.red.withOpacity(0.3);
              trailingIcon = const Icon(Icons.cancel, color: Colors.red);
            }

            // 1. SÜZÜLEREK GELME (STAGGERED FADE/SLIDE)
            final Animation<double> entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _entranceController, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut)),
            );
            final Animation<Offset> entranceSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
              CurvedAnimation(parent: _entranceController, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut)),
            );

            Widget tile = Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(option, style: const TextStyle(fontSize: 16), maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: trailingIcon,
                onTap: () => _checkAnswer(option),
              ),
            );

            // 2. SARSINTI (SHAKE) ANİMASYONU - Sadece son tıklanan yanlış şık sarsılır
            if (isWrongSelected && option == _lastWrongOption) {
              tile = AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  // Sinüs dalgası ile sağa sola sarsıntı matematiği (3 kez gidip gelir, 10px kayar)
                  final double shift = sin(_shakeController.value * pi * 6) * 10;
                  return Transform.translate(
                    offset: Offset(shift, 0),
                    child: child,
                  );
                },
                child: tile,
              );
            }

            // 3. BÜYÜME (POP-UP) ANİMASYONU - Sadece doğru şıkta uygulanır
            if (isAnsweredCorrectly && isCorrect) {
              tile = AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  // %8 oranında büyüyüp dikkat çeker
                  final double scale = 1.0 + (_scaleController.value * 0.08); 
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: tile,
              );
            }

            // En dış katmanda süzülme animasyonu var
            return FadeTransition(
              opacity: entranceOpacity,
              child: SlideTransition(
                position: entranceSlide,
                child: tile,
              ),
            );
          }),
        ],
      ),
    );
  }
}
