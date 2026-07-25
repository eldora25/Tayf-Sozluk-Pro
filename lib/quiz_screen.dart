import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'models.dart';

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int threshold;
  final Function(WordModel) onWordLearned;
  final Function(WordModel) onWordWrong;

  const QuizScreen({
    super.key,
    required this.words,
    required this.threshold,
    required this.onWordLearned,
    required this.onWordWrong,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FlutterTts flutterTts = FlutterTts();
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

  @override
  void initState() {
    super.initState();
    totalQuestions = widget.words.length;
    _initTts();
    _startTimer();
    _generateQuestion();
  }

  void _initTts() async {
    await flutterTts.setLanguage("tr-TR");
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _generateQuestion() {
    if (widget.words.isEmpty) return;
    
    selectedWrongOptions.clear();
    isAnsweredCorrectly = false;
    currentWord = widget.words[random.nextInt(widget.words.length)];
    
    // Doğru kelimenin çoklu anlamlarından RASTGELE sadece bir tanesini seç
    correctOption = currentWord.meanings[random.nextInt(currentWord.meanings.length)];
    Set<String> wrongOptions = {};
    
    // Çeldiricileri de diğer kelimelerin rastgele TEK bir anlamından seç
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
  }

  void _checkAnswer(String option) {
    if (isAnsweredCorrectly || selectedWrongOptions.contains(option)) return;
    
    setState(() {
      if (option == correctOption) {
        // DOĞRU CEVAP
        isAnsweredCorrectly = true;
        currentWord.correctCount++;
        correctAnswers++;
        answeredQuestions++;
        flutterTts.speak("Doğru"); // Onay Sesi
        
        // Ezberlendi mi?
        if (currentWord.correctCount >= widget.threshold) {
          widget.onWordLearned(currentWord);
        }
        
        Future.delayed(const Duration(seconds: 1), _generateQuestion);
      } else {
        // YANLIŞ CEVAP
        selectedWrongOptions.add(option);
        currentWord.wrongCount++;
        wrongAnswers++;
        flutterTts.speak("Yanlış"); // Hata Sesi
        widget.onWordWrong(currentWord);
        // Yeni soruya geçilmiyor, bekliyoruz.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: const Center(child: Text("Tebrikler! Bu kütüphanedeki tüm kelimeleri öğrendiniz.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Modu")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ÜST BİLGİ PANELLERİ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 5), Text(correctAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Row(children: [Text(wrongAnswers.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 5), const Icon(Icons.cancel, color: Colors.red)]),
              ],
            ),
            const SizedBox(height: 10),
            Text("Soru: $answeredQuestions / $totalQuestions", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: totalQuestions > 0 ? answeredQuestions / totalQuestions : 0,
              backgroundColor: Colors.grey[300],
              color: Colors.deepPurple,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 30),
            
            // KELİME KUTUSU
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(currentWord.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            
            // SEÇENEKLER
            ...options.map((option) {
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

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(option, style: const TextStyle(fontSize: 18)),
                  trailing: trailingIcon,
                  onTap: () => _checkAnswer(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
