import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'main.dart'; 

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> with SingleTickerProviderStateMixin {
  bool _isNotificationShowing = false;
  late AnimationController _notifController;
  late Animation<Offset> _notifOffset;

  @override
  void initState() {
    super.initState();
    _notifController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500)
    );
    _notifOffset = Tween<Offset>(begin: const Offset(0.0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _notifController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

  // 1. BİLDİRİM SİMÜLASYONU
  void _showDemoNotification() {
    if (_isNotificationShowing) return;
    setState(() => _isNotificationShowing = true);
    
    _notifController.forward();
    
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _notifController.reverse().then((value) {
          setState(() => _isNotificationShowing = false);
        });
      }
    });
  }

  // 2. SRS DEMO KELİMELERİ ENJEKTE ETME
  Future<void> _injectDemoSrsWords() async {
    int pastTime = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    
    List<WordModel> demoWords = [
      WordModel(word: 'Ephemeral', meanings: ['Geçici', 'Kısa süreli'], examples: ['Fame is ephemeral.'], libraryName: 'Demo Sözlük', listType: 'toRepeat', level: 'İleri')..srsLevel = 2..nextReviewDate = pastTime..wrongCount = 1,
      WordModel(word: 'Resilient', meanings: ['Dirençli', 'Çabuk iyileşen'], examples: ['She is very resilient.'], libraryName: 'Demo Sözlük', listType: 'toRepeat', level: 'Orta')..srsLevel = 1..nextReviewDate = pastTime,
      WordModel(word: 'Serendipity', meanings: ['Mutlu tesadüf'], examples: ['Finding this book was pure serendipity.'], libraryName: 'Demo Sözlük', listType: 'toRepeat', level: 'İleri')..srsLevel = 3..nextReviewDate = pastTime,
    ];

    await isar.writeTxn(() async {
      await isar.wordModels.putAll(demoWords);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("3 Adet Demo SRS Kelimesi sisteme eklendi! Ana Ekrana dönebilirsiniz."), backgroundColor: Colors.green)
      );
    }
  }

  // 3. ZAMAN MAKİNESİ (Sistemi İleri Sarma)
  Future<void> _timeTravelForward() async {
    List<WordModel> learningWords = await isar.wordModels.filter().listTypeEqualTo('learning').findAll();
    
    if (learningWords.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SRS Havuzunda ileri sarılacak 'Öğrenilen' kelime yok."), backgroundColor: Colors.orange)
        );
      }
      return;
    }

    // Beklemedeki kelimelerin zamanını 2 gün ileri sar (Geçmişe at) ki tekrar vakitleri gelsin
    int twoDaysMs = 2 * 24 * 60 * 60 * 1000;
    
    for (var w in learningWords) {
      w.nextReviewDate = w.nextReviewDate - twoDaysMs;
      // Eğer zamanı dolduysa direkt listesini 'toRepeat' yap (main.dart'taki döngüyü simule et)
      if (w.nextReviewDate <= DateTime.now().millisecondsSinceEpoch) {
        w.listType = 'toRepeat';
      }
    }

    await isar.writeTxn(() async {
      await isar.wordModels.putAll(learningWords);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${learningWords.length} kelimenin zamanı 2 gün ileri sarıldı! Ana Ekranda uyarısı çıkacaktır."), backgroundColor: Colors.blueAccent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Bu ekran, uygulamanın SRS (Aralıklı Tekrar) dinamiklerini ve bildirim sistemini beklemeden test edebilmeniz için tasarlanmıştır.",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),

              // KART 1: Bildirim Simülasyonu
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_active, size: 48, color: Colors.amber),
                      const SizedBox(height: 10),
                      const Text("Bildirim Görünüm Testi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Cihaza düşecek olan hatırlatma bildiriminin görsel bir kopyasını ekranın üst kısmında canlandırır.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Bildirimi Canlandır"),
                        onPressed: _showDemoNotification,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KART 2: SRS Kelime Enjektesi
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.playlist_add_circle, size: 48, color: Colors.green),
                      const SizedBox(height: 10),
                      const Text("Örnek SRS Verisi Yükle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Ana ekrandaki 'Tekrar Zamanı!' kırmızı uyarı kutusunu tetiklemek için sisteme süresi dolmuş 3 adet İngilizce kelime ekler.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add),
                        label: const Text("Demo Kelimeleri Ekle"),
                        onPressed: _injectDemoSrsWords,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KART 3: Zaman Makinesi
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.history_toggle_off, size: 48, color: Colors.blueAccent),
                      const SizedBox(height: 10),
                      const Text("Zaman Makinesi (Sistemi İleri Sar)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Şu an 'Öğrenilen' (beklemede olan) kelimelerin zamanını 2 gün ileri sarar. Böylece günlerce beklemeden kelimelerin SRS havuzuna düşüp düşmediğini test edebilirsiniz.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        icon: const Icon(Icons.fast_forward),
                        label: const Text("Zamanı 2 Gün İleri Sar"),
                        onPressed: _timeTravelForward,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          // EKRANIN ÜSTÜNDEN İNEN BİLDİRİM ANİMASYONU
          Align(
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: _notifOffset,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text("Tekrar Zamanı Geldi! 🔥", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("Öğrendiklerini unutmaman için seni bekleyen 5 kelimen var. Seriyi bozmamak için şimdi tekrar et!", style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
