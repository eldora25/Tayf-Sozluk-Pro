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

class _PronunciationScreenState extends State<PronunciationScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeechInitialized = false; // YENİ: Başlatılma kontrolü
  String _text = 'Mikrofona basılı tut ve kelimeyi oku...';
  
  List<WordModel> gameWords = [];
  late WordModel currentWord;
  int currentIndex = 0;
  int score = 0;
  bool isFinished = false;
  bool _isSuccessAnim = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech(); // YENİ: Sayfa açıldığında bir kez başlatılır
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: false);

    List<WordModel> pool = List.from(widget.words)..shuffle();
    gameWords = pool.take(min(10, pool.length)).toList(); 

    if (gameWords.isNotEmpty) {
      currentWord = gameWords[currentIndex];
    } else {
      isFinished = true;
    }
  }

  // YENİ: Motoru sadece bir kez başlatan güvenli fonksiyon
  Future<void> _initSpeech() async {
    _isSpeechInitialized = await _speech.initialize(
      onStatus: (val) => debugPrint('onStatus: $val'),
      onError: (val) => debugPrint('onError: $val'),
    );
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

      // Eğer daha önce başlatılamadıysa tekrar dene
      if (!_isSpeechInitialized) {
        await _initSpeech();
      }

      if (_isSpeechInitialized) {
        setState(() {
          _isListening = true;
          _isSuccessAnim = false;
          _text = "Dinleniyor, konuşmaya başla...";
        });
        HapticFeedback.lightImpact();
        
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
      } else {
         setState(() => _text = "Mikrofon başlatılamadı!");
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _checkPronunciation(String spokenWords) {
    String cleanSpoken = spokenWords.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');
    String cleanTarget = currentWord.word.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');

    if (cleanSpoken.contains(cleanTarget) || cleanTarget.contains(cleanSpoken)) {
      _speech.stop();
      HapticFeedback.heavyImpact();
      setState(() {
        _isListening = false;
        _isSuccessAnim = true;
        score += 15; 
        _text = "Mükemmel Telaffuz! 👏";
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _nextWord();
      });
    }
  }

  void _nextWord() {
    if (currentIndex < gameWords.length - 1) {
      setState(() {
        currentIndex++;
        currentWord = gameWords[currentIndex];
        _isSuccessAnim = false;
        _text = 'Mikrofona basılı tut ve kelimeyi oku...';
      });
    } else {
      setState(() {
        isFinished = true;
      });
      widget.onGameFinished(score);
    }
  }

  Widget _buildRippleEffect() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (_isListening) ...[
              Container(
                width: 80 + (_pulseController.value * 60),
                height: 80 + (_pulseController.value * 60),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(1.0 - _pulseController.value)),
              ),
              Container(
                width: 80 + ((_pulseController.value - 0.2).clamp(0.0, 1.0) * 80),
                height: 80 + ((_pulseController.value - 0.2).clamp(0.0, 1.0) * 80),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.5 - (_pulseController.value * 0.5).clamp(0.0, 0.5))),
              ),
            ],
            FloatingActionButton(
              backgroundColor: _isListening ? Colors.redAccent : Theme.of(context).primaryColor,
              elevation: _isListening ? 10 : 4,
              onPressed: () {}, 
              child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 32, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Telaffuz Sınavı")), body: const Center(child: Text("Yeterli kelime yok.")));
    }

    if (isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sınav Bitti", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Harika Konuştun! 🎙️", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  Lottie.network('https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', height: 180, repeat: true),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Column(
                      children: [
                        const Text("Kazanılan Tayf Puanı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond, color: Colors.green, size: 36),
                            const SizedBox(width: 12),
                            Text("+$score", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(18), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      icon: const Icon(Icons.home, size: 24),
                      label: const Text("ANA EKRANA DÖN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Telaffuz Pratiği 🎤", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text("Skor: $score", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Text("Kelime: ${currentIndex + 1} / ${gameWords.length}", style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 40),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: _isSuccessAnim ? Colors.green : Theme.of(context).cardColor, 
                    borderRadius: BorderRadius.circular(24), 
                    border: Border.all(color: _isSuccessAnim ? Colors.green : Theme.of(context).primaryColor.withOpacity(0.3), width: 2), 
                    boxShadow: [BoxShadow(color: _isSuccessAnim ? Colors.green.withOpacity(0.4) : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: 2)]
                  ),
                  transform: Matrix4.identity()..scale(_isSuccessAnim ? 1.05 : 1.0),
                  alignment: Alignment.center,
                  child: Text(
                    currentWord.word, 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _isSuccessAnim ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: 1.5)
                  ),
                ),
                
                const SizedBox(height: 50),
                const Text("Canlı Algılama:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 100),
                  decoration: BoxDecoration(
                    color: _isSuccessAnim ? Colors.green.withOpacity(0.1) : (_isListening ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05)), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isSuccessAnim ? Colors.green.withOpacity(0.5) : (_isListening ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.transparent), width: 1.5)
                  ),
                  child: Center(
                    child: Text(
                      _text, 
                      textAlign: TextAlign.center, 
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: _isListening ? FontWeight.normal : FontWeight.bold, 
                        color: _isSuccessAnim ? Colors.green : (_isListening ? Theme.of(context).primaryColor : Colors.grey.shade600)
                      )
                    ),
                  ),
                ),
                const Spacer(),
                const Text("Aşağıdaki butona basılı tut ve yukarıdaki kelimeyi İngilizce olarak sesli oku.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
                const SizedBox(height: 100), 
              ],
            ),
          ),
          
          Positioned(
            bottom: 30 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTapDown: (_) => _listen(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: () => _stopListening(),
              child: _buildRippleEffect(),
            ),
          )
        ],
      ),
    );
  }
}
