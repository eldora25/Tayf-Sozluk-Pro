import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'main.dart'; 

class MatchGameScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(int pointsEarned) onGameFinished;

  const MatchGameScreen({
    super.key,
    required this.words,
    required this.onGameFinished,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> with TickerProviderStateMixin {
  List<WordModel> gameWords = [];
  List<WordModel> leftColumn = [];
  List<WordModel> rightColumn = [];
  Set<String> matchedWords = {};
  String? wrongTargetWord;

  int currentRound = 0;
  int totalRounds = 0;
  bool isGameFinished = false;
  int score = 0;
  int mistakes = 0;
  bool _isLoading = true; 
  
  bool isDragging = false; 
  
  final ValueNotifier<bool> _isHoveringTarget = ValueNotifier(false);
  final Random _random = Random();
  
  Map<String, String> _targetDisplays = {};
  
  // YENİ: Artan ceza sistemi için hata kayıt defteri
  Map<String, int> _wordMistakeCounts = {}; 

  @override
  void initState() {
    super.initState();
    _prepareGame();
  }
  
  @override
  void dispose() {
    _isHoveringTarget.dispose();
    super.dispose();
  }

  Future<void> _prepareGame() async {
    List<WordModel> pool = List.from(widget.words);
    
    if (pool.length < 15) {
      int dbCount = await isar.wordModels.count();
      if (dbCount > 0) {
        int needed = 15 - pool.length;
        for (int i = 0; i < needed; i++) {
          int randomOffset = _random.nextInt(dbCount);
          WordModel? randomWord = await isar.wordModels.where().offset(randomOffset).findFirst();
          if (randomWord != null && !pool.any((w) => w.word == randomWord.word)) {
            pool.add(randomWord);
          }
        }
      }
    }

    pool.shuffle();
    gameWords = pool.take(min(15, pool.length)).toList();
    totalRounds = (gameWords.length / 5).ceil();

    if (gameWords.isEmpty) {
      setState(() {
        isGameFinished = true;
        _isLoading = false;
      });
      return;
    }

    _loadRound();
  }

  void _loadRound() {
    if (currentRound >= totalRounds) {
      setState(() {
        isGameFinished = true;
      });
      
      // Toplam kazanç eksi puana düşerse 0'da tut. 
      int finalPoints = score > 0 ? score : 0;
      widget.onGameFinished(finalPoints);
      return;
    }

    int start = currentRound * 5;
    int end = min(start + 5, gameWords.length);
    List<WordModel> roundWords = gameWords.sublist(start, end);

    leftColumn = List.from(roundWords)..shuffle();
    rightColumn = List.from(roundWords)..shuffle();
    matchedWords.clear();
    isDragging = false;
    _isHoveringTarget.value = false;
    
    _targetDisplays.clear();
    for (var w in rightColumn) {
       bool isWordNet = w.pos.isNotEmpty || w.synonyms.isNotEmpty || w.antonyms.isNotEmpty;
       if (isWordNet) {
          List<int> validOptions = [];
          if (w.synonyms.isNotEmpty) validOptions.add(0);
          if (w.antonyms.isNotEmpty) validOptions.add(1);
          if (w.meanings.isNotEmpty) validOptions.add(2);
          
          if (validOptions.isEmpty) {
            _targetDisplays[w.word] = "Kayıt Boş";
          } else {
            int selected = validOptions[_random.nextInt(validOptions.length)];
            if (selected == 0) _targetDisplays[w.word] = "Eş Anlam:\n${w.synonyms.first}";
            else if (selected == 1) _targetDisplays[w.word] = "Zıt Anlam:\n${w.antonyms.first}";
            else _targetDisplays[w.word] = "Tanım:\n${w.meanings.first}";
          }
       } else {
          _targetDisplays[w.word] = w.meanings.join(', ');
       }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _handleDrop(WordModel dragged, WordModel target) {
    _isHoveringTarget.value = false;
    setState(() => isDragging = false);
    
    if (dragged.word == target.word) {
      HapticFeedback.mediumImpact();
      setState(() {
        matchedWords.add(dragged.word);
        
        // YENİ ANTİ-SPAM: Sadece sıfır hatayla bulunursa puan ver
        int previousMistakes = _wordMistakeCounts[target.word] ?? 0;
        if (previousMistakes == 0) {
          score += 10;
        }
      });

      if (matchedWords.length == leftColumn.length) {
        currentRound++;
        Future.delayed(const Duration(milliseconds: 600), _loadRound);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        wrongTargetWord = target.word;
        mistakes++;
        
        // YENİ ARTAN CEZA SİSTEMİ
        int currentMistakeCount = (_wordMistakeCounts[target.word] ?? 0) + 1;
        _wordMistakeCounts[target.word] = currentMistakeCount;
        
        int penalty = currentMistakeCount * 5; // 1. hata -5, 2. hata -10, 3. hata -15
        score -= penalty; 
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            wrongTargetWord = null;
          });
        }
      });
    }
  }

  Widget _buildStaggeredItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lexis Eldora | Eşleştirme"), elevation: 0),
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    if (gameWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lexis Eldora | Eşleştirme"), elevation: 0),
        body: const Center(child: Text("Sistemde oynamak için yeterli kelime bulunamadı.")),
      );
    }

    if (isGameFinished) {
      int finalPoints = score > 0 ? score : 0; // Negatif puana düştüyse sıfırla

      return Scaffold(
        appBar: AppBar(title: const Text("Oyun Bitti", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Mükemmel Eşleşme! 🎉", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 10),
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', 
                    height: 180,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events, size: 100, color: Colors.amber), 
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Ham Skor:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text("$score", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: score < 0 ? Colors.red : Colors.blue)),
                          ]),
                          const Divider(height: 30),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Hatalı Sürükleme:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text("$mistakes", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          ]),
                          const Divider(height: 30),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Kazanılan Tayf Puanı:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Icon(Icons.diamond, color: finalPoints > 0 ? Colors.green : Colors.redAccent, size: 28),
                                const SizedBox(width: 8),
                                Text(finalPoints > 0 ? "+$finalPoints" : "0", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: finalPoints > 0 ? Colors.green : Colors.redAccent)),
                              ],
                            ),
                          ]),
                        ],
                      ),
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
                          isGameFinished = false;
                          currentRound = 0;
                          score = 0;
                          mistakes = 0;
                          _wordMistakeCounts.clear();
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
                      label: const Text("ANA EKRANA DÖN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
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
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Lexis Eldora | Eşleştirme", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent, 
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Theme.of(context).primaryColor.withOpacity(0.8)),
          ),
        ),
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
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.1), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            padding: const EdgeInsets.only(top: 100, bottom: 16.0, left: 8.0, right: 8.0), 
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Text("Raunt: ${currentRound + 1} / $totalRounds", style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 8),
                Text("Cevabın üzerindeyken okumak için bekleyin.", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: leftColumn.asMap().entries.map((entry) {
                            int idx = entry.key;
                            WordModel word = entry.value;
                            bool isMatched = matchedWords.contains(word.word);
                            
                            if (isMatched) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                height: 70,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.5), width: 2)),
                                child: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 36)),
                              );
                            }
                            return _buildStaggeredItem(
                              idx, 
                              Draggable<WordModel>(
                                data: word,
                                onDragStarted: () => setState(() => isDragging = true),
                                onDragEnd: (details) {
                                  _isHoveringTarget.value = false;
                                  setState(() => isDragging = false);
                                },
                                onDraggableCanceled: (v, o) {
                                  _isHoveringTarget.value = false;
                                  setState(() => isDragging = false);
                                },
                                feedback: ValueListenableBuilder<bool>(
                                  valueListenable: _isHoveringTarget,
                                  builder: (context, isHovering, child) {
                                    return Opacity(
                                      opacity: isHovering ? 0.0 : 0.9, 
                                      child: child,
                                    );
                                  },
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.42,
                                      height: 75,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(20), 
                                        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10))]
                                      ),
                                      child: Center(
                                        child: SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(
                                  height: 70,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid, width: 2)),
                                ),
                                child: Container(
                                  height: 70,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.9), Theme.of(context).primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  ),
                                  child: Center(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            );
                          }).toList(),
                        ),
                      ),
                      
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: rightColumn.asMap().entries.map((entry) {
                            int idx = entry.key;
                            WordModel word = entry.value;
                            bool isMatched = matchedWords.contains(word.word);
                            
                            if (isMatched) {
                               return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                height: 70,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.5), width: 2)),
                                child: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 36)),
                              );
                            }
                            
                            bool isWrong = wrongTargetWord == word.word;
                            
                            return _buildStaggeredItem(
                              idx, 
                              DragTarget<WordModel>(
                                onWillAccept: (data) {
                                  _isHoveringTarget.value = true;
                                  return true;
                                },
                                onLeave: (data) {
                                  _isHoveringTarget.value = false;
                                },
                                onAccept: (data) {
                                  _isHoveringTarget.value = false;
                                  _handleDrop(data, word);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  bool isHovered = candidateData.isNotEmpty;
                                  
                                  double dynamicHeight = 70.0;
                                  Matrix4 transformMatrix = Matrix4.identity();
                                  
                                  if (isHovered) {
                                    dynamicHeight = 160.0;
                                    transformMatrix.translate(0.0, -30.0, 0.0); 
                                    transformMatrix.scale(1.05); 
                                  } else if (isDragging) {
                                    dynamicHeight = 90.0;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeOutBack,
                                          height: dynamicHeight, 
                                          transform: transformMatrix,
                                          transformAlignment: Alignment.center,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isWrong 
                                                ? Colors.redAccent.withOpacity(0.9)
                                                : (isHovered ? Colors.orangeAccent.withOpacity(0.95) : Theme.of(context).cardColor),
                                            border: Border.all(
                                              color: isWrong ? Colors.red : (isHovered ? Colors.orange : Colors.grey.withOpacity(0.3)),
                                              width: isHovered || isWrong ? 3 : 1
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: isHovered || isWrong 
                                                ? [BoxShadow(color: isWrong ? Colors.red.withOpacity(0.6) : Colors.orange.withOpacity(0.6), blurRadius: 20, spreadRadius: 4)] 
                                                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
                                          ),
                                          child: Center(
                                            child: SingleChildScrollView(
                                              physics: const BouncingScrollPhysics(),
                                              child: Text(
                                                _targetDisplays[word.word] ?? word.meanings.join(', '), 
                                                textAlign: TextAlign.center, 
                                                style: TextStyle(
                                                  color: isWrong || isHovered ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                                  fontSize: isHovered ? 14 : 12, 
                                                  fontWeight: FontWeight.bold
                                                )
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
