import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'models.dart';

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

  @override
  void initState() {
    super.initState();
    _prepareGame();
  }

  void _prepareGame() {
    List<WordModel> pool = List.from(widget.words)..shuffle();
    gameWords = pool.take(min(15, pool.length)).toList();
    totalRounds = (gameWords.length / 5).ceil();

    if (gameWords.isEmpty) {
      isGameFinished = true;
      return;
    }

    _loadRound();
  }

  void _loadRound() {
    if (currentRound >= totalRounds) {
      setState(() {
        isGameFinished = true;
      });
      // DÜZELTİLDİ: Oyun zorlaştırıldı, hatasızlara en az 5, hatalılara sıfıra kadar inen TP sistemi.
      int earnedPoints = (gameWords.length * 3) - (mistakes * 3);
      if (earnedPoints < 0) earnedPoints = 0; 
      if (earnedPoints < 5 && mistakes == 0) earnedPoints = 5; 
      widget.onGameFinished(earnedPoints);
      return;
    }

    int start = currentRound * 5;
    int end = min(start + 5, gameWords.length);
    List<WordModel> roundWords = gameWords.sublist(start, end);

    leftColumn = List.from(roundWords)..shuffle();
    rightColumn = List.from(roundWords)..shuffle();
    matchedWords.clear();

    setState(() {});
  }

  void _handleDrop(WordModel dragged, WordModel target) {
    if (dragged.word == target.word) {
      HapticFeedback.mediumImpact();
      setState(() {
        matchedWords.add(dragged.word);
        score += 10;
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
        score -= 5; // YENİ: Hata yaptıkça Eksi Skor (-5) yazar
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
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lexis Eldora | Eşleştirme"), elevation: 0),
        body: const Center(child: Text("Oynamak için yeterli kelime yok.")),
      );
    }

    if (isGameFinished) {
      int finalPoints = (gameWords.length * 3) - (mistakes * 3);
      if (finalPoints < 0) finalPoints = 0;
      if (finalPoints < 5 && mistakes == 0) finalPoints = 5;

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
                            const Text("Oyun Skoru:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                                const Icon(Icons.diamond, color: Colors.green, size: 28),
                                const SizedBox(width: 8),
                                Text("+$finalPoints", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
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
                                feedback: Material(
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
                                    child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                                  child: Text(word.word, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                                onWillAccept: (data) => true, 
                                onAccept: (data) => _handleDrop(data, word),
                                builder: (context, candidateData, rejectedData) {
                                  bool isHovered = candidateData.isNotEmpty;
                                  
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeOutBack,
                                          height: isHovered ? 120 : 70, 
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(12),
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
                                          child: Text(
                                            word.meanings.join(', '), 
                                            textAlign: TextAlign.center, 
                                            maxLines: isHovered ? 4 : 2, 
                                            overflow: TextOverflow.ellipsis, 
                                            style: TextStyle(
                                              color: isWrong || isHovered ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                              fontSize: isHovered ? 15 : 14, 
                                              fontWeight: FontWeight.bold
                                            )
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
