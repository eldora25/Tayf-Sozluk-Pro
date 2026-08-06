import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'models.dart';

class StatisticsScreen extends StatelessWidget {
  final List<WordModel> allWords;
  final List<WordModel> learningWords; 
  final List<WordModel> toRepeatWords; 
  final List<WordModel> toSRSRepeatWords;
  final List<WordModel> learnedWords;
  final List<WordModel> wrongWords;
  final List<String> availableLibraries;
  
  final int totalCompletedQuizzes;
  final int totalQuizTimeSeconds;
  final int totalQuizQuestions;
  final int totalQuizWrong;

  final List<String> learnedWordTimestamps;
  final List<String> completedQuizTimestamps;
  final List<String> viewedCardTimestamps;
  final List<String> wrongAnswerTimestamps;
  final int firstUseTimestamp;

  final int bestStreak;
  final int tayfPoints;

  final int bestQuizTime;
  final int bestQuizCorrect;
  final String bestQuizDate;

  const StatisticsScreen({
    super.key,
    required this.allWords,
    required this.learningWords,
    required this.toRepeatWords,
    required this.toSRSRepeatWords,
    required this.learnedWords,
    required this.wrongWords,
    required this.availableLibraries,
    required this.totalCompletedQuizzes,
    required this.totalQuizTimeSeconds,
    required this.totalQuizQuestions,
    required this.totalQuizWrong,
    required this.learnedWordTimestamps,
    required this.completedQuizTimestamps,
    required this.viewedCardTimestamps,
    required this.wrongAnswerTimestamps,
    required this.firstUseTimestamp,
    required this.bestStreak,
    required this.tayfPoints,
    required this.bestQuizTime,
    required this.bestQuizCorrect,
    required this.bestQuizDate,
  });

  String _formatTime(int seconds) {
    int d = seconds ~/ (24 * 3600);
    int h = (seconds % (24 * 3600)) ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${d > 0 ? d.toString().padLeft(2, '0') + ':' : ''}${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int _countInPeriod(List<String> timestamps, Duration period) {
    final now = DateTime.now();
    return timestamps.where((ts) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      return now.difference(date) <= period;
    }).length;
  }

  List<FlSpot> _getChartData(List<String> timestamps) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}; 

    for (var ts in timestamps) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      final itemDate = DateTime(date.year, date.month, date.day);
      final diff = today.difference(itemDate).inDays;
      if (diff >= 0 && diff <= 6) {
        counts[6 - diff] = (counts[6 - diff] ?? 0) + 1;
      }
    }

    return counts.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
  }

  Widget _buildAnimatedNumber(int number, TextStyle style) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: number),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(value.toString(), style: style);
      },
    );
  }

  Widget _buildStaggeredWrapper(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 10) * 80)),
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

  Widget _buildSpeedCard(BuildContext context, String title, Duration period, Color color) {
    int learned = _countInPeriod(learnedWordTimestamps, period);
    int quizzes = _countInPeriod(completedQuizTimestamps, period);
    int viewed = _countInPeriod(viewedCardTimestamps, period);
    int wrongs = _countInPeriod(wrongAnswerTimestamps, period);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.timeline, color: color, size: 20)),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Doğru Bilinen:", style: TextStyle(fontWeight: FontWeight.w500)), _buildAnimatedNumber(learned, const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tamamlanan Quiz:", style: TextStyle(fontWeight: FontWeight.w500)), _buildAnimatedNumber(quizzes, const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Bakılan Kart:", style: TextStyle(fontWeight: FontWeight.w500)), _buildAnimatedNumber(viewed, const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Yapılan Yanlış:", style: TextStyle(fontWeight: FontWeight.w500)), _buildAnimatedNumber(wrongs, const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16))]),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<int> milestones, int currentValue, IconData icon, Color earnedColor, String unit) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        int target = milestones[index];
        bool isEarned = currentValue >= target;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: isEarned ? LinearGradient(colors: [earnedColor.withOpacity(0.8), earnedColor], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: isEarned ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isEarned ? earnedColor : Colors.grey.withOpacity(0.2), width: 2),
            boxShadow: isEarned ? [BoxShadow(color: earnedColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isEarned ? icon : Icons.lock_outline, color: isEarned ? Colors.white : Colors.grey.withOpacity(0.5), size: 38),
              const SizedBox(height: 10),
              Text("$target", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isEarned ? Colors.white : Colors.grey)),
              Text(unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isEarned ? Colors.white70 : Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  void _showMitosisTreeModal(BuildContext context, List<MapEntry<String, int>> treeData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_tree, color: Colors.purpleAccent, size: 28),
                          const SizedBox(width: 10),
                          Text("Mitoz Bölünme Ağacı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Hangi kelimeden kaç adet saf kart üretildi?", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    Flexible(
                      child: treeData.isEmpty 
                        ? const Center(child: Text("Henüz bölünmüş kartınız yok.", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: treeData.length,
                            itemBuilder: (ctx, i) {
                              String word = treeData[i].key;
                              int count = treeData[i].value;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                                  boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.biotech, color: Colors.purpleAccent),
                                  ),
                                  title: Text(word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [Colors.purpleAccent.shade400, Colors.pinkAccent]),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text("$count Klon", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              );
                            }
                          )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMitosisCard(BuildContext context, int count, List<MapEntry<String, int>> treeData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purpleAccent.shade700, Colors.pinkAccent.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (count > 0) _showMitosisTreeModal(context, treeData);
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.biotech, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🧬 Mitoz Havuzu", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Quizlerde bölünerek saf, eşsiz ve tek anlamlı hale gelen toplam kart sayısı.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                      if (count > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                          child: const Text("Ağacı görmek için dokunun", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildAnimatedNumber(count, const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeitnerBoxCard(BuildContext context, String boxName, String title, int count, int totalCount, IconData icon, Color color) {
    double percent = totalCount > 0 ? (count / totalCount) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(boxName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                      Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAnimatedNumber(count, TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)),
                    Text("%${(percent * 100).toStringAsFixed(1)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.withOpacity(0.15),
                color: color,
                minHeight: 6,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DÜZELTİLDİ: Toplam istatistikler hesaplanırken tüm aktif listeler tek bir havuza alınır
    var allActiveWords = [
      ...allWords,
      ...learnedWords,
      ...learningWords,
      ...toRepeatWords,
      ...toSRSRepeatWords,
      ...wrongWords // Hata Düzeltildi: Yanlış kelimeler de kapsama eklendi
    ].toSet().toList();

    int totalSystemWords = allActiveWords.length;
    int totalWrongCount = allActiveWords.fold(0, (a, b) => a + b.wrongCount);
    int totalCorrectCount = allActiveWords.fold(0, (a, b) => a + b.correctCount);

    DateTime firstUse = DateTime.fromMillisecondsSinceEpoch(firstUseTimestamp);
    int daysUsed = DateTime.now().difference(firstUse).inDays;
    if (daysUsed < 1) daysUsed = 1; 
    
    double graduationSpeed = learnedWords.length / daysUsed; 
    double activitySpeed = learnedWordTimestamps.length / daysUsed; 

    double quizSpeed = totalQuizTimeSeconds > 0 ? (totalQuizQuestions / (totalQuizTimeSeconds / 60)) : 0.0;

    List<String> trueGraduationTimestamps = learnedWords.map((w) => w.nextReviewDate.toString()).toList();

    int totalMitosisCount = 0;
    Map<String, int> mitosisTree = {};

    for (var w in allActiveWords) {
      if (w.libraryName.startsWith('\u{1F9EC} Mitoz')) {
        totalMitosisCount++;
        mitosisTree[w.word] = (mitosisTree[w.word] ?? 0) + 1;
      }
    }
    
    var sortedMitosis = mitosisTree.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    int srs1Count = 0;
    int srs2Count = 0;
    int srs3Count = 0;
    int srs4Count = 0;
    int srs5Count = 0;

    Set<int> countedIds = {};

    for (var w in allActiveWords) {
      if (countedIds.contains(w.id)) continue;
      countedIds.add(w.id);
      
      if (w.srsLevel == 1) srs1Count++;
      else if (w.srsLevel == 2) srs2Count++;
      else if (w.srsLevel == 3) srs3Count++;
      else if (w.srsLevel == 4) srs4Count++;
      else if (w.srsLevel == 5) srs5Count++;
    }

    int masteredCount = learnedWords.length;
    int totalActiveSRS = srs1Count + srs2Count + srs3Count + srs4Count + srs5Count + masteredCount;
    double maxBarVal = [srs1Count, srs2Count, srs3Count, srs4Count, srs5Count, masteredCount].reduce(max).toDouble();

    final List<int> streakMilestones = [5, 7, 10, 15, 20, 30, 40, 50, 75, 100, 150, 200, 300];
    final List<int> wordMilestones = [5, 7, 10, 15, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 600, 700, 1000, 1500, 2000, 2500, 3000, 5000, 7000, 10000];
    
    final activityChartData = _getChartData(learnedWordTimestamps);
    final graduationChartData = _getChartData(trueGraduationTimestamps);
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 6, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Lexis Eldora | İstatistikler", style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Başarılar", icon: Icon(Icons.emoji_events)),
              Tab(text: "Genel Özet", icon: Icon(Icons.pie_chart)),
              Tab(text: "Leitner Kutusu", icon: Icon(Icons.inventory_2)),
              Tab(text: "Öğrenme Grafiği", icon: Icon(Icons.auto_graph)), 
              Tab(text: "Quiz", icon: Icon(Icons.psychology)),
              Tab(text: "Kütüphaneler", icon: Icon(Icons.library_books)),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStaggeredWrapper(0, Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 36), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text("Ateşli Seri Rozetleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)), Text("Uygulamaya aralıksız girerek kazanılır.", style: TextStyle(color: Colors.grey, fontSize: 12))]))]),
                  )),
                  const SizedBox(height: 20),
                  _buildStaggeredWrapper(1, _buildBadgeGrid(streakMilestones, bestStreak, Icons.local_fire_department, Colors.deepOrange, "Gün")),
                  const SizedBox(height: 40),
                  _buildStaggeredWrapper(2, Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [const Icon(Icons.military_tech, color: Colors.blue, size: 36), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text("Kelime Ustası Rozetleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), Text("Öğrenilen (Mezun) kelime sayısına göre kazanılır.", style: TextStyle(color: Colors.grey, fontSize: 12))]))]),
                  )),
                  const SizedBox(height: 20),
                  _buildStaggeredWrapper(3, _buildBadgeGrid(wordMilestones, learnedWords.length, Icons.military_tech, Colors.blue, "Kelime")),
                  const SizedBox(height: 40),
                ],
              ),

              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStaggeredWrapper(0, _buildMitosisCard(context, totalMitosisCount, sortedMitosis)), 
                  _buildStaggeredWrapper(1, _buildStatCard(context, "Mevcut Tayf Puan (TP)", tayfPoints, Icons.diamond, Colors.blueAccent)),
                  _buildStaggeredWrapper(2, _buildStatCard(context, "Toplam Kütüphane", (availableLibraries.length - 1), Icons.my_library_books, Colors.deepPurple)),
                  _buildStaggeredWrapper(3, _buildStatCard(context, "Sistemdeki Kelime", totalSystemWords, Icons.format_list_bulleted, Colors.cyan)),
                  _buildStaggeredWrapper(4, _buildStatCard(context, "Öğrenilen (Mezun)", learnedWords.length, Icons.workspace_premium, Colors.green)),
                  _buildStaggeredWrapper(5, _buildStatCard(context, "Tüm Zamanlar Doğru", totalCorrectCount, Icons.check_circle, Colors.teal)), 
                  _buildStaggeredWrapper(6, _buildStatCard(context, "Tüm Zamanlar Yanlış", totalWrongCount, Icons.gpp_bad, Colors.redAccent)),
                ],
              ),
              
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStaggeredWrapper(0, Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.indigo.shade600, Colors.deepPurple.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text("Leitner Kutusu (SRS)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text("Kelimeler bildikçe üst kutulara geçer. 5. Kutuyu geçen kelimeler 'Mezun (Tam Hafıza)' seviyesine ulaşır.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),

                  _buildStaggeredWrapper(1, Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                      border: Border.all(color: Colors.grey.withOpacity(0.15))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hafıza Dağılım Grafiği", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxBarVal > 0 ? maxBarVal * 1.25 : 10,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0: return const Text("K1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFFEA00)));
                                        case 1: return const Text("K2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD500F9)));
                                        case 2: return const Text("K3", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00E5FF)));
                                        case 3: return const Text("K4", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF3D00)));
                                        case 4: return const Text("K5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00E676)));
                                        case 5: return const Text("Mezun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber));
                                      }
                                      return const Text("");
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: srs1Count.toDouble(), color: const Color(0xFFFFEA00), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: srs2Count.toDouble(), color: const Color(0xFFD500F9), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: srs3Count.toDouble(), color: const Color(0xFF00E5FF), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: srs4Count.toDouble(), color: const Color(0xFFFF3D00), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: srs5Count.toDouble(), color: const Color(0xFF00E676), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: masteredCount.toDouble(), color: Colors.amber, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),

                  _buildStaggeredWrapper(2, _buildLeitnerBoxCard(context, "1. Kutu (1 Gün Tekrar)", "Geçici Hafıza • İlk Adım", srs1Count, totalActiveSRS, Icons.change_history, const Color(0xFFFFEA00))),
                  _buildStaggeredWrapper(3, _buildLeitnerBoxCard(context, "2. Kutu (2 Gün Tekrar)", "Başlangıç Seviyesi", srs2Count, totalActiveSRS, Icons.spa, const Color(0xFFD500F9))),
                  _buildStaggeredWrapper(4, _buildLeitnerBoxCard(context, "3. Kutu (4 Gün Tekrar)", "Orta Düzey Hafıza", srs3Count, totalActiveSRS, Icons.workspace_premium, const Color(0xFF00E5FF))),
                  _buildStaggeredWrapper(5, _buildLeitnerBoxCard(context, "4. Kutu (9 Gün Tekrar)", "Güçlü Hafıza", srs4Count, totalActiveSRS, Icons.military_tech, const Color(0xFFFF3D00))),
                  _buildStaggeredWrapper(6, _buildLeitnerBoxCard(context, "5. Kutu (14 Gün Tekrar)", "Kalıcı Hafıza Eşiği", srs5Count, totalActiveSRS, Icons.diamond, const Color(0xFF00E676))),
                  _buildStaggeredWrapper(7, _buildLeitnerBoxCard(context, "Mezun (Tam Hafıza)", "Kalıcı Ezber Yapıldı", masteredCount, totalActiveSRS, Icons.verified, Colors.amber)),
                  const SizedBox(height: 40),
                ],
              ),

              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStaggeredWrapper(0, Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade500, Colors.green.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.school, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text("Gerçek Öğrenme (Mezun) Hızı", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(graduationSpeed.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6.0, left: 8.0),
                              child: Text("Kelime / Gün", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text("Toplam Mezun Kelime: ${learnedWords.length}  |  Kullanım: $daysUsed Gün", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  _buildStaggeredWrapper(1, Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [const Icon(Icons.auto_graph, color: Colors.green), const SizedBox(width: 8), const Text("Haftalık Mezuniyet Eğrisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 150,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: graduationChartData,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: Colors.green)),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(colors: [Colors.green.withOpacity(0.5), Colors.green.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),

                  _buildStaggeredWrapper(2, Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.show_chart, color: primaryColor), const SizedBox(width: 8), const Text("Haftalık Aktivite Eğrisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 150,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: activityChartData,
                                    isCurved: true,
                                    color: primaryColor,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: primaryColor)),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(colors: [primaryColor.withOpacity(0.5), primaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  
                  _buildStaggeredWrapper(3, Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
                    child: Column(
                      children: [
                        const Text("Ortalama Aktivite Hızınız", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text("${activitySpeed.toStringAsFixed(1)} İşlem / Gün", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: const Text("Doğru bilme ve tekrar sıklığı", style: TextStyle(color: Colors.white, fontSize: 12))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),

                  _buildStaggeredWrapper(4, _buildSpeedCard(context, "Günlük (Son 24 Saat)", const Duration(days: 1), Colors.blue)),
                  _buildStaggeredWrapper(5, _buildSpeedCard(context, "Haftalık (Son 7 Gün)", const Duration(days: 7), Colors.orange)),
                  _buildStaggeredWrapper(6, _buildSpeedCard(context, "Aylık (Son 30 Gün)", const Duration(days: 30), Colors.purple)),
                  _buildStaggeredWrapper(7, _buildSpeedCard(context, "Yıllık (Son 365 Gün)", const Duration(days: 365), Colors.redAccent)),
                  const SizedBox(height: 80), 
                ],
              ),

              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (bestQuizCorrect > 0)
                    _buildStaggeredWrapper(0, Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orangeAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))]
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                                SizedBox(width: 10),
                                Text("Tüm Zamanların Quiz Rekoru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white30)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("İlk Seferde Doğru", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text("$bestQuizCorrect Soru", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text("Rekor Süre", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(_formatTime(bestQuizTime), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                            child: Text("Kırılma Tarihi: $bestQuizDate", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )),
                  
                  _buildStaggeredWrapper(1, _buildStatCard(context, "Tamamlanan Quiz", totalCompletedQuizzes, Icons.done_all, Colors.orange)),
                  _buildStaggeredWrapper(2, _buildTextStatCard(context, "Toplam Quiz Süresi", _formatTime(totalQuizTimeSeconds), Icons.timer, Colors.teal)),
                  _buildStaggeredWrapper(3, _buildStatCard(context, "Cevaplanan Soru", totalQuizQuestions, Icons.question_answer, Colors.blueAccent)),
                  _buildStaggeredWrapper(4, _buildStatCard(context, "Quiz Yanlışları", totalQuizWrong, Icons.error_outline, Colors.redAccent)),
                  _buildStaggeredWrapper(5, _buildTextStatCard(context, "Soru Çözme Hızı", "${quizSpeed.toStringAsFixed(1)} Soru / Dk", Icons.speed, Colors.purpleAccent)),
                ],
              ),
              
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: availableLibraries.length,
                itemBuilder: (context, index) {
                  String libName = availableLibraries[index];
                  if (libName == 'Tekrarlanması Gerekenler') return const SizedBox.shrink();

                  int total = allWords.where((e) => e.libraryName == libName).length +
                              learnedWords.where((e) => e.libraryName == libName).length +
                              learningWords.where((e) => e.libraryName == libName).length +
                              toRepeatWords.where((e) => e.libraryName == libName).length +
                              toSRSRepeatWords.where((e) => e.libraryName == libName).length;
                              
                  int learned = learnedWords.where((e) => e.libraryName == libName).length;
                  int wrong = wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                  double progress = total > 0 ? (learned / total) : 0;

                  return _buildStaggeredWrapper(index, Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(libName == 'WordNet Veritabanı' ? Icons.language : Icons.book, color: libName == 'WordNet Veritabanı' ? Colors.indigo : Colors.deepPurple, size: 24),
                              const SizedBox(width: 10),
                              Expanded(child: Text(libName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: libName == 'WordNet Veritabanı' ? Colors.indigo : Colors.deepPurple))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Toplam: $total", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Text("Öğrenilen: $learned", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, color: libName == 'WordNet Veritabanı' ? Colors.indigoAccent : Colors.greenAccent.shade400, backgroundColor: Colors.grey.withOpacity(0.2), minHeight: 8)),
                        ],
                      ),
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, int value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))], border: Border.all(color: color.withOpacity(0.2), width: 1.5)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
        trailing: _buildAnimatedNumber(value, TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    );
  }

  Widget _buildTextStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))], border: Border.all(color: color.withOpacity(0.2), width: 1.5)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
        trailing: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    );
  }
}
