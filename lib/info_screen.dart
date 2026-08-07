import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isTr = context.locale.languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? "Nasıl Kullanılır & Özellikler" : "How to Use & Features", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.deepPurple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text("Lexis Eldora", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(
                  isTr ? "Akıllı Kelime Öğrenme & Aralıklı Tekrar Sistemi" : "Smart Word Learning & Spaced Repetition System", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14)
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildFeatureCard(
            context,
            icon: Icons.language,
            color: Colors.indigo,
            title: isTr ? "WordNet Veritabanı (150.000+ Kelime)" : "WordNet Database (150,000+ Words)",
            description: isTr 
                ? "Gelişmiş İngilizce-İngilizce kelime ağından oluşan bu devasa sözlük, ilk kullanımda Isar veritabanına kalıcı olarak gömülür. Bu işlem sadece bir kez yapılır ve cihazınızın hızına bağlı olarak 1-2 dakika sürebilir. Sonrasında tüm sorgularınız, quiz eşleştirmeleriniz ve listeleriniz tamamen offline (internetsiz) ve ışık hızında çalışır."
                : "Consisting of an advanced English-English word net, this massive dictionary is permanently embedded into the Isar database upon first use. This process is done only once and can take 1-2 minutes depending on your device's speed. Afterwards, all your queries, quiz matches, and lists work completely offline and at lightning speed.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.schedule,
            color: Colors.blue,
            title: isTr ? "Aralıklı Tekrar Sistemi (SRS)" : "Spaced Repetition System (SRS)",
            description: isTr
                ? "Öğrendiğiniz kelimeler hafıza eğrinize göre (1, 2, 4, 9, 14 gün) aralıklarla karşınıza çıkar. 'Biliyorum' dediğiniz kelimelerin seviyesi artar, 'Tekrar' dediğiniz kelimeler başa döner."
                : "The words you learn appear to you at intervals according to your memory curve (1, 2, 4, 9, 14 days). The level of words you say 'I know' increases, and words you say 'Repeat' go back to the beginning.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.local_fire_department,
            color: Colors.orange,
            title: isTr ? "Günlük Seri & Buz Kalkanı" : "Daily Streak & Freeze Shield",
            description: isTr
                ? "Uygulamayı her gün kullanarak serinizi büyütün. Kazandığınız Tayf Puanlarıyla (TP) 'Buz Kalkanı' alarak, uygulamaya giremediğiniz günlerde serinizin bozulmasını engelleyebilirsiniz."
                : "Grow your streak by using the app every day. By purchasing a 'Freeze Shield' with the Tayf Points (TP) you earned, you can prevent your streak from breaking on days you cannot open the app.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.quiz,
            color: Colors.deepPurpleAccent,
            title: isTr ? "Dinamik Quiz Modu" : "Dynamic Quiz Mode",
            description: isTr
                ? "Kelimeleri ezberlemek için %40 zorlu kelimeler, %60 yeni kelimelerle harmanlanmış, zamana karşı yarışılan çoktan seçmeli zeki quiz modlarını kullanabilirsiniz."
                : "To memorize words, you can use intelligent multiple-choice timed quiz modes blended with 40% difficult words and 60% new words.",
          ),
          _buildFeatureCard(
            context,
            icon: Icons.warning_amber_rounded,
            color: Colors.amber,
            title: isTr ? "İncelenecekler (Karantina)" : "Review Pool (Quarantine)",
            description: isTr
                ? "Ana ekranda çalışırken hatalı olduğunu düşündüğünüz bir karta denk gelirseniz, '!' (Sarı Ünlem) butonuna basarak onu anında eski havuzundan koparıp İncelenecekler listesine atabilirsiniz. Bu işlem, buluttaki güven skorunu da otonom olarak düşürür."
                : "If you encounter a card while studying on the main screen that you think is flawed, you can instantly pull it out of its old pool and throw it into the Review list by pressing the '!' (Yellow Exclamation) button. This action also autonomously lowers its trust score in the cloud.",
          ),

          _buildFeatureCard(
            context,
            icon: Icons.call_split_rounded,
            color: Colors.teal,
            title: isTr ? "🛠️ Kartları Ayrıştır ve Parçala (Split)" : "🛠️ Split and Breakdown Cards (Split)",
            description: isTr
                ? "Kelime listelerinizde veya karantinada birleşik/hatalı kaydedilmiş kartlar görürseniz (Örn: Kelime: Apple, Apples) bu kelimeyi düzenle diyerek 'PARÇALA' butonuna basın. Tek dokunuşla bu kartı bağımsız kök kelimelere ayırıp, eşsiz DNA'ları ile sisteme saf kartlar olarak geri kazandırabilirsiniz."
                : "If you see combined/incorrectly saved cards in your word lists or quarantine (e.g., Word: Apple, Apples), tap edit and press the 'SPLIT' button. With a single touch, you can separate this card into independent root words and bring them back to the system as pure cards with their unique DNAs.",
          ),
          
          const SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [isDark ? Colors.deepPurple.shade900.withOpacity(0.5) : Colors.purple.shade50, isDark ? Colors.indigo.shade900.withOpacity(0.5) : Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public, color: Colors.deepPurpleAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTr ? "🌍 Firebase Topluluk & 🧬 Mitoz Bulut Ekosistemi" : "🌍 Firebase Community & 🧬 Mitosis Cloud Ecosystem",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 4)]
                        ),
                        child: Text(isTr ? "YENİ" : "NEW", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTr 
                        ? "Lexis Eldora artık e-posta gönderip bekleme devrini kapatarak tamamen otonomleşti! Doğrudan bulut entegrasyonu sayesinde verileriniz anlık olarak senkronize edilir ve kalite filtreden geçer."
                        : "Lexis Eldora has now become completely autonomous, eliminating the era of sending emails and waiting! Thanks to direct cloud integration, your data is synchronized instantly and filtered for quality.",
                    style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildSubFeatureRow(
                    context, 
                    Icons.biotech, 
                    Colors.purple, 
                    isTr ? "Mitoz Bölünme (Saf Kartlar):" : "Mitotic Fission (Pure Cards):", 
                    isTr 
                        ? "Quiz çözerken çok anlamlı kelimeler (Örn: Apple = Elma, Meyve) doğru bilindikçe otomatik bölünür ve 'Mitoz' kütüphanenize tek anlamlı kusursuz bilgi kartları olarak eşsiz DNA damgasıyla düşer."
                        : "Multi-meaning words while solving quizzes (e.g., Apple = Elma, Meyve) automatically split as they are answered correctly and drop into your 'Mitosis' library as single-meaning perfect flashcards with a unique DNA stamp."
                  ),
                  const SizedBox(height: 16),
                  _buildSubFeatureRow(
                    context, 
                    Icons.cloud_upload_rounded, 
                    Colors.purpleAccent, 
                    isTr ? "Buluta Senkronize Et (Toplu Batch Gönderim):" : "Sync to Cloud (Batch Upload):", 
                    isTr
                        ? "Kütüphane Yönetimi ekranındaki mor yükleme butonuna basarak mitoz kartlarınızı saniyeler içinde Firebase bulutuna aktarabilirsiniz. Kompozit anahtar mimarisi (Kelime + Anlam) sayesinde mükerrer kayıtlar engellenir, popülarite skoru artar ve +50 TP kazanırsınız."
                        : "You can transfer your mitosis cards to the Firebase cloud in seconds by pressing the purple upload button on the Library Management screen. Thanks to the composite key architecture (Word + Meaning), duplicate entries are prevented, the popularity score increases, and you earn +50 TP."
                  ),
                  const SizedBox(height: 16),
                  _buildSubFeatureRow(
                    context, 
                    Icons.shield_rounded, 
                    Colors.redAccent, 
                    isTr ? "Otonom Karantina ve Kalite Filtresi:" : "Autonomous Quarantine and Quality Filter:", 
                    isTr
                        ? "Hatalı olduğunu düşündüğünüz kartlar için '!' karantina butonunu kullandığınızda, sistem buluttaki kartın Güven Skorunu (Trust Score) otonom olarak düşürür. Eksi skora düşen bozuk kartlar havuzdan otomatik olarak imha edilir."
                        : "When you use the '!' quarantine button for cards you think are incorrect, the system autonomously lowers the Trust Score of the card in the cloud. Broken cards falling into negative scores are automatically destroyed from the pool."
                  ),
                  const SizedBox(height: 16),
                  _buildSubFeatureRow(
                    context, 
                    Icons.cloud_download, 
                    Colors.blue, 
                    isTr ? "Buluttan Havuz İndir (Çek):" : "Download Pool from Cloud (Pull):", 
                    isTr
                        ? "Kütüphane Yönetimi ekranındaki Bulut ikonuna dokunarak isterseniz Standart Topluluk Havuzunu, isterseniz de %100 saf kartlardan oluşan Global Mitoz Havuzunu doğrudan güncel olarak indirebilirsiniz."
                        : "By tapping the Cloud icon on the Library Management screen, you can download either the Standard Community Pool or the Global Mitosis Pool consisting of 100% pure cards as up-to-date."
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [isDark ? Colors.blueGrey.shade900 : Colors.lightBlue.shade50, isDark ? Colors.cyan.shade900.withOpacity(0.5) : Colors.cyan.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan.shade400.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.cyan.shade400.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: Colors.cyan.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTr ? "İlerleme Geçmişi (Bulut Yedekleme)" : "Progress History (Cloud Backup)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTr
                        ? "Emek vererek ulaştığınız SRS (Hafıza) seviyeleri, Tayf Puanları (TP), Ateşli Serileriniz ve satın aldığınız Buz Kalkanları artık tamamen güvende!"
                        : "The SRS (Memory) levels, Tayf Points (TP), Streaks, and Freeze Shields you reached with your hard work are now completely safe!",
                    style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildSubFeatureRow(
                    context, 
                    Icons.person_pin_circle, 
                    Colors.cyan.shade600, 
                    isTr ? "Sana Özel Kullanıcı Adı (Username):" : "Custom Username:", 
                    isTr
                        ? "Yan menünün (Drawer) en üstünden 3-11 haneli büyük/küçük harf duyarlı şık bir Kullanıcı Adı (Örn: Tayfun25) belirleyebilirsiniz. Tüm kayıtlarınız bulutta sadece bu anahtarla şifrelenir."
                        : "You can set an elegant 3-11 digit case-sensitive Username (e.g., Tayfun25) from the top of the side menu (Drawer). All your records are encrypted in the cloud using only this key."
                  ),
                  const SizedBox(height: 16),
                  _buildSubFeatureRow(
                    context, 
                    Icons.cloud_upload, 
                    Colors.blueAccent, 
                    isTr ? "Günde 4 Kez Buluta Kilit (6 Saat Limiti):" : "Cloud Lock 4 Times a Day (6-Hour Limit):", 
                    isTr
                        ? "Yan menüdeki 'Buluta Yedekle' seçeneği ile o anki tüm gelişiminizi kendi adınızla Firebase'e gönderebilirsiniz. Adil kullanım için bu işlem günde sadece 4 kez (6 saatte bir) yapılabilir."
                        : "You can send all your current progress to Firebase under your own name with the 'Backup to Cloud' option in the side menu. For fair use, this action can only be done 4 times a day (every 6 hours)."
                  ),
                  const SizedBox(height: 16),
                  _buildSubFeatureRow(
                    context, 
                    Icons.sync_rounded, 
                    Colors.green, 
                    isTr ? "Her Cihazda Anında Geri Yükleme:" : "Instant Restore on Every Device:", 
                    isTr
                        ? "Cihaz değiştirdiğinizde veya uygulamayı sildiğinizde, 'Buluttan Geri Yükle' sekmesine belirlediğiniz Kullanıcı Adını girmeniz yeterlidir. Tüm ilerlemeniz otonom olarak yeni cihaza taşınır. (Geri yüklemede süre sınırı yoktur)."
                        : "When you change devices or uninstall the app, simply enter the Username you set into the 'Restore from Cloud' tab. All your progress is autonomously migrated to the new device. (There is no time limit on restore)."
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(thickness: 2),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade700, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTr ? "PRO İPUCU: Akıllı Seslendirme (TTS)" : "PRO TIP: Smart Voiceover (TTS)", 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isTr
                      ? "Uygulamanın yüklediğiniz dosyaları İngilizce mi yoksa Türkçe mi okuyacağını bilmesi için; dosya adınıza 'ing-tr' (veya 'eng-tur') ekleyebilirsiniz. \nÖrn: benim_sozlugum_ing-tr.csv\n\nVeya doğrudan dosyanızın İLK SATIRINA '#tts:ing-tr' parametresini yazarak motoru kusursuzca yönlendirebilirsiniz."
                      : "For the app to know whether to read your uploaded files in English or Turkish, you can append 'ing-tr' (or 'eng-tur') to your filename.\nE.g., my_dictionary_ing-tr.csv\n\nOr you can directly guide the engine flawlessly by writing the '#tts:ing-tr' parameter on the FIRST LINE of your file.",
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: isDark ? Colors.amber.shade100 : Colors.black87),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isTr ? "İçe Aktarma (Import) Format Rehberi" : "Import Format Guide",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isTr
                ? "Uygulamaya kendi kelime listelerinizi (TXT, CSV veya JSON) hatasız, kayıpsız ve en verimli şekilde aktarabilmek için dosyalarınızı aşağıdaki ideal formatlara göre düzenlemeniz önerilir."
                : "To import your own word lists (TXT, CSV or JSON) into the app flawlessly, losslessly and in the most efficient way, it is recommended to organize your files according to the ideal formats below.",
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          _buildFormatCard(
            context,
            title: isTr ? "1. TXT Formatı (Önerilen Basit Format)" : "1. TXT Format (Recommended Simple Format)",
            extension: ".txt",
            color: Colors.blueGrey,
            explanation: isTr
                ? "Kelime ile anlamı ayırmak için İki Nokta ( : ), birden fazla anlamı birbirinden ayırmak için Noktalı Virgül ( ; ) kullanmalısınız. İsteğe bağlı olarak ilk satıra TTS dilini belirten parametreyi yazabilirsiniz."
                : "You must use a Colon ( : ) to separate the word from its meaning, and a Semicolon ( ; ) to separate multiple meanings from each other. Optionally, you can write the parameter specifying the TTS language on the first line.",
            exampleCode: """#tts:ing-tr
elma : meyve ; kırmızı veya yeşil renkli tatlı meyve
araba : taşıt ; motorlu araç
book : kitap ; ayırtmak ; rezervasyon yapmak""",
          ),

          _buildFormatCard(
            context,
            title: isTr ? "2. CSV Formatı (Excel Tarzı Gelişmiş Format)" : "2. CSV Format (Excel Style Advanced Format)",
            extension: ".csv",
            color: Colors.teal,
            explanation: isTr
                ? "Sütunlar virgül ( , ) ile ayrılır. Sırasıyla: Kelime, Anlamlar, Örnekler, Seviye. Bir hücrenin içinde birden fazla anlam veya örnek varsa bunları Üç Boru ( ||| ) ile ayırabilirsiniz."
                : "Columns are separated by commas ( , ). Respectively: Word, Meanings, Examples, Level. If a cell contains multiple meanings or examples, you can separate them with Three Pipes ( ||| ).",
            exampleCode: """#tts:ing-tr
Word,Meaning,Example,Level
apple,elma ||| meyve,I ate an apple.,Başlangıç
abandon,terk etmek ||| bırakmak,Don't abandon me. ||| He abandoned his car.,İleri""",
          ),

          _buildFormatCard(
            context,
            title: isTr ? "3. JSON Formatı (Programcı Formatı)" : "3. JSON Format (Developer Format)",
            extension: ".json",
            color: Colors.deepPurple,
            explanation: isTr
                ? "Dosyanız bir liste (array) içinde JSON objelerinden oluşmalıdır. 'word' kelimeyi, 'meanings' anlamları (dizi olarak), 'examples' örnekleri belirtir."
                : "Your file must consist of JSON objects within a list (array). 'word' specifies the word, 'meanings' specifies meanings (as an array), and 'examples' specifies examples.",
            exampleCode: """[
  {
    "tts_language": "ing-tr",
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(fontSize: 13.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubFeatureRow(BuildContext context, IconData icon, Color color, String title, String desc) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 20)
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(fontSize: 13.5, height: 1.4, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatCard(BuildContext context, {required String title, required String extension, required Color color, required String explanation, required String exampleCode}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isTr = context.locale.languageCode == 'tr';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: ExpansionTile(
        initiallyExpanded: extension == ".txt", 
        onExpansionChanged: (expanded) {
          if (expanded) HapticFeedback.selectionClick();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text(extension, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(explanation, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 16),
                Text(isTr ? "Örnek Dosya İçeriği:" : "Sample File Content:", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                  ),
                  child: SelectableText(
                    exampleCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isDark ? Colors.greenAccent.shade200 : Colors.indigo.shade900,
                      height: 1.6
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
