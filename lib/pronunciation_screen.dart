import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'main.dart';
import 'core/db_helper.dart';

class PronunciationScreen extends StatefulWidget {
  final List<WordModel> words;
  final bool isWordNet; // YENİ: WordNet Çifte Bonus Kontrolü
  final Function(int pointsEarned) onGameFinished;

  const PronunciationScreen({
    super.key,
    required this.words,
    required this.isWordNet,
    required this.onGameFinished,
  });

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeechInitialized = false;
  bool _isLoading = true; 
  String _text = 'Mikrofona basılı tut ve kelimeyi oku...';
  
  List<WordModel> gameWords = [];
  late WordModel currentWord;
  int currentIndex = 0;
  int score = 0;
  bool isFinished = false;
  bool _isSuccessAnim = false;
  
  int _currentWordMistakes = 0; 

  late AnimationController _pulseController;

  // YENİ: Combo ve Detaylı Puan Takip Sistemi
  int _combo = 0;
  int _normalTP = 0;
  int _wordNetNormalBonus = 0;
  int _comboTP = 0;
  int _wordNetComboBonus = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech(); 
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: false);
    _prepareGame();
  }

  Future<void> _prepareGame() async {
    List<WordModel> pool = List.from(widget.words);
    
    if (pool.length < 10) {
      int dbCount = await isar.wordModels.count();
      if (dbCount > 0) {
        int needed = 10 - pool.length;
        final random = Random();
        for (int i = 0; i < needed; i++) {
          int offset = random.nextInt(dbCount);
          var rw = await isar.wordModels.where().offset(offset).findFirst();
          if (rw != null && !pool.any((w) => w.word == rw.word)) {
            pool.add(rw);
          }
        }
      }
    }

    pool.shuffle();
    gameWords = pool.take(min(10, pool.length)).toList(); 

    if (gameWords.isNotEmpty) {
      setState(() {
        currentWord = gameWords[currentIndex];
        _isLoading = false;
      });
    } else {
      setState(() {
        isFinished = true;
        _isLoading = false;
      });
    }
  }

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

  String _getTargetWord() {
    String targetWord = currentWord.word;
    if (RegExp(r'^\d{8}-').hasMatch(targetWord) || targetWord.contains('[ID:')) {
        targetWord = currentWord.synonyms.isNotEmpty ? currentWord.synonyms.first : (currentWord.meanings.isNotEmpty ? currentWord.meanings.first : "word");
    }
    return targetWord.replaceAll(RegExp(r'\[.*?\]'), '').replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'[\[\]\{\}\\|_»•:;*+><=~]'), '').trim();
  }

  // YUKARI KAYAN COMBO EFEKTİ
  void _showComboAnimation(int multiplier, int tp) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 2500),
        curve: Curves.easeOutQuart,
        onEnd: () => overlayEntry?.remove(),
        builder: (context, value, child) {
          double opacity = 1.0;
          if (value < 0.1) opacity = value * 10;
          else if (value > 0.7) opacity = (1.0 - value) * 3.33;

          double topOffset = 100.0 - (value * 80.0);

          return Positioned(
            top: MediaQuery.of(context).padding.top + topOffset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.orangeAccent, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 15, spreadRadius: 3),
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "COMBO ${multiplier}X", 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.orangeAccent, shadows: [Shadow(color: Colors.red, blurRadius: 15)], decoration: TextDecoration.none, fontFamily: 'sans-serif', letterSpacing: 1.5)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "+$tp TP", 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.lightBlueAccent, shadows: [Shadow(color: Colors.blue, blurRadius: 10)], decoration: TextDecoration.none, fontFamily: 'sans-serif')
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      )
    );
    Overlay.of(context).insert(overlayEntry);
    HapticFeedback.vibrate();
  }

  // YENİ: SABİT, CANLI VE NEON COMBO ROZETİ (Üst Bar İçin)
  Widget _buildLiveComboBadge() {
    if (_combo < 2) return const SizedBox.shrink(); 
    
    Color comboColor = Colors.orangeAccent;
    double blur = 8.0;
    if (_combo >= 15) {
      comboColor = Colors.pinkAccent;
      blur = 20.0;
    } else if (_combo >= 10) {
      comboColor = Colors.redAccent;
      blur = 16.0;
    } else if (_combo >= 5) {
      comboColor = Colors.deepOrangeAccent;
      blur = 12.0;
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(_combo), 
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (sin(value * pi) * 0.15), 
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: comboColor, width: 1.5),
              boxShadow: [
                BoxShadow(color: comboColor.withOpacity(0.6 * value), blurRadius: blur, spreadRadius: 1)
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: comboColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  "COMBO ${_combo}X", 
                  style: TextStyle(color: comboColor, fontWeight: FontWeight.w900, fontSize: 12, shadows: [Shadow(color: comboColor, blurRadius: blur)])
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        setState(() => _text = "Mikrofon izni gerekli!");
        return;
      }

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
      
      if (!_isSuccessAnim && _text != 'Mikrofona basılı tut ve kelimeyi oku...' && _text != "Dinleniyor, konuşmaya başla...") {
         setState(() {
            _combo = 0; 
            _currentWordMistakes++;
            int penalty = _currentWordMistakes * 3; 
            score -= penalty;
            _text = "Hatalı Telaffuz! (-$penalty TP)\nOkunan: '$_text'";
            HapticFeedback.heavyImpact();
         });
      } else if (!_isSuccessAnim) {
         setState(() {
            _text = 'Mikrofona basılı tut ve kelimeyi oku...';
         });
      }
    }
  }

  void _checkPronunciation(String spokenWords) {
    String cleanSpoken = spokenWords.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');
    String cleanTarget = _getTargetWord().toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '');

    if (cleanSpoken.contains(cleanTarget) || cleanTarget.contains(cleanSpoken)) {
      _speech.stop();
      HapticFeedback.heavyImpact();
      setState(() {
        _isListening = false;
        _isSuccessAnim = true;
        
        if (_currentWordMistakes == 0) {
           _combo++;
           int multiplier = 1;
           if (_combo == 3) multiplier = 3;
           else if (_combo == 5) multiplier = 5;
           else if (_combo >= 10 && _combo % 5 == 0) multiplier = _combo; 
           
           int baseReward = 15;
           int earnedNormal = baseReward;
           int earnedCombo = (baseReward * multiplier) - baseReward;
           
           _normalTP += earnedNormal;
           _comboTP += earnedCombo;
           
           if (widget.isWordNet) {
              _wordNetNormalBonus += earnedNormal;
              _wordNetComboBonus += earnedCombo;
           }
           
           int totalEarnedThisMatch = (earnedNormal + earnedCombo) * (widget.isWordNet ? 2 : 1);
           score += totalEarnedThisMatch;
           
           if (multiplier > 1) {
              _showComboAnimation(multiplier, totalEarnedThisMatch);
           }
        } else {
           _combo = 0;
        }
        
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
        _currentWordMistakes = 0; 
        _text = 'Mikrofona basılı tut ve kelimeyi oku...';
      });
    } else {
      setState(() {
        isFinished = true;
      });
      widget.onGameFinished(score > 0 ? score : 0);
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
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text("Telaffuz Sınavı", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0), body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)));
    }

    if (widget.words.isEmpty && gameWords.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Telaffuz Sınavı")), body: const Center(child: Text("Sistemde oynamak için yeterli kelime bulunamadı.")));
    }

    if (isFinished) {
      int finalPoints = score > 0 ? score : 0; 
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Normal TP:", style: TextStyle(fontSize: 16)), Text("+$_normalTP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]),
                        if (widget.isWordNet)
                          Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("WordNet Bonusu:", style: TextStyle(fontSize: 16, color: Colors.indigo)), Text("+$_wordNetNormalBonus", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent))])),
                        if (_comboTP > 0)
                          Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Combo Ödülü:", style: TextStyle(fontSize: 16, color: Colors.orange)), Text("+$_comboTP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent))])),
                        if (widget.isWordNet && _wordNetComboBonus > 0)
                          Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("WordNet Combo:", style: TextStyle(fontSize: 16, color: Colors.deepPurple)), Text("+$_wordNetComboBonus", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))])),
                        
                        const Divider(height: 30),
                        const Text("Toplam Kazanılan Tayf Puanı", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.diamond, color: finalPoints > 0 ? Colors.green : Colors.redAccent, size: 36),
                            const SizedBox(width: 12),
                            Text(finalPoints > 0 ? "+$finalPoints" : "0", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: finalPoints > 0 ? Colors.green : Colors.redAccent)),
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
                      icon: const Icon(Icons.refresh, size: 24),
                      label: const Text("YENİDEN OYNA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          isFinished = false;
                          currentIndex = 0;
                          score = 0;
                          _currentWordMistakes = 0;
                          _combo = 0; _normalTP = 0; _wordNetNormalBonus = 0; _comboTP = 0; _wordNetComboBonus = 0;
                          _isLoading = true;
                          _prepareGame();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
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

    String targetWordDisplay = _getTargetWord();

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
              child: Text("Skor: $score", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: score < 0 ? Colors.redAccent.shade100 : Colors.white)),
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
                // DÜZELTİLDİ: FittedBox ve Combo Rozeti eklendi, taşma önlendi
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_combo >= 2) _buildLiveComboBadge(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Text("Kelime: ${currentIndex + 1} / ${gameWords.length}", style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ]
                  )
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
                    targetWordDisplay, 
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
                        color: _isSuccessAnim ? Colors.green : (_isListening ? Theme.of(context).primaryColor : Colors.redAccent)
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
