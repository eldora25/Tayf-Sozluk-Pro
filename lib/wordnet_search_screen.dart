import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'models.dart';
import 'main.dart'; // TTS dillerini akıllıca çekmek için

class WordNetSearchScreen extends StatefulWidget {
  final List<WordModel> words;
  const WordNetSearchScreen({super.key, required this.words});

  @override
  State<WordNetSearchScreen> createState() => _WordNetSearchScreenState();
}

class _WordNetSearchScreenState extends State<WordNetSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  
  String query = "";
  List<WordModel> filteredWords = [];
  List<WordModel> baseWords = [];
  
  // Arayüz Ayarları (Klasik Browser Seçenekleri)
  double _fontSizeBase = 14.0; 
  List<String> searchHistory = [];
  bool showGloss = true;
  bool wrapLines = true;
  String currentViewMode = "Overview"; 

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
        String cleanWord = w.word.contains('[ID:') ? "WordNet Kaydı" : w.word;
        if (cleanWord.toLowerCase() == query) return true;
        if (w.meanings.any((m) => m.toLowerCase().contains(query))) return true;
        return false;
      }).take(200).toList(); // Performans için limitle
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
    _tts.stop();
    _searchController.dispose();
    super.dispose();
  }

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

  Widget _buildClassicSenseRow(int index, String rawWord, Map<String, dynamic> parsedData) {
    List<String> syns = List<String>.from(parsedData["synonyms"]);
    String def = parsedData["definition"];
    
    String mainWord = rawWord.contains('[ID:') ? "WordNet Kaydı" : rawWord;
    
    List<String> allWords = [if (mainWord != "WordNet Kaydı") mainWord, ...syns];
    if (allWords.isEmpty) allWords.add("Term");

    List<TextSpan> spans = [];
    Color baseTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    
    spans.add(TextSpan(text: "${index + 1}. ", style: TextStyle(color: baseTextColor, fontWeight: FontWeight.normal)));

    for (int i = 0; i < allWords.length; i++) {
      String w = allWords[i];
      bool isMatch = query.isNotEmpty && w.toLowerCase().contains(query);
      spans.add(TextSpan(
        text: w,
        style: TextStyle(
          color: isMatch ? Colors.redAccent : baseTextColor,
          fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
        ),
      ));
      if (i < allWords.length - 1) {
        spans.add(TextSpan(text: ", ", style: TextStyle(color: baseTextColor)));
      }
    }

    if (showGloss && def.isNotEmpty) {
      spans.add(TextSpan(text: " -- (", style: TextStyle(color: baseTextColor.withOpacity(0.6))));
      spans.add(TextSpan(text: def, style: TextStyle(color: baseTextColor.withOpacity(0.9))));
      spans.add(TextSpan(text: ")", style: TextStyle(color: baseTextColor.withOpacity(0.6))));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              softWrap: wrapLines,
              overflow: wrapLines ? TextOverflow.clip : TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: _fontSizeBase, fontFamily: 'Georgia', height: 1.5),
                children: spans,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await _tts.stop();
              await Future.delayed(const Duration(milliseconds: 250));
              String textToSpeak = def.isNotEmpty ? def : allWords.first;
              _tts.setLanguage("en-US");
              _tts.speak(textToSpeak);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Icon(Icons.volume_up, size: _fontSizeBase + 4, color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("WordNet 2.1 Browser", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.text_decrease), tooltip: 'Yazıyı Küçült', onPressed: () { if (_fontSizeBase > 10.0) setState(() => _fontSizeBase -= 2.0); }),
          IconButton(icon: const Icon(Icons.text_increase), tooltip: 'Yazıyı Büyüt', onPressed: () { if (_fontSizeBase < 24.0) setState(() => _fontSizeBase += 2.0); }),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Üst Menü Simülasyonu
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text("History", style: TextStyle(fontWeight: FontWeight.w600)),
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text("Options", style: TextStyle(fontWeight: FontWeight.w600)),
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
              ],
            ),
          ),
          
          // 2. Arama Çubuğu
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text("Search Word: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: _clearSearch) : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Alt Menü
          if (query.isNotEmpty)
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text("Searches for $query: ", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
                      child: Row(
                        children: [
                          Text(currentViewMode, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "Overview", child: Text("Overview", style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: "Synonyms", child: Text("Synonyms, ordered by frequency", style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: "Antonyms", child: Text("Antonyms", style: TextStyle(fontSize: 12))),
                    ],
                    onSelected: (val) => setState(() => currentViewMode = val),
                  ),
                  const Spacer(),
                  Text("Senses: ${filteredWords.length}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
          const Divider(height: 1, thickness: 1),

          // 4. WordNet Okuma Ekranı (Klasik Çıktı)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: filteredWords.isEmpty
                  ? Center(child: Text(query.isEmpty ? "Welcome to WordNet Browser.\nEnter a word to search." : "No senses found for '$query'.", style: const TextStyle(color: Colors.grey, fontSize: 14)))
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text("The word '$query' has ${filteredWords.length} senses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSizeBase, color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 16),
                        ...List.generate(filteredWords.length, (index) {
                          WordModel w = filteredWords[index];
                          var parsedData = _parseMeanings(w.meanings);
                          
                          if (currentViewMode == "Synonyms" && parsedData["synonyms"].isEmpty) return const SizedBox.shrink();
                          if (currentViewMode == "Antonyms" && parsedData["antonyms"].isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClassicSenseRow(index, w.word, parsedData),
                              
                              if (currentViewMode == "Synonyms" || currentViewMode == "Overview")
                                ...parsedData["synonyms"].map<Widget>((syn) => Padding(
                                  padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
                                  child: Text("=> $syn", style: TextStyle(fontSize: _fontSizeBase - 1)),
                                )).toList(),

                              if (currentViewMode == "Antonyms" || currentViewMode == "Overview")
                                ...parsedData["antonyms"].map<Widget>((ant) => Padding(
                                  padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
                                  child: Text("=> Antonym: $ant", style: TextStyle(fontSize: _fontSizeBase - 1, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                )).toList(),
                              
                              if (index < filteredWords.length - 1) const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
          ),
          
          // Alt Bar
          Container(
            height: 24,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(query.isNotEmpty ? "$currentViewMode of '$query'" : "Ready", style: const TextStyle(fontSize: 11)),
          )
        ],
      ),
    );
  }
}
