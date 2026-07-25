import 'dart:math';
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

class _MatchGameScreenState extends State<MatchGameScreen> {
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
    // 3 Rauntluk (Maksimum 15 kelime) bir oyun hazırlayalım
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
      // Kazanılan Tayf Puanı (TP) hesaplanır (Doğrular - Yanlışlar)
      int earnedPoints = (gameWords.length * 3) - (mistakes * 2);
      if (earnedPoints < 5) earnedPoints = 5; // En az 5 teselli puanı
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
      // DOĞRU EŞLEŞTİRME
      HapticFeedback.mediumImpact();
      setState(() {
        matchedWords.add(dragged.word);
        score += 10;
      });

      // Raunt bitti mi kontrol et
      if (matchedWords.length == leftColumn.length) {
        currentRound++;
        Future.delayed(const Duration(milliseconds: 600), _loadRound);
      }
    } else {
      // YANLIŞ EŞLEŞTİRME (Kırmızı Parlama ve Sarsıntı Titreşimi)
      HapticFeedback.heavyImpact();
      setState(() {
        wrongTargetWord = target.word;
        mistakes++;
        score -= 2;
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

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Eşleştirme Oyunu")),
        body: const Center(child: Text("Oynamak için yeterli kelime yok.")),
      );
    }

    if (isGameFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Oyun Bitti")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Mükemmel Eşleşme!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', 
                  height: 180,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => const Text("🧩", style: TextStyle(fontSize: 80)), 
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Oyun Skoru:", style: TextStyle(fontSize: 20)),
                          Text("$score", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Hatalı Sürükleme:", style: TextStyle(fontSize: 20)),
                          Text("$mistakes", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        ]),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Kazanılan 💎:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("+${(gameWords.length * 3) - (mistakes * 2) < 5 ? 5 : (gameWords.length * 3) - (mistakes * 2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    icon: const Icon(Icons.refresh),
                    label: const Text("TEKRAR OYNA", style: TextStyle(fontSize: 18)),
                    onPressed: () {
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
                    icon: const Icon(Icons.home),
                    label: const Text("ANA EKRANA DÖN", style: TextStyle(fontSize: 18)),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sürükle ve Eşleştir 🧩"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("Skor: $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text("Raunt: ${currentRound + 1} / $totalRounds", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  // SOL SÜTUN: İNGİLİZCE KELİMELER (SÜRÜKLENEBİLİR - DRAGGABLE)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: leftColumn.map((word) {
                        if (matchedWords.contains(word.word)) {
                          return const SizedBox(height: 70, child: Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40)));
                        }
                        return Draggable<WordModel>(
                          data: word,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 70,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
                              child: Text(word.word, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          childWhenDragging: Container(
                            height: 70,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Container(
                            height: 70,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))]
                            ),
                            child: Text(word.word, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // SAĞ SÜTUN: TÜRKÇE ANLAMLAR (HEDEF - DRAG TARGET)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: rightColumn.map((word) {
                        if (matchedWords.contains(word.word)) {
                           return const SizedBox(height: 70, child: Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40)));
                        }
                        
                        bool isWrong = wrongTargetWord == word.word;
                        
                        return DragTarget<WordModel>(
                          onWillAccept: (data) => true, // Her şeyi kabul et, sonucu onAccept'te değerlendir
                          onAccept: (data) => _handleDrop(data, word),
                          builder: (context, candidateData, rejectedData) {
                            bool isHovered = candidateData.isNotEmpty;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 70,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isWrong 
                                    ? Colors.redAccent 
                                    : (isHovered ? Colors.orangeAccent : Theme.of(context).cardColor),
                                border: Border.all(
                                  color: isWrong ? Colors.red : (isHovered ? Colors.orange : Theme.of(context).primaryColor),
                                  width: isHovered || isWrong ? 3 : 1
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))]
                              ),
                              child: Text(word.meanings.first, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(
                                color: isWrong || isHovered ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 14, fontWeight: FontWeight.bold
                              )),
                            );
                          },
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
    );
  }
}
