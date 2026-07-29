import 'package:flutter/material.dart';
import 'models.dart';
import 'main.dart'; // globalTts ve "Smart" dil algılama metodlarını kullanmak için eklendi

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

  @override
  void initState() {
    super.initState();
    // Yalnızca WordNet'e ait olan kelimeleri çek (160 bin kelimelik filtreleme)
    baseWords = widget.words.where((w) => w.level == 'WordNet' || w.libraryName.toLowerCase().contains('wordnet')).toList();
    filteredWords = baseWords.take(150).toList(); // Performans için açılışta ilk 150 tanesi
  }

  void updateSearch(String val) {
    setState(() {
      query = val.toLowerCase();
      if (query.isEmpty) {
        filteredWords = baseWords.take(150).toList();
      } else {
        // Hem kelimede hem anlamında hem de eş/zıt anlamlarda arar
        filteredWords = baseWords.where((w) {
          if (w.word.toLowerCase().contains(query)) return true;
          if (w.meanings.any((m) => m.toLowerCase().contains(query))) return true;
          return false;
        }).take(150).toList();
      }
    });
  }

  @override
  void dispose() {
    globalTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("WordNet Kütüphanesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${baseWords.length} Kayıt Yüklü", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: updateSearch,
              decoration: InputDecoration(
                labelText: "Kelime, Anlam, Eş veya Zıt Anlamlı Ara...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          Expanded(
            child: filteredWords.isEmpty 
              ? const Center(child: Text("Kayıt bulunamadı. JSON veya TXT dosyanızı içe aktardığınızdan emin olun."))
              : ListView.builder(
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    var word = filteredWords[index];
                    
                    // ID Gizlenir
                    String displayWord = word.word == "WordNet Terimi" ? "WordNet Kaydı" : word.word;
                    
                    // Alt başlıkta ilk "ANLAM:" gösterilir
                    String subtitleText = "";
                    var definitionList = word.meanings.where((m) => m.startsWith("ANLAM: ")).toList();
                    if (definitionList.isNotEmpty) {
                      subtitleText = definitionList.first.replaceAll('ANLAM: ', '');
                    } else if (word.meanings.isNotEmpty) {
                      subtitleText = word.meanings.first;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(Icons.language, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(displayWord, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        children: [
                          ...word.meanings.map((m) {
                            Color textColor = Colors.black87;
                            IconData iconData = Icons.label;
                            if (Theme.of(context).brightness == Brightness.dark) {
                              textColor = Colors.white70;
                            }
                            
                            // Kategorilere göre harika renk ve ikon kodlaması
                            if (m.startsWith("ANLAM:")) {
                              textColor = Colors.blueAccent;
                              iconData = Icons.menu_book;
                            } else if (m.startsWith("EŞ ANLAMLI:")) {
                              textColor = Colors.green;
                              iconData = Icons.merge_type;
                            } else if (m.startsWith("ZIT ANLAMLI:")) {
                              textColor = Colors.redAccent;
                              iconData = Icons.call_split;
                            }
                            
                            String cleanText = m.replaceAll(RegExp(r'ANLAM: |EŞ ANLAMLI: |ZIT ANLAMLI: '), '');

                            return ListTile(
                              leading: Icon(iconData, color: textColor, size: 20),
                              title: Text(m, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                              trailing: IconButton(
                                icon: const Icon(Icons.volume_up, size: 20),
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
