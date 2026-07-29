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
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.menu_book_rounded, size: 72, color: primary),
                const SizedBox(height: 12),
                Text("Tayf Sözlük Pro", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text("Akıllı Kelime Öğrenme & SRS Sistemi", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildElegantSection(
            context,
            icon: Icons.schedule,
            title: "Aralıklı Tekrar Sistemi (SRS)",
            content: "Öğrendiğiniz kelimeler hafıza eğrinize göre belirli aralıklarla (1, 2, 4, 9, 14 gün) karşınıza çıkar. Kartı çevirdiğinizde 'Biliyorum' derseniz kelime bir üst seviyeye geçer, 'Tekrar' derseniz başa döner. Seviye 5'e ulaşan kelimeler 'Öğrenilenler' listesine kalıcı olarak mezun olur.",
          ),
          _buildElegantSection(
            context,
            icon: Icons.language,
            title: "WordNet Kütüphanesi",
            content: "Dünyanın en gelişmiş İngilizce sözlük ağı olan WordNet (160.000+ kelime) sisteme tam entegredir. Kelimelerin İngilizce anlamlarını, eş anlamlılarını (Synonym) ve zıt anlamlılarını (Antonym) otomatik olarak gruplayarak size eşsiz bir öğrenme deneyimi sunar.",
          ),
          _buildElegantSection(
            context,
            icon: Icons.quiz,
            title: "Dinamik Quiz & Çeldiriciler",
            content: "Sistem, sadece basit kelime soruları sormaz. WordNet kelimelerinde size bir anlam verip kelimeyi bulmanızı veya kelimeyi verip eş/zıt anlamlısını bulmanızı isteyebilir. Yanlış şıklar her zaman akıllıca seçilir.",
          ),
          
          const SizedBox(height: 24),
          const Divider(thickness: 1),
          const SizedBox(height: 24),

          // YENİ VE ŞIK: İÇE AKTARMA REHBERİ
          Row(
            children: [
              const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
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
            "Uygulamaya kendi kelime listelerinizi hatasız ve en verimli şekilde aktarabilmek için dosyalarınızı aşağıdaki ideal formatlara göre düzenlemeniz önerilir.",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),

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

          _buildFormatCard(
            context,
            title: "2. CSV Formatı (Excel Tarzı Gelişmiş Format)",
            extension: ".csv",
            color: Colors.teal,
            explanation: "Sütunlar virgül ( , ) ile ayrılır. Sırasıyla: Kelime, Anlamlar, Örnekler, Seviye. Bir hücrenin içinde birden fazla anlam varsa bunları Üç Boru ( ||| ) ile ayırabilirsiniz.",
            exampleCode: """Word,Meaning,Example,Level
apple,elma ||| meyve,I ate an apple.,Başlangıç
abandon,terk etmek ||| bırakmak,Don't abandon me.,İleri""",
          ),

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
  }
]""",
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Eski Zarif Tasarımlı Bölüm Oluşturucu
  Widget _buildElegantSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İçe Aktarma formatlarını gösteren şık kod kartı
  Widget _buildFormatCard(BuildContext context, {required String title, required String extension, required Color color, required String explanation, required String exampleCode}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: extension == ".txt", 
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(extension, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(explanation, style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 16),
                const Text("Örnek Dosya İçeriği:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
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
