import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_model.dart';

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int questionCount;
  final int threshold;
  final Function(WordModel) onWrongWord;
  final Function(WordModel) onWordMastered;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.questionCount,
    required this.threshold,
    required this.onWrongWord,
    required this.onWordMastered,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  late WordModel _currentWord;
  late List<String> _options;
  String? _selectedOption;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    _isAnswered = false;
    _selectedOption = null;
    _currentWord = widget.words[Random().nextInt(widget.words.length)];
    
    String correctMeaning = _currentWord.meanings.first;
    Set<String> wrongOptions = {};
    
    while (wrongOptions.length < 3) {
      var randomWord = widget.words[Random().nextInt(widget.words.length)];
      if (randomWord.word != _currentWord.word) {
        wrongOptions.add(randomWord.meanings.first);
      }
    }
    
    _options = [correctMeaning, ...wrongOptions];
    _options.shuffle();
  }

  void _handleOptionTap(String option) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      if (option == _currentWord.meanings.first) {
        _correctAnswers++;
        _currentWord.quizCorrectCount++;
        if (_currentWord.quizCorrectCount >= widget.threshold) {
          widget.onWordMastered(_currentWord);
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (_currentIndex < widget.questionCount - 1) {
            setState(() { _currentIndex++; _generateQuestion(); });
          } else {
            _showFinishedDialog();
          }
        });
      } else {
        _wrongAnswers++;
        widget.onWrongWord(_currentWord);
      }
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Tamamlandı! 🎉"),
        content: Text("Doğru: $_correctAnswers\nYanlış: $_wrongAnswers"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Kapat"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quiz (${_currentIndex + 1}/${widget.questionCount})")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        key: ValueKey(_currentIndex),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("✓ Doğru: $_correctAnswers", style: const TextStyle(color: Colors.green, fontSize: 16)),
                Text("✗ Yanlış: $_wrongAnswers", style: const TextStyle(color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
              child: Text(_currentWord.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const SizedBox(height: 30),
            ..._options.map((option) {
              bool isCorrect = option == _currentWord.meanings.first;
              bool isSelected = option == _selectedOption;
              Color btnColor = Colors.purple.shade100;
              Widget? suffixIcon;

              if (_isAnswered) {
                if (isCorrect) {
                  btnColor = Colors.green.shade200;
                  suffixIcon = const Icon(Icons.check, color: Colors.green);
                } else if (isSelected) {
                  btnColor = Colors.red.shade200;
                  suffixIcon = const Icon(Icons.close, color: Colors.red);
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () => _handleOptionTap(option),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Text(option, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                        if (suffixIcon != null) suffixIcon,
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
