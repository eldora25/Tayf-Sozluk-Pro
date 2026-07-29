import 'package:flutter/material.dart';
import '../models.dart'; // Model dosyanızın yolu

class WordNetSearchScreen extends StatefulWidget {
  final List<WordModel> words;

  const WordNetSearchScreen({super.key, required this.words});

  @override
  State<WordNetSearchScreen> createState() => _WordNetSearchScreenState();
}

class _WordNetSearchScreenState extends State<WordNetSearchScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Sadece WordNet olarak etiketlenen kelimeleri filtrele
    var wordnetWords = widget.words.where((w) => w.level == 'WordNet').toList();
    
    var filteredList = wordnetWords.where((w) {
      bool matchesWord = w.word.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesMeaning = w.meanings.any((m) => m.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesWord || matchesMeaning;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("WordNet Sözlük"),
            Text("${wordnetWords.length} kelime yüklü", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "İngilizce Kelime veya Anlam Ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        wordnetWords.isEmpty 
                          ? "Henüz WordNet kütüphanesi yüklenmedi.\nAyarlar menüsünden içe aktarabilirsiniz." 
                          : "Aramanıza uygun sonuç bulunamadı.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Icon(Icons.language, color: Colors.white),
                          ),
                          title: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  ...item.meanings.map((m) {
                                    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
                                    FontWeight weight = FontWeight.normal;
                                    IconData iconData = Icons.arrow_right;

                                    if (m.startsWith("Synonym:")) {
                                      textColor = Colors.green;
                                      weight = FontWeight.bold;
                                      iconData = Icons.compare_arrows;
                                    } else if (m.startsWith("Antonym:")) {
                                      textColor = Colors.redAccent;
                                      weight = FontWeight.bold;
                                      iconData = Icons.swap_horiz;
                                    } else {
                                      iconData = Icons.menu_book;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(iconData, size: 18, color: textColor),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(m, style: TextStyle(color: textColor, fontWeight: weight, fontSize: 15))),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
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
