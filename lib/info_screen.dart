import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nasıl Kullanılır & Özellikler", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. ESKİ ŞIK GİRİŞ VE UYGULAMA ÖZELLİKLERİ
          Center(
            child: Column(
              children: [
                Icon(Icons.menu_book_rounded, size: 64, color: primary),
                const SizedBox(height: 8),
                Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 4),
                const Text("Akıllı Kelime Öğrenme & Aralıklı Tekrar Sistemi", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildFeatureCard(
            context,
            icon: Icons.schedule,
            color: Colors.blue,
            title: "Aralıklı Tekrar Sistemi (SRS)",
            description: "Öğrendiğiniz kelimeler hafıza eğrinize göre (1, 2, 4, 9, 14 gün) aralıklarla karşınıza çıkar. 'Biliyorum' dediğiniz kelimelerin seviyesi artar, 'Tekrar' dediğiniz kelimeler başa döner.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.local_fire_department,
            color: Colors.orange,
            title: "Günlük Seri & Buz Kalkanı",
            description: "Uygulamayı her gün kullanarak serinizi büyütün. Kazandığınız Tayf Puanlarıyla (TP) 'Buz Kalkanı' alarak, uygulamaya giremediğiniz günlerde serinizin bozulmasını engelleyebilirsiniz.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.quiz,
            color: Colors.deepPurpleAccent,
            title: "Dinamik Quiz Modu",
            description: "Kelimeleri ezberlemek için eşleştirme oyunları, telaffuz sınavları ve akıllı çeldiricilerle donatılmış, zamana karşı yarışılan çoktan seçmeli quiz modlarını kullanabilirsiniz.",
          ),
          
          const SizedBox(height: 32),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // 2. İÇE AKTARMA (IMPORT) FORMAT REHBERİ
          Row(
            children: [
              const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "İçe Aktarma (Import) Format Rehberi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Uygulamaya kendi kelime listelerinizi (TXT, CSV veya JSON) hatasız, kayıpsız ve en verimli şekilde aktarabilmek için dosyalarınızı aşağıdaki ideal formatlara göre düzenlemeniz önerilir.",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // TXT Formatı Kılavuzu
          _buildFormatCard(
            context,
            title: "1. TXT Formatı (Önerilen Basit Format)",
            extension: ".txt",
            color: Colors.blueGrey,
            explanation: "Kelime ile anlamı ayırmak için İki Nokta ( : ), birden fazla anlamı birbirinden ayırmak için Noktalı Virgül ( ; ) kullanmalısınız.",
            exampleCode: """elma : meyve ; kırmızı veya yeşil renkli tatlı meyve
araba : taşıt ; motorlu araç
book : kitap ; ayırtmak ; rezervasyon yapmak""",
          ),

          // CSV Formatı Kılavuzu
          _buildFormatCard(
            context,
            title: "2. CSV Formatı (Excel Tarzı Gelişmiş Format)",
            extension: ".csv",
            color: Colors.teal,
            explanation: "Sütunlar virgül ( , ) ile ayrılır. Sırasıyla: Kelime, Anlamlar, Örnekler, Seviye. Bir hücrenin içinde birden fazla anlam veya örnek varsa bunları Üç Boru ( ||| ) ile ayırabilirsiniz.",
            exampleCode: """Word,Meaning,Example,Level
apple,elma ||| meyve,I ate an apple.,Başlangıç
abandon,terk etmek ||| bırakmak,Don't abandon me. ||| He abandoned his car.,İleri""",
          ),

          // JSON Formatı Kılavuzu
          _buildFormatCard(
            context,
            title: "3. JSON Formatı (Programcı Formatı)",
            extension: ".json",
            color: Colors.deepPurple,
            explanation: "Dosyanız bir liste (array) içinde JSON objelerinden oluşmalıdır. 'word' kelimeyi, 'meanings' anlamları (dizi olarak), 'examples' örnekleri belirtir.",
            exampleCode: """[
  {
    "word": "resilient",
    "meanings": ["dirençli", "çabuk iyileşen"],
    "examples": ["She is a resilient person."],
    "level": "İleri"
  },
  {
    "word": "apple",
    "meanings": ["elma"],
    "examples": [],
    "level": "Başlangıç"
  }
]""",
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Özellikleri gösteren standart kart yapısı (İlk versiyonun aynısı)
  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required Color color, required String title, required String description}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İçe Aktarma formatlarını gösteren özel kod görünümlü kart yapısı
  Widget _buildFormatCard(BuildContext context, {required String title, required String extension, required Color color, required String explanation, required String exampleCode}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: extension == ".txt", 
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(extension, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(explanation, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                const Text("Örnek Dosya İçeriği:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: SelectableText(
                    exampleCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isDark ? Colors.greenAccent : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
