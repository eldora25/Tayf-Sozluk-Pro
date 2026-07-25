import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // OPTİMİZASYON: Öncelikli dili kullanır, telefonu yormaz.
  Future<void> _speakWord(String text, String libraryName) async {
    if (!isAudioEnabled) return;
    String lang = getSourceLanguage(libraryName);
    await flutterTts.setLanguage(lang);
    await flutterTts.speak(text);
  }

  // OPTİMİZASYON: Geri bildirim dilini, kelimenin orijinal diliyle EŞLEŞTİRİR
  // İngilizce ise İngilizce, Türkçe ise Türkçe geribildirim verir. Dil değiştirmekle zaman kaybetmez.
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
    _speakWord(currentWord.word, currentWord.libraryName);
  }

  void _checkAnswer(String option) {
    if (isAnsweredCorrectly || selectedWrongOptions.contains(option)) return;
    
    setState(() {
      if (option == correctOption) {
        isAnsweredCorrectly = true;
        answeredQuestions++;
        if (selectedWrongOptions.isEmpty) {
          correctAnswers++;
          currentWord.correctCount++;
        }
      } else {
        selectedWrongOptions.add(option);
        wrongAnswers++;
        currentWord.wrongCount++;
      }
    });

    if (option == correctOption) {
      _speakFeedback(true, currentWord);
      if (currentWord.correctCount >= widget.threshold) {
         widget.onWordLearned(currentWord);
      }
      // Geçiş hızı 600 ms'ye düşürüldü.
      Future.delayed(const Duration(milliseconds: 600), _generateQuestion);
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
                const Text("🎉", style: TextStyle(fontSize: 80)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: () => _speakWord(currentWord.word, currentWord.libraryName),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Text(currentWord.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
            
            Expanded(
              child: ListView(
                children: options.map((option) {
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

                  return Container(
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
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
