import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'models.dart'; 

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final int questionCount;
  final int threshold;
  final Function(WordModel) onWrongWord;
  final Function(WordModel) onWordMastered;
  final Function(int timeElapsed, int answered, int wrong) onQuizFinished;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.questionCount,
    required this.threshold,
    required this.onWrongWord,
    required this.onWordMastered,
    required this.onQuizFinished, 
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts(); 
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  late WordModel _currentWord;
  late List<String> _options;
  
  Set<String> _selectedWrongOptions = {};
  bool _isCorrectlyAnswered = false; 
  late DateTime _startTime; 
  
  late AnimationController _shakeController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _generateQuestion();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _entranceController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _generateQuestion() {
    _isCorrectlyAnswered = false;
    _selectedWrongOptions.clear(); 
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

    _entranceController.forward(from: 0.0);
    _speakCurrentWord();
  }

  Future<void> _speakCurrentWord() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(_currentWord.word);
    } catch (e) {
      debugPrint("TTS Okuma Hatası: $e");
    }
  }

  void _handleOptionTap(String option) async {
    if (_isCorrectlyAnswered) return; 
    if (_selectedWrongOptions.contains(option)) return; 

    if (option == _currentWord.meanings.first) {
      setState(() {
        _isCorrectlyAnswered = true;
        _correctAnswers++;
        _currentWord.correctCount++; 
        if (_currentWord.correctCount >= widget.threshold) {
          widget.onWordMastered(_currentWord);
        }
      });

      await flutterTts.setLanguage("en-US"); 
      await flutterTts.speak("Correct"); 

      Future.delayed(const Duration(seconds: 1), () {
        if (_currentIndex < widget.questionCount - 1) {
          setState(() { _currentIndex++; _generateQuestion(); });
        } else {
          _finishQuiz(); 
        }
      });
    } else {
      setState(() {
        _selectedWrongOptions.add(option); 
        _wrongAnswers++;
        widget.onWrongWord(_currentWord); 
      });

      _shakeController.forward(from: 0.0);

      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("Wrong"); 
    }
  }

  void _finishQuiz() {
    int timeElapsed = DateTime.now().difference(_startTime).inSeconds;
    widget.onQuizFinished(timeElapsed, _correctAnswers, _wrongAnswers);
    _showFinishedDialog(timeElapsed);
  }

  void _showFinishedDialog(int timeElapsed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Tamamlandı! 🎉"),
        content: Text("Doğru: $_correctAnswers\nYanlış: $_wrongAnswers\nSüre: $timeElapsed sn"),
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
            
            GestureDetector(
              onTap: _speakCurrentWord,
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
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                        child: Text(_currentWord.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            
            ..._options.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value;
              
              bool isCorrect = option == _currentWord.meanings.first;
              bool isWrongTapped = _selectedWrongOptions.contains(option); 
              
              Color btnColor = Colors.purple.shade100;
              Widget? suffixIcon;
              double scaleValue = 1.0; 

              if (_isCorrectlyAnswered && isCorrect) {
                btnColor = Colors.green.shade200;
                suffixIcon = const Icon(Icons.check, color: Colors.green);
                scaleValue = 1.05; 
              } else if (isWrongTapped) {
                btnColor = Colors.red.shade200;
                suffixIcon = const Icon(Icons.close, color: Colors.red);
              }

              final curve = CurvedAnimation(
                parent: _entranceController,
                curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutBack),
              );

              return AnimatedBuilder(
                animation: Listenable.merge([_entranceController, _shakeController]),
                builder: (context, child) {
                  double shakeOffset = 0;
                  if (isWrongTapped && _shakeController.isAnimating) {
                    shakeOffset = sin(_shakeController.value * pi * 4) * 8; 
                  }

                  return Transform.translate(
                    offset: Offset(shakeOffset, 50 * (1 - curve.value)),
                    child: Opacity(
                      opacity: curve.value.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () => _handleOptionTap(option),
                          child: AnimatedScale(
                            scale: scaleValue,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: btnColor, 
                                borderRadius: BorderRadius.circular(12), 
                                border: Border.all(color: Colors.purple.shade300),
                                boxShadow: scaleValue > 1.0 ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(option, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                                  if (suffixIcon != null) suffixIcon,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
