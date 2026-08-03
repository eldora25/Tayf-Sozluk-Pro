import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// UYGULAMANIN HER YERİNDEN ERİŞİLEBİLECEK KÜRESEL LOG MERKEZİ
class GlobalLogger {
  static final List<String> logs = [
    "Sistem başlatıldı.",
  ];

  static void addLog(String message) {
    String timestamp = "[${DateTime.now().toLocal().toString().split('.')[0]}]";
    logs.add("$timestamp $message");
    print("$timestamp $message"); // Aynı zamanda konsola da yazdır
  }

  static String getAllLogs() {
    return logs.join('\n');
  }
}

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  
  Future<void> _exportLogs() async {
    if (GlobalLogger.logs.isEmpty) return;

    try {
      DateTime now = DateTime.now();
      String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
      String fileName = 'log_$timestamp.txt';
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      
      String logContent = GlobalLogger.getAllLogs();
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
      body: GlobalLogger.logs.isEmpty
          ? const Center(child: Text("Henüz bir hata kaydı bulunmuyor."))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: GlobalLogger.logs.length,
              itemBuilder: (context, index) {
                // Hata mesajlarını kırmızı, bilgi mesajlarını yeşil göstermek için
                bool isError = GlobalLogger.logs[index].toLowerCase().contains('hata') || 
                               GlobalLogger.logs[index].toLowerCase().contains('error') || 
                               GlobalLogger.logs[index].toLowerCase().contains('başarısız');

                return Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      GlobalLogger.logs[index],
                      style: TextStyle(
                        color: isError ? Colors.redAccent : Colors.greenAccent, 
                        fontFamily: 'monospace'
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
