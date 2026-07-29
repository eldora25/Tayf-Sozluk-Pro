import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:lottie/lottie.dart'; 
import 'models.dart';
import 'main.dart'; 

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int threshold;
  final int questionCount;
  final Function(WordModel) onWordMastered;
  final Function(WordModel) onWrongWord;
  final Function(int timeElapsed, int answered, int wrong) onQuizFinished;

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

  late AnimationController _entranceController; 
  late AnimationController _shakeController;    
  late AnimationController _scaleController;    
  String? _lastWrongOption; 

  @override
  void initState() {
    super.initState();
    
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
    globalTts.stop(); 
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

  Future<void> _speakText(String text, String languageCode) async {
    if (!isAudioEnabled) return;
    try {
      await globalTts.stop();
      String cleanText = text.replaceAll(RegExp(r'[\[\]\{\}\\|_]'), ' ');
      
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
    
    if (lang == 'en-US') {
      text = isCorrect ? "Correct" : "Wrong";
    } else if (lang == 'tr-TR') {
      text = isCorrect ? "Doğru" : "Yanlış";
    } else if (lang == 'de-DE') {
      text = isCorrect ? "Richtig" : "Falsch";
    } else if (lang == 'es-ES') {
      text = isCorrect ? "Correcto" : "Incorrecto";
    } else if (lang == 'fr-FR') {
      text = isCorrect ? "Vrai" : "Faux";
    } else if (lang == 'ru-RU') {
      text = isCorrect ? "Правильно" : "Неправильно";
    } else {
      text = isCorrect ? "Correct" : "Wrong";
    }
    
    _speakText(text, lang);
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
      _speakText("Congratulations", "en-US");
      return;
    }
    
    selectedWrongOptions.clear();
    _lastWrongOption = null;
    isAnsweredCorrectly = false;
    currentWord = quizWords[answeredQuestions];
    
    // Doğru Şık: Çoklu anlamlardan rastgele sadece 1 tanesi alınır.
    correctOption = currentWord.meanings[random.nextInt(currentWord.meanings.length)];
    Set<String> wrongOptions = {};
    
    // Yanlış Şıklar (Çeldiriciler):
    while (wrongOptions.length < 3 && wrongOptions.length < widget.words.length - 1) {
      WordModel randomWord = widget.words[random.nextInt(widget.words.length)];
      
      // 1. Kesinlikle başka kelime olacak
      // 2. Anlamı boş olmayacak
      if (randomWord.word != currentWord.word && randomWord.meanings.isNotEmpty) {
        
        // Çoklu anlamlardan SADECE BİR TANESİ rastgele seçilir
        String randomMeaning = randomWord.meanings[random.nextInt(randomWord.meanings.length)];
        
        // Seçilen bu yanlış anlam, tesadüfen doğru kelimenin anlamlarından biriyle aynı olmasın
        if (!currentWord.meanings.contains(randomMeaning)) {
          wrongOptions.add(randomMeaning);
        }
      }
    }
    
    options = [correctOption, ...wrongOptions];
    options.shuffle();
    
    setState(() {});
    
    _entranceController.forward(from: 0.0); 
    _speakText(currentWord.word, getSmartSourceLanguage(currentWord.libraryName, currentWord.word));
  }

  void _checkAnswer(String option) {
    if (isAnsweredCorrectly || selectedWrongOptions.contains(option)) return;
    
    setState(() {
      if (option == correctOption) {
        isAnsweredCorrectly = true;
        answeredQuestions++;
        
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
        
        HapticFeedback.heavyImpact(); 
        _lastWrongOption = option;
        _shakeController.forward(from: 0.0); 
      }
    });

    if (option == correctOption) {
      _speakFeedback(true);
      if (currentWord.correctCount >= widget.threshold) {
         widget.onWordMastered(currentWord);
      }
      Future.delayed(const Duration(milliseconds: 1500), _generateQuestion);
    } else {
      widget.onWrongWord(currentWord);
      _speakFeedback(false);
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
                const Text("Quiz Tamamlandı! 🎉", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', 
                  height: 180,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                ),
                const SizedBox(height: 10),
                const Text("Congratulations!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
    Color borderColor = isDarkMode ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.5);

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
              Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 5), Text(correctAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]),
              Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueAccent)),
              Row(children: [Text(wrongAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(width: 5), const Icon(Icons.cancel, color: Colors.red)]),
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
            onTap: () => _speakText(currentWord.word, getSmartSourceLanguage(currentWord.libraryName, currentWord.word)),
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _entranceController.value)),
                  child: Opacity(
                    opacity: _entranceController.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08), 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]
                      ),
                      child: Text(
                        currentWord.word, 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          
          ...List.generate(options.length, (index) {
            String option = options[index];
            bool isCorrect = option == correctOption;
            bool isWrongSelected = selectedWrongOptions.contains(option);
            
            Color cardColor = Theme.of(context).cardColor;
            Widget? trailingIcon;
            double scaleValue = 1.0;
            
            if (isAnsweredCorrectly && isCorrect) {
              cardColor = Colors.green.withOpacity(0.3);
              trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
              scaleValue = 1.05; 
            } else if (isWrongSelected) {
              cardColor = Colors.red.withOpacity(0.3);
              trailingIcon = const Icon(Icons.cancel, color: Colors.red);
            }

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
                boxShadow: scaleValue > 1.0 ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
              ),
              child: ListTile(
                title: Text(option, style: const TextStyle(fontSize: 16), maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: trailingIcon,
                onTap: () => _checkAnswer(option),
              ),
            );

            if (isWrongSelected && option == _lastWrongOption) {
              tile = AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double shift = sin(_shakeController.value * pi * 6) * 10;
                  return Transform.translate(offset: Offset(shift, 0), child: child);
                },
                child: tile,
              );
            }

            if (isAnsweredCorrectly && isCorrect) {
              tile = AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  final double scale = 1.0 + (_scaleController.value * 0.05); 
                  return Transform.scale(scale: scale, child: child);
                },
                child: tile,
              );
            }

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
