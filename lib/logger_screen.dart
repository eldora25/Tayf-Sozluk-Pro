import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  // Örnek Log Listesi (Gerçek log mekanizmanıza bağlanabilir)
  List<String> logs = [
    "Sistem başlatıldı.",
    "Veritabanı bağlantısı kuruldu.",
    "WordNet kütüphanesi hazır.",
    "Kullanıcı girişi başarılı."
  ];

  Future<void> _exportLogs() async {
    if (logs.isEmpty) return;

    try {
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'log_$timestamp.txt';
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      
      String logContent = logs.join('\n');
      await file.writeAsString(logContent);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Tayf Sözlük Pro - Sistem Hata Logları');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Log dışa aktarma hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hata Kayıtları (Log)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Logları .txt Olarak Paylaş",
            onPressed: _exportLogs,
          )
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text("Henüz bir hata kaydı bulunmuyor."))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "[${DateTime.now().toLocal().toString().split('.')[0]}] ${logs[index]}",
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
