import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Özellikler & Rehber"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFeatureCard(
            icon: Icons.psychology,
            color: Colors.blue,
            title: "Aralıklı Tekrar Sistemi (SRS)",
            description: "Beyninizin unutma eğrisini kırıyoruz! Öğrendiğiniz kelimeler 1, 2, 4, 9 ve 14. günlerde akıllı algoritmamızla karşınıza çıkar. 14. günü başarıyla geçen kelimeler 'Mezun' olur ve kalıcı hafızanıza yerleşir. Hata yaparsanız kelime 1. güne geri döner.",
          ),
          _buildFeatureCard(
            icon: Icons.local_fire_department,
            color: Colors.orange,
            title: "Günlük Seri (Streak) ve Buz Kalkanı",
            description: "Her gün uygulamaya girerek ateşinizi (serinizi) koruyun. Günlük hedeflerinizi tamamlayarak Tayf Puanı (TP) kazanın. Eğer bir gün giremeyecek olursanız, kazandığınız puanlarla 'Buz Kalkanı' (❄️) satın alarak serinizin yanmasını engelleyebilirsiniz.",
          ),
          _buildFeatureCard(
            icon: Icons.gamepad,
            color: Colors.purple,
            title: "Oyunlaştırılmış Quiz Modu",
            description: "Sıradan testleri unutun! Doğru cevaplarda butonlar parlar ve büyür, yanlış cevaplarda telefonunuz titrer ve şıklar sağa sola sarsılır. Quizi başarıyla bitirdiğinizde sizi havai fişekler karşılar.",
          ),
          _buildFeatureCard(
            icon: Icons.library_books,
            color: Colors.green,
            title: "Çoklu Anlam ve Sınırsız Kütüphane",
            description: "Bir kelimenin birden fazla anlamını ve örnek cümlesini ekleyebilirsiniz. İster kendi kütüphanenizi oluşturun, ister CSV/JSON formatındaki hazır listeleri saniyeler içinde içe aktarın.",
          ),
          _buildFeatureCard(
            icon: Icons.notifications_active,
            color: Colors.redAccent,
            title: "Akıllı Bildirimler",
            description: "Sizi asla gereksiz yere rahatsız etmeyiz. Sadece seriniz tehlikedeyse, SRS tekrar kelimelerinizin süresi gelmişse veya günlük hedefinize henüz ulaşmadıysanız size kibar hatırlatmalar yaparız.",
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Tayfun Yamak © 2026\nTayf Sözlük Pro V1.0",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
      child: Column(
        children: const [
          Icon(Icons.school, size: 60, color: Colors.deepPurple),
          SizedBox(height: 10),
          Text(
            "Tayf Sözlük Pro'ya Hoş Geldiniz!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          SizedBox(height: 10),
          Text(
            "Bu uygulama, dil öğrenme sürecinizi bilimsel metotlar ve modern arayüz tasarımıyla en üst seviyeye çıkarmak için tasarlandı.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required Color color, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
