import 'package:flutter/material.dart';
import 'models.dart';
import 'main.dart'; 

class WordNetSearchScreen extends StatefulWidget {
  final List<WordModel> words;
  const WordNetSearchScreen({super.key, required this.words});

  @override
  State<WordNetSearchScreen> createState() => _WordNetSearchScreenState();
}

class _WordNetSearchScreenState extends State<WordNetSearchScreen> {
  String query = "";
  List<WordModel> filteredWords = [];
  List<WordModel> baseWords = [];
  
  double _fontSizeBase = 14.0; // Yazı tipi büyüklüğünü ayarlamak için temel değer

  @override
  void initState() {
    super.initState();
    // Sadece WordNet etiketli veya kütüphane adında wordnet geçen kelimeleri yükle
    baseWords = widget.words.where((w) => w.level == 'WordNet' || w.libraryName.toLowerCase().contains('wordnet')).toList();
    filteredWords = baseWords.take(150).toList();
  }

  void updateSearch(String val) {
    setState(() {
      query = val.toLowerCase();
      if (query.isEmpty) {
        filteredWords = baseWords.take(150).toList();
      } else {
        filteredWords = baseWords.where((w) {
          if (w.word.toLowerCase().contains(query)) return true;
          if (w.meanings.any((m) => m.toLowerCase().contains(query))) return true;
          return false;
        }).take(150).toList(); // Performans için arama sonuçlarını sınırla
      }
    });
  }

  @override
  void dispose() {
    globalTts.stop(); // Ekrandan çıkarken sesi durdur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("WordNet Browser", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${baseWords.length} Kayıt", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          // Yazı Küçültme Butonu
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Yazıyı Küçült',
            onPressed: () {
              if (_fontSizeBase > 10.0) setState(() => _fontSizeBase -= 2.0);
            },
          ),
          // Yazı Büyütme Butonu
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Yazıyı Büyüt',
            onPressed: () {
              if (_fontSizeBase < 24.0) setState(() => _fontSizeBase += 2.0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: updateSearch,
              style: TextStyle(fontSize: _fontSizeBase),
              decoration: InputDecoration(
                labelText: "Kelime, Anlam, Eş/Zıt Anlam Ara...",
                labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: _fontSizeBase),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          Expanded(
            child: filteredWords.isEmpty 
              ? Center(child: Text("Kayıt bulunamadı.", style: TextStyle(fontSize: _fontSizeBase)))
              : ListView.builder(
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    var word = filteredWords[index];
                    
                    // ID Gizleme ve Formatlama
                    String displayWord = word.word == "WordNet Terimi" ? "Kayıt (WordNet)" : word.word;
                    
                    String subtitleText = "";
                    var definitionList = word.meanings.where((m) => m.startsWith("ANLAM: ")).toList();
                    if (definitionList.isNotEmpty) {
                      subtitleText = definitionList.first.replaceAll('ANLAM: ', '');
                    } else if (word.meanings.isNotEmpty) {
                      subtitleText = word.meanings.first;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 4,
                      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: ExpansionTile(
                        iconColor: Theme.of(context).primaryColor,
                        collapsedIconColor: Theme.of(context).primaryColor.withOpacity(0.5),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.language, color: Theme.of(context).primaryColor, size: 24),
                        ),
                        title: Text(
                          displayWord, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSizeBase + 2, color: isDark ? Colors.white : Colors.black87)
                        ),
                        subtitle: Text(
                          subtitleText, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: _fontSizeBase - 2, color: isDark ? Colors.white54 : Colors.black54)
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black12 : Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: word.meanings.map((m) {
                                Color textColor = isDark ? Colors.white70 : Colors.black87;
                                IconData iconData = Icons.label;
                                
                                // Etikete göre dinamik renkler ve ikonlar
                                if (m.startsWith("ANLAM:")) {
                                  textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade800;
                                  iconData = Icons.menu_book;
                                } else if (m.startsWith("EŞ ANLAMLI:")) {
                                  textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
                                  iconData = Icons.merge_type;
                                } else if (m.startsWith("ZIT ANLAMLI:")) {
                                  textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
                                  iconData = Icons.call_split;
                                }
                                
                                String cleanText = m.replaceAll(RegExp(r'ANLAM: |EŞ ANLAMLI: |ZIT ANLAMLI: '), '');

                                return ListTile(
                                  leading: Icon(iconData, color: textColor, size: _fontSizeBase + 4),
                                  title: Text(
                                    m, 
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: _fontSizeBase)
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.volume_up, size: _fontSizeBase + 4, color: isDark ? Colors.grey.shade400 : Colors.grey),
                                    onPressed: () async {
                                      await globalTts.stop();
                                      String lang = getSmartTargetLanguage(word.libraryName, cleanText);
                                      if (word.level == 'WordNet' || word.libraryName.toLowerCase().contains('wordnet')) {
                                        lang = 'en-US';
                                      }
                                      globalTts.setLanguage(lang);
                                      globalTts.speak(cleanText);
                                    },
                                  ),
                                );
                              }).toList()
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
