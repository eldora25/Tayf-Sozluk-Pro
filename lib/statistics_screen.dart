import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final int totalLibraries;
  final int totalWords;
  final int learnedWords;
  final int wordsToRepeat;
  final int totalWrongAnswers;

  const StatisticsScreen({
    super.key,
    required this.totalLibraries,
    required this.totalWords,
    required this.learnedWords,
    required this.wordsToRepeat,
    required this.totalWrongAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildStatCard(context, "Toplam Kütüphane", totalLibraries.toString(), Icons.library_books, Colors.deepPurple),
            _buildStatCard(context, "Toplam Kelime", totalWords.toString(), Icons.format_list_bulleted, Colors.blue),
            _buildStatCard(context, "Öğrenilen Kelime", learnedWords.toString(), Icons.check_circle, Colors.green),
            _buildStatCard(context, "Tekrarlanacak Kelime", wordsToRepeat.toString(), Icons.repeat, Colors.orange),
            _buildStatCard(context, "Toplam Yanlış Sayısı", totalWrongAnswers.toString(), Icons.cancel, Colors.red),
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
