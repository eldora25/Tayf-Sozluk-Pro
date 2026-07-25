import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'models.dart';

class PronunciationScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(int pointsEarned) onGameFinished;

  const PronunciationScreen({
    super.key,
    required this.words,
    required this.onGameFinished,
  });

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Mikrofona bas ve kelimeyi oku...';
  
  List<WordModel> gameWords = [];
  late WordModel currentWord;
  int currentIndex = 0;
  int score = 0;
  bool isFinished = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    List<WordModel> pool = List.from(widget.words)..shuffle();
    gameWords = pool.take(min(10, pool.length)).toList(); // 10 Kelimelik konuşma testi

    if (gameWords.isNotEmpty) {
      currentWord = gameWords[currentIndex];
    } else {
      isFinished = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        setState(() => _text = "Mikrofon izni gerekli!");
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = "Dinleniyor...";
        });
        HapticFeedback.lightImpact();
        
        // Sadece İngilizce dinlemesi için ayar
        _speech.listen(
          localeId: 'en_US',
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (val.hasConfidenceRating && val.confidence > 0) {
              _checkPronunciation(val.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _checkPronunciation(String spokenWords) {
    String cleanSpoken = spokenWords.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');
    String cleanTarget = currentWord.word.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');

    if (cleanSpoken.contains(cleanTarget) || cleanTarget.contains(cleanSpoken)) {
      _speech.stop();
      HapticFeedback.mediumImpact();
      setState(() {
        _isListening = false;
        score += 15; // Telaffuz zor olduğu için daha fazla puan
        _text = "Mükemmel Telaffuz! 👏";
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _nextWord();
      });
    }
  }

  void _nextWord() {
    if (currentIndex < gameWords.length - 1) {
      setState(() {
        currentIndex++;
        currentWord = gameWords[currentIndex];
        _text = 'Mikrofona bas ve kelimeyi oku...';
      });
    } else {
      setState(() {
        isFinished = true;
      });
      widget.onGameFinished(score);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Telaffuz Sınavı")), body: const Center(child: Text("Yeterli kelime yok.")));
    }

    if (isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sınav Bitti")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Harika Konuştun!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              Lottie.network('https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', height: 180, repeat: true),
              const SizedBox(height: 20),
              Text("Kazanılan 💎: $score", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                icon: const Icon(Icons.home),
                label: const Text("Ana Ekrana Dön"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Telaffuz Pratiği 🎤"),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("Skor: $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _listen(),
        onTapUp: (_) => _speech.stop(),
        onTapCancel: () => _speech.stop(),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? 1.0 + (_pulseController.value * 0.2) : 1.0,
              child: FloatingActionButton(
                backgroundColor: _isListening ? Colors.redAccent : Theme.of(context).primaryColor,
                onPressed: _listen,
                child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Kelime: ${currentIndex + 1} / ${gameWords.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).primaryColor, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Text(currentWord.word, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            const Text("Söylediklerin:", style: TextStyle(fontSize: 18, color: Colors.blueAccent)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(_text, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: _isListening ? FontWeight.normal : FontWeight.bold, color: _text.contains("Mükemmel") ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            const Spacer(),
            const Text("Mikrofona dokun ve yukarıdaki İngilizce kelimeyi sesli olarak oku.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
