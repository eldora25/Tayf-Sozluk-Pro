import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// GLOBAL HATA KAYDEDİCİ MOTOR
class AppLogger {
  static Future<void> logError(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_errors.log');
      final timestamp = DateTime.now().toString();
      await file.writeAsString('[$timestamp] $message\n\n', mode: FileMode.append);
    } catch (e) {
      // Dosyaya yazılamazsa sessizce geç
    }
  }

  static Future<String> readLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_errors.log');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      return "Log dosyası okunamadı: $e";
    }
    return "Kayıtlı hata bulunamadı.";
  }

  static Future<void> clearLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_errors.log');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Hata olursa görmezden gel
    }
  }
}

// LOG GÖRÜNTÜLEME EKRANI
class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  String logContent = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    String logs = await AppLogger.readLogs();
    setState(() {
      logContent = logs.isEmpty ? "Kayıtlı hata bulunamadı." : logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem Hata Kayıtları"),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Tümünü Kopyala",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logContent));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loglar kopyalandı!")));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Temizle",
            onPressed: () async {
              await AppLogger.clearLogs();
              _loadLogs();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loglar temizlendi.")));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          logContent, 
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
