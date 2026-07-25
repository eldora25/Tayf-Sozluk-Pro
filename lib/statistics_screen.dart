import 'package:flutter/material.dart';
import 'models.dart';

class StatisticsScreen extends StatelessWidget {
  final List<WordModel> allWords;
  final List<WordModel> learnedWords;
  final List<WordModel> wrongWords;
  final List<String> availableLibraries;
  
  // Global Quiz İstatistikleri
  final int totalCompletedQuizzes;
  final int totalQuizTimeSeconds;
  final int totalQuizQuestions;
  final int totalQuizWrong;

  // Öğrenme Hızı Zaman Damgaları
  final List<String> learnedWordTimestamps;
  final List<String> completedQuizTimestamps;
  final List<String> viewedCardTimestamps;
  final List<String> wrongAnswerTimestamps;
  final int firstUseTimestamp;

  const StatisticsScreen({
    super.key,
    required this.allWords,
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
  });

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Öğrenilen Kelime:"),
                Text("$learned", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tamamlanan Quiz:"),
                Text("$quizzes", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Bakılan Kart:"),
                Text("$viewed", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Yapılan Yanlış:"),
                Text("$wrongs", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSystemWords = allWords.length + learnedWords.length;
    int totalWrongCount = wrongWords.fold(0, (a, b) => a + b.wrongCount);

    DateTime firstUse = DateTime.fromMillisecondsSinceEpoch(firstUseTimestamp);
    int daysUsed = DateTime.now().difference(firstUse).inDays;
    if (daysUsed < 1) daysUsed = 1; 
    double wordsPerDay = learnedWords.length / daysUsed;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("İstatistikler"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Genel Özet", icon: Icon(Icons.pie_chart)),
              Tab(text: "Öğrenme Hızı", icon: Icon(Icons.speed)),
              Tab(text: "Quiz İstatistikleri", icon: Icon(Icons.quiz)),
              Tab(text: "Kütüphane Bazlı", icon: Icon(Icons.library_books)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. GENEL ÖZET
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(context, "Toplam Kütüphane", (availableLibraries.length - 1).toString(), Icons.my_library_books, Colors.deepPurple),
                _buildStatCard(context, "Toplam Kelime", totalSystemWords.toString(), Icons.format_list_bulleted, Colors.blue),
                _buildStatCard(context, "Öğrenilen Kelime", learnedWords.length.toString(), Icons.check_circle, Colors.green),
                _buildStatCard(context, "Toplam Yanlış", totalWrongCount.toString(), Icons.cancel, Colors.red),
              ],
            ),
            
            // 2. ÖĞRENME HIZI
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 20),
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
                _buildSpeedCard(context, "Günlük (Son 24 Saat)", const Duration(days: 1), Colors.blue),
                _buildSpeedCard(context, "Haftalık (Son 7 Gün)", const Duration(days: 7), Colors.orange),
                _buildSpeedCard(context, "Aylık (Son 30 Gün)", const Duration(days: 30), Colors.teal),
                _buildSpeedCard(context, "Yıllık (Son 365 Gün)", const Duration(days: 365), Colors.deepPurple),
              ],
            ),

            // 3. QUİZ İSTATİSTİKLERİ
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(context, "Tamamlanan Quiz", totalCompletedQuizzes.toString(), Icons.done_all, Colors.orange),
                _buildStatCard(context, "Toplam Quiz Süresi", _formatTime(totalQuizTimeSeconds), Icons.timer, Colors.teal),
                _buildStatCard(context, "Cevaplanan Soru", totalQuizQuestions.toString(), Icons.question_answer, Colors.blueAccent),
                _buildStatCard(context, "Quiz Yanlışları", totalQuizWrong.toString(), Icons.error_outline, Colors.redAccent),
              ],
            ),
            
            // 4. KÜTÜPHANE BAZLI
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableLibraries.length,
              itemBuilder: (context, index) {
                String libName = availableLibraries[index];
                if (libName == 'Tekrarlanması Gerekenler') return const SizedBox.shrink();

                int total = allWords.where((e) => e.libraryName == libName).length +
                            learnedWords.where((e) => e.libraryName == libName).length;
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
                        // KESİN ÇÖZÜM: Taşmayı önleyen FittedBox yapısı
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
