import 'dart:math';
import 'package:flutter/material.dart';
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
  late WordModel currentWord;
  List<String> options = [];
  bool isAnswered = false;
  String? selectedOption;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    if (widget.words.isEmpty) return;
    
    isAnswered = false;
    selectedOption = null;
    currentWord = widget.words[random.nextInt(widget.words.length)];
    
    String correctMeaning = currentWord.meanings.first;
    Set<String> wrongOptions = {};
    
    // Rastgele yanlış cevaplar bul
    while (wrongOptions.length < 3 && wrongOptions.length < widget.words.length - 1) {
      WordModel randomWord = widget.words[random.nextInt(widget.words.length)];
      if (randomWord.word != currentWord.word && randomWord.meanings.isNotEmpty) {
        wrongOptions.add(randomWord.meanings.first);
      }
    }
    
    options = [correctMeaning, ...wrongOptions];
    options.shuffle();
    setState(() {});
  }

  void _checkAnswer(String option) {
    if (isAnswered) return;
    
    setState(() {
      isAnswered = true;
      selectedOption = option;
      
      if (option == currentWord.meanings.first) {
        // Doğru
        currentWord.correctCount++;
        if (currentWord.correctCount >= widget.threshold) {
          widget.onWordLearned(currentWord);
        }
        Future.delayed(const Duration(seconds: 1), _generateQuestion);
      } else {
        // Yanlış
        currentWord.wrongCount++;
        widget.onWordWrong(currentWord);
        // Yanlışta otomatik geçiş yok, kullanıcı tıklayarak geçer
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

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Modu")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Hedef Eşik: ${currentWord.correctCount} / ${widget.threshold}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentWord.word,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            ...options.map((option) {
              bool isCorrect = option == currentWord.meanings.first;
              bool isSelected = option == selectedOption;
              
              Color cardColor = Theme.of(context).cardColor;
              Widget? trailingIcon;
              
              if (isAnswered) {
                if (isCorrect) {
                  cardColor = Colors.green.withOpacity(0.3);
                  trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
                } else if (isSelected) {
                  cardColor = Colors.red.withOpacity(0.3);
                  trailingIcon = const Icon(Icons.cancel, color: Colors.red);
                }
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
            if (isAnswered && selectedOption != currentWord.meanings.first)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: _generateQuestion,
                  child: const Text("Sonraki Soru"),
                ),
              )
          ],
        ),
      ),
    );
  }
}
