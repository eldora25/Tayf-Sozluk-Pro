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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.deepPurple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: const [
                Icon(Icons.menu_book_rounded, size: 64, color: Colors.white),
                SizedBox(height: 12),
                Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                SizedBox(height: 6),
                Text("Akıllı Kelime Öğrenme & Aralıklı Tekrar Sistemi", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14)),
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
            description: "Kelimeleri ezberlemek için %40 zorlu kelimeler, %60 yeni kelimelerle harmanlanmış, zamana karşı yarışılan çoktan seçmeli zeki quiz modlarını kullanabilirsiniz.",
          ),
          
          const SizedBox(height: 32),
          const Divider(thickness: 2),
          const SizedBox(height: 24),

          // 2. İÇE AKTARMA (IMPORT) FORMAT REHBERİ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "İçe Aktarma (Import) Format Rehberi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Uygulamaya kendi kelime listelerinizi (TXT, CSV veya JSON) hatasız, kayıpsız ve en verimli şekilde aktarabilmek için dosyalarınızı aşağıdaki ideal formatlara göre düzenlemeniz önerilir.",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),

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

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required Color color, required String title, required String description}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(BuildContext context, {required String title, required String extension, required Color color, required String explanation, required String exampleCode}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: extension == ".txt", 
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(extension, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(explanation, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 14),
                const Text("Örnek Dosya İçeriği:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  child: SelectableText(
                    exampleCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isDark ? Colors.greenAccent.shade200 : Colors.indigo.shade900,
                      height: 1.5
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
