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

class _QuizScreenState extends State<QuizScreen> {
  final FlutterTts flutterTts = FlutterTts(); 
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  late WordModel _currentWord;
  late List<String> _options;
  
  // O anki soruda seçilen YANLIŞ şıkları tutacağımız liste
  Set<String> _selectedWrongOptions = {};
  
  bool _isCorrectlyAnswered = false; // Soru doğru bilindiğinde diğer şıklara tıklanmasını engeller
  late DateTime _startTime; // Quiz süresini tutmak için başlangıç zamanı

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Quiz başladı
    _generateQuestion();
  }

  void _generateQuestion() {
    _isCorrectlyAnswered = false;
    _selectedWrongOptions.clear(); // Yeni soruya geçildiğinde yanlışlar listesini temizle
    _currentWord = widget.words[Random().nextInt(widget.words.length)];
    
    String correctMeaning = _currentWord.meanings.first;
    Set<String> wrongOptions = {};
    
    // Yanlış şıkları rastgele diğer kelimelerden seç
    while (wrongOptions.length < 3) {
      var randomWord = widget.words[Random().nextInt(widget.words.length)];
      if (randomWord.word != _currentWord.word) {
        wrongOptions.add(randomWord.meanings.first);
      }
    }
    
    _options = [correctMeaning, ...wrongOptions];
    _options.shuffle();
  }

  void _handleOptionTap(String option) async {
    if (_isCorrectlyAnswered) return; // Zaten doğru bilindiyse bekleme süresinde tıklamaları engelle
    if (_selectedWrongOptions.contains(option)) return; // Daha önce basılan yanlış şıkka tekrar basılmasını engelle

    if (option == _currentWord.meanings.first) {
      // DOĞRU CEVAP
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

      // Doğru bilindikten sonra 1 saniye bekleyip diğer soruya geç
      Future.delayed(const Duration(seconds: 1), () {
        if (_currentIndex < widget.questionCount - 1) {
          setState(() { _currentIndex++; _generateQuestion(); });
        } else {
          _finishQuiz(); 
        }
      });
    } else {
      // YANLIŞ CEVAP
      setState(() {
        _selectedWrongOptions.add(option); // Şıkkı kırmızı yapmak için listeye ekle
        _wrongAnswers++;
        widget.onWrongWord(_currentWord); // Kelimenin yanlış sayısını veritabanında artırıp SRS seviyesini düşür
      });

      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("Wrong"); 
      
      // NOT: Burada bilerek diğer soruya geçmiyoruz (Future.delayed yok). 
      // Kullanıcı doğruyu bulana kadar süre işlemeye ve o soruda kalmaya devam edecek.
    }
  }

  void _finishQuiz() {
    // Süreyi saniye cinsinden hesapla
    int timeElapsed = DateTime.now().difference(_startTime).inSeconds;
    widget.onQuizFinished(timeElapsed, _correctAnswers, _wrongAnswers);
    _showFinishedDialog();
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
              bool isWrongTapped = _selectedWrongOptions.contains(option); // Bu şıkka daha önce yanlış olarak basıldı mı?
              
              Color btnColor = Colors.purple.shade100;
              Widget? suffixIcon;

              // Eğer doğru cevap bulunduysa ve bu şık doğru olansa yeşil yap
              if (_isCorrectlyAnswered && isCorrect) {
                btnColor = Colors.green.shade200;
                suffixIcon = const Icon(Icons.check, color: Colors.green);
              } 
              // Eğer bu şıkka daha önce basıldıysa ve yanlışsa kırmızı yap
              else if (isWrongTapped) {
                btnColor = Colors.red.shade200;
                suffixIcon = const Icon(Icons.close, color: Colors.red);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () => _handleOptionTap(option),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
