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
  final TextEditingController _searchController = TextEditingController();
  String query = "";
  List<WordModel> filteredWords = [];
  List<WordModel> baseWords = [];
  
  // Klasik WordNet Arayüz Seçenekleri
  List<String> searchHistory = [];
  bool showGloss = true;
  bool wrapLines = true;
  String currentViewMode = "Overview"; // Overview, Synonyms, Antonyms

  @override
  void initState() {
    super.initState();
    baseWords = widget.words.where((w) => w.level == 'WordNet' || w.libraryName.toLowerCase().contains('wordnet')).toList();
  }

  void _performSearch(String val) {
    if (val.trim().isEmpty) return;
    
    setState(() {
      query = val.trim().toLowerCase();
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        if (searchHistory.length > 15) searchHistory.removeLast();
      }

      filteredWords = baseWords.where((w) {
        if (w.word.toLowerCase() == query) return true;
        if (w.meanings.any((m) => m.toLowerCase().contains(query))) return true;
        return false;
      }).take(200).toList();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      query = "";
      filteredWords.clear();
    });
  }

  @override
  void dispose() {
    globalTts.stop();
    _searchController.dispose();
    super.dispose();
  }

  // Anlam listesinden verileri ayıran yardımcı fonksiyon
  Map<String, dynamic> _parseMeanings(List<String> rawMeanings) {
    String definition = "";
    List<String> synonyms = [];
    List<String> antonyms = [];

    for (var m in rawMeanings) {
      if (m.startsWith("ANLAM: ")) {
        definition = m.replaceAll("ANLAM: ", "").trim();
      } else if (m.startsWith("EŞ ANLAMLI: ")) {
        synonyms.add(m.replaceAll("EŞ ANLAMLI: ", "").trim());
      } else if (m.startsWith("ZIT ANLAMLI: ")) {
        antonyms.add(m.replaceAll("ZIT ANLAMLI: ", "").trim());
      }
    }
    return {
      "definition": definition,
      "synonyms": synonyms,
      "antonyms": antonyms,
    };
  }

  // Klasik WordNet satırını çizen widget (Aranan kelime kırmızı vurgulu)
  Widget _buildClassicSenseRow(int index, String mainWord, Map<String, dynamic> parsedData) {
    List<String> syns = List<String>.from(parsedData["synonyms"]);
    String def = parsedData["definition"];
    
    // Bütün eş anlamlıları ve ana kelimeyi birleştir
    List<String> allWords = [if (mainWord != "WordNet Terimi") mainWord, ...syns];
    if (allWords.isEmpty) allWords.add("Term");

    List<TextSpan> spans = [];
    spans.add(TextSpan(text: "${index + 1}. ", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal)));

    for (int i = 0; i < allWords.length; i++) {
      String w = allWords[i];
      bool isMatch = query.isNotEmpty && w.toLowerCase().contains(query);
      spans.add(TextSpan(
        text: w,
        style: TextStyle(
          color: isMatch ? Colors.red : Colors.black,
          fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
        ),
      ));
      if (i < allWords.length - 1) {
        spans.add(const TextSpan(text: ", ", style: TextStyle(color: Colors.black)));
      }
    }

    if (showGloss && def.isNotEmpty) {
      spans.add(const TextSpan(text: " -- (", style: TextStyle(color: Colors.black54)));
      spans.add(TextSpan(text: def, style: const TextStyle(color: Colors.black87)));
      spans.add(const TextSpan(text: ")", style: TextStyle(color: Colors.black54)));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              softWrap: wrapLines,
              overflow: wrapLines ? TextOverflow.clip : TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, fontFamily: 'Times New Roman', height: 1.4),
                children: spans,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await globalTts.stop();
              String textToSpeak = def.isNotEmpty ? def : allWords.first;
              globalTts.setLanguage("en-US");
              globalTts.setSpeechRate(0.45);
              globalTts.speak(textToSpeak);
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.volume_up, size: 16, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Klasik Windows gri pencere arkaplanı
      appBar: AppBar(
        title: const Text("WordNet 2.1 Browser", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Klasik Menü Çubuğu (File, History, Options)
          Container(
            color: const Color(0xFFE0DFE3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), foregroundColor: Colors.black),
                  child: const Text("File"),
                ),
                PopupMenuButton<String>(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text("History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                  ),
                  itemBuilder: (context) => searchHistory.isEmpty 
                    ? [const PopupMenuItem(value: "", child: Text("No history"))]
                    : searchHistory.map((h) => PopupMenuItem(value: h, child: Text(h))).toList(),
                  onSelected: (val) {
                    if (val.isNotEmpty) {
                      _searchController.text = val;
                      _performSearch(val);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text("Options", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                  ),
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      checked: showGloss,
                      value: "gloss",
                      child: const Text("Show descriptive gloss"),
                    ),
                    CheckedPopupMenuItem(
                      checked: wrapLines,
                      value: "wrap",
                      child: const Text("Wrap lines"),
                    ),
                  ],
                  onSelected: (val) {
                    setState(() {
                      if (val == "gloss") showGloss = !showGloss;
                      if (val == "wrap") wrapLines = !wrapLines;
                    });
                  },
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), foregroundColor: Colors.black),
                  child: const Text("Help"),
                ),
              ],
            ),
          ),
          
          // 2. Arama Çubuğu (Search Word:)
          Container(
            color: const Color(0xFFF0F0F0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text("Search Word: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400)),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(bottom: 14, left: 4),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  InkWell(
                    onTap: _clearSearch,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.clear, size: 18),
                    ),
                  )
              ],
            ),
          ),
          
          // 3. Alt Menü (Searches for X: [Senses] [Dropdown])
          if (query.isNotEmpty)
            Container(
              color: const Color(0xFFF0F0F0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text("Searches for $query: ", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE0DFE3), border: Border.all(color: Colors.grey)),
                      child: Row(
                        children: [
                          Text(currentViewMode, style: const TextStyle(fontSize: 12, color: Colors.black)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "Overview", child: Text("Overview", style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: "Synonyms", child: Text("Synonyms, ordered by estimated frequency", style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: "Antonyms", child: Text("Antonyms", style: TextStyle(fontSize: 12))),
                    ],
                    onSelected: (val) => setState(() => currentViewMode = val),
                  ),
                  const Spacer(),
                  Text("Senses: ${filteredWords.length}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
          const Divider(height: 1, thickness: 1, color: Colors.grey),

          // 4. Ana Beyaz Görüntüleme Ekranı (WordNet Çıktısı)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: filteredWords.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty ? "Welcome to WordNet Browser.\nEnter a word to search." : "No senses found for '$query'.",
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12.0),
                      children: [
                        Text("The word $query has ${filteredWords.length} senses", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 16),
                        ...List.generate(filteredWords.length, (index) {
                          WordModel w = filteredWords[index];
                          var parsedData = _parseMeanings(w.meanings);
                          
                          // Eğer filtre Modu Eş Anlamlıysa ve kelimede eş anlamlı yoksa atla
                          if (currentViewMode == "Synonyms" && parsedData["synonyms"].isEmpty) return const SizedBox.shrink();
                          if (currentViewMode == "Antonyms" && parsedData["antonyms"].isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClassicSenseRow(index, w.word, parsedData),
                              
                              if (currentViewMode == "Synonyms" || currentViewMode == "Overview")
                                ...parsedData["synonyms"].map<Widget>((syn) => Padding(
                                  padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
                                  child: Text("=> $syn", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                )).toList(),

                              if (currentViewMode == "Antonyms" || currentViewMode == "Overview")
                                ...parsedData["antonyms"].map<Widget>((ant) => Padding(
                                  padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
                                  child: Text("=> Antonym: $ant", style: const TextStyle(fontSize: 13, color: Colors.red)),
                                )).toList(),
                              
                              if (index < filteredWords.length - 1) const SizedBox(height: 8),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
          ),
          
          // Alt Bilgi Çubuğu (Status bar)
          Container(
            height: 20,
            color: const Color(0xFFE0DFE3),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(query.isNotEmpty ? "$currentViewMode of $query" : "Ready", style: const TextStyle(fontSize: 11, color: Colors.black)),
          )
        ],
      ),
    );
  }
}
