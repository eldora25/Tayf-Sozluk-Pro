import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'models.dart';

class StatisticsScreen extends StatelessWidget {
  final List<WordModel> allWords;
  final List<WordModel> learningWords; 
  final List<WordModel> toRepeatWords; 
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

  const StatisticsScreen({
    super.key,
    required this.allWords,
    required this.learningWords,
    required this.toRepeatWords,
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
  });

  // MADDE 4: Zaman gösterimi kesin olarak dd:hh:mm:ss formatına dönüştürüldü
  String _formatTime(int seconds) {
    int d = seconds ~/ (24 * 3600);
    int h = (seconds % (24 * 3600)) ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${d.toString().padLeft(2, '0')}:${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int _countInPeriod(List<String> timestamps, Duration period) {
    final now = DateTime.now();
    return timestamps.where((ts) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      return now.difference(date) <= period;
    }).length;
  }

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}; 

    for (var ts in learnedWordTimestamps) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      final itemDate = DateTime(date.year, date.month, date.day);
      final diff = today.difference(itemDate).inDays;
      if (diff >= 0 && diff <= 6) {
        counts[6 - diff] = (counts[6 - diff] ?? 0) + 1;
      }
    }

    return counts.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
  }

  Widget _buildSpeedCard(BuildContext context, String title, Duration period, Color color) {
    int learned = _countInPeriod(learnedWordTimestamps, period);
    int quizzes = _countInPeriod(completedQuizTimestamps, period);
    int viewed = _countInPeriod(viewedCardTimestamps, period);
    int wrongs = _countInPeriod(wrongAnswerTimestamps, period);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Öğrenilen Kelime:"), Text("$learned", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tamamlanan Quiz:"), Text("$quizzes", style: const TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Bakılan Kart:"), Text("$viewed", style: const TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Yapılan Yanlış:"), Text("$wrongs", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<int> milestones, int currentValue, IconData icon, Color earnedColor, String unit) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        int target = milestones[index];
        bool isEarned = currentValue >= target;
        
        return Container(
          decoration: BoxDecoration(
            color: isEarned ? earnedColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isEarned ? earnedColor : Colors.grey.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isEarned ? icon : Icons.lock, color: isEarned ? earnedColor : Colors.grey, size: 36),
              const SizedBox(height: 8),
              Text("$target\n$unit", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isEarned ? earnedColor : Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSystemWords = allWords.length + learnedWords.length + toRepeatWords.length + learningWords.length;
    int totalWrongCount = wrongWords.fold(0, (a, b) => a + b.wrongCount);

    DateTime firstUse = DateTime.fromMillisecondsSinceEpoch(firstUseTimestamp);
    int daysUsed = DateTime.now().difference(firstUse).inDays;
    if (daysUsed < 1) daysUsed = 1; 
    double wordsPerDay = learnedWords.length / daysUsed;

    final List<int> streakMilestones = [5, 7, 10, 15, 20, 30, 40, 50, 75, 100, 150, 200, 300];
    final List<int> wordMilestones = [5, 7, 10, 15, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 600, 700, 1000, 1500, 2000, 2500, 3000, 5000, 7000, 10000];
    
    final chartData = _getChartData();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("İstatistikler & Rozetler"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Başarılar", icon: Icon(Icons.emoji_events)),
              Tab(text: "Genel Özet", icon: Icon(Icons.pie_chart)),
              Tab(text: "Öğrenme Eğrisi", icon: Icon(Icons.show_chart)), 
              Tab(text: "Quiz", icon: Icon(Icons.quiz)),
              Tab(text: "Kütüphaneler", icon: Icon(Icons.library_books)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("🔥 Ateşli Seri Rozetleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                const Text("Uygulamaya aralıksız girip aktivitene devam ettiğinde kazanılır.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                _buildBadgeGrid(streakMilestones, bestStreak, Icons.local_fire_department, Colors.deepOrange, "Gün"),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                const Text("🎓 Kelime Ustası Rozetleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text("Öğrenilen (Mezun) kelime havuzuna eklediğin kelime sayısına göre kazanılır.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                _buildBadgeGrid(wordMilestones, learnedWords.length, Icons.military_tech, Colors.blue, "Kelime"),
                const SizedBox(height: 40),
              ],
            ),

            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(context, "Mevcut Tayf Puan (TP)", tayfPoints.toString(), Icons.diamond, Colors.blue),
                _buildStatCard(context, "Toplam Kütüphane", (availableLibraries.length - 1).toString(), Icons.my_library_books, Colors.deepPurple),
                _buildStatCard(context, "Toplam Kelime", totalSystemWords.toString(), Icons.format_list_bulleted, Colors.cyan),
                _buildStatCard(context, "Öğrenilen (Mezun)", learnedWords.length.toString(), Icons.check_circle, Colors.green),
                _buildStatCard(context, "SRS Havuzunda", learningWords.length.toString(), Icons.access_time, Colors.orange), 
                _buildStatCard(context, "Toplam Yanlış", totalWrongCount.toString(), Icons.cancel, Colors.red),
              ],
            ),
            
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Haftalık Öğrenme Eğrisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
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
                                  spots: chartData,
                                  isCurved: true,
                                  color: Theme.of(context).primaryColor,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Ortalama Öğrenme Hızınız", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("${wordsPerDay.toStringAsFixed(1)} Kelime / Gün", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 4),
                        Text("Uygulama Kullanımı: $daysUsed Gün", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSpeedCard(context, "Günlük (Son 24 Saat)", const Duration(days: 1), Colors.blue),
                _buildSpeedCard(context, "Haftalık (Son 7 Gün)", const Duration(days: 7), Colors.orange),
                _buildSpeedCard(context, "Aylık (Son 30 Gün)", const Duration(days: 30), Colors.purple),
                _buildSpeedCard(context, "Yıllık (Son 365 Gün)", const Duration(days: 365), Colors.redAccent),
                const SizedBox(height: 80), 
              ],
            ),

            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(context, "Tamamlanan Quiz", totalCompletedQuizzes.toString(), Icons.done_all, Colors.orange),
                _buildStatCard(context, "Toplam Quiz Süresi", _formatTime(totalQuizTimeSeconds), Icons.timer, Colors.teal),
                _buildStatCard(context, "Cevaplanan Soru", totalQuizQuestions.toString(), Icons.question_answer, Colors.blueAccent),
                _buildStatCard(context, "Quiz Yanlışları", totalQuizWrong.toString(), Icons.error_outline, Colors.redAccent),
              ],
            ),
            
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableLibraries.length,
              itemBuilder: (context, index) {
                String libName = availableLibraries[index];
                if (libName == 'Tekrarlanması Gerekenler') return const SizedBox.shrink();

                int total = allWords.where((e) => e.libraryName == libName).length +
                            learnedWords.where((e) => e.libraryName == libName).length +
                            learningWords.where((e) => e.libraryName == libName).length +
                            toRepeatWords.where((e) => e.libraryName == libName).length;
                            
                int learned = learnedWords.where((e) => e.libraryName == libName).length;
                int wrong = wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                double progress = total > 0 ? (learned / total) : 0;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(libName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: progress, color: Colors.green, backgroundColor: Colors.grey[300], minHeight: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        subtitle: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    );
  }
}
