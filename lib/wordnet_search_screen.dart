import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  
  String query = "";
  List<WordModel> filteredWords = [];
  List<WordModel> baseWords = [];
  
  // Arayüz Ayarları
  double _fontSizeBase = 15.0; 
  Color? _customFontColor; // Kullanıcının seçtiği font rengi
  List<String> searchHistory = [];
  bool showGloss = true;
  bool wrapLines = true;
  String currentViewMode = "Overview"; 

  // Hazır Font Renkleri
  final List<Color> _fontColors = [
    Colors.black87,
    Colors.white,
    Colors.blueGrey.shade900,
    Colors.deepPurple,
    Colors.teal.shade900,
    Colors.brown.shade800,
  ];

  @override
  void initState() {
    super.initState();
    // Hem eski JSON okuyucu formatını hem de yeni direkt WordNet objelerini yakalar.
    baseWords = widget.words.where((w) {
      bool isOldFormat = w.level == 'WordNet' || w.libraryName.toLowerCase().contains('wordnet');
      bool isNewFormat = w.pos.isNotEmpty || w.synonyms.isNotEmpty || w.antonyms.isNotEmpty;
      return isOldFormat || isNewFormat;
    }).toList();
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
        // Eğer aranan kelime anlamlar, eş anlamlılar veya zıt anlamlılar içindeyse bul
        if (w.meanings.any((m) => m.toLowerCase().contains(query))) return true;
        if (w.synonyms.any((s) => s.toLowerCase().contains(query))) return true;
        if (w.antonyms.any((a) => a.toLowerCase().contains(query))) return true;
        return false;
      }).take(300).toList(); 
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

  // Eğer veri eski TXT/JSON formatında (ANLAM: EŞ ANLAMLI: vs) kaydedildiyse ayrıştırır,
  // Yeni şemadaki gerçek parametreleri (w.synonyms) varsa onları kullanır.
  Map<String, dynamic> _getParsedData(WordModel w) {
    String definition = "";
    List<String> synonyms = [];
    List<String> antonyms = [];

    // Yeni Isar Şeması Önceliği
    if (w.pos.isNotEmpty || w.synonyms.isNotEmpty || w.antonyms.isNotEmpty) {
      definition = w.meanings.isNotEmpty ? w.meanings.first : "";
      synonyms = w.synonyms;
      antonyms = w.antonyms;
    } else {
      // Eski Metin Tabanlı Format (Fallback)
      for (var m in w.meanings) {
        if (m.startsWith("ANLAM: ")) {
          definition = m.replaceAll("ANLAM: ", "").trim();
        } else if (m.startsWith("EŞ ANLAMLI: ")) {
          synonyms.add(m.replaceAll("EŞ ANLAMLI: ", "").trim());
        } else if (m.startsWith("ZIT ANLAMLI: ")) {
          antonyms.add(m.replaceAll("ZIT ANLAMLI: ", "").trim());
        } else if (definition.isEmpty) {
          definition = m; // Saf tanım direkt eklendiyse
        }
      }
    }

    return {
      "pos": w.pos.isNotEmpty ? w.pos : "",
      "definition": definition,
      "synonyms": synonyms,
      "antonyms": antonyms,
    };
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Metin Rengi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _fontColors.map((color) => GestureDetector(
            onTap: () {
              setState(() => _customFontColor = color);
              Navigator.pop(context);
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
              ),
              child: _customFontColor == color ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white) : null,
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal"))
        ],
      )
    );
  }

  Widget _buildClassicSenseRow(int index, WordModel w, Map<String, dynamic> parsedData) {
    List<String> syns = List<String>.from(parsedData["synonyms"]);
    String def = parsedData["definition"];
    String pos = parsedData["pos"];
    
    String mainWord = w.word.contains('[ID:') ? "WordNet Kaydı" : w.word;
    
    List<String> allWords = [if (mainWord != "WordNet Kaydı") mainWord, ...syns];
    if (allWords.isEmpty) allWords.add("Term");

    List<TextSpan> spans = [];
    Color baseTextColor = _customFontColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    
    spans.add(TextSpan(text: "${index + 1}. ", style: TextStyle(color: baseTextColor, fontWeight: FontWeight.normal)));

    if (pos.isNotEmpty) {
      spans.add(TextSpan(text: "($pos) ", style: TextStyle(color: Theme.of(context).primaryColor, fontStyle: FontStyle.italic)));
    }

    for (int i = 0; i < allWords.length; i++) {
      String wordStr = allWords[i];
      bool isMatch = query.isNotEmpty && wordStr.toLowerCase().contains(query);
      spans.add(TextSpan(
        text: wordStr,
        style: TextStyle(
          color: isMatch ? Colors.redAccent : baseTextColor,
          fontWeight: isMatch ? FontWeight.bold : FontWeight.w600,
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
      padding: const EdgeInsets.only(bottom: 16.0),
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
              child: Icon(Icons.volume_up, size: _fontSizeBase + 6, color: Theme.of(context).primaryColor.withOpacity(0.7)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = _customFontColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("WordNet 2.1 Browser", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.format_color_text), tooltip: 'Yazı Rengi', onPressed: _showColorPicker),
          IconButton(icon: const Icon(Icons.text_decrease), tooltip: 'Yazıyı Küçült', onPressed: () { if (_fontSizeBase > 10.0) setState(() => _fontSizeBase -= 2.0); }),
          IconButton(icon: const Icon(Icons.text_increase), tooltip: 'Yazıyı Büyüt', onPressed: () { if (_fontSizeBase < 30.0) setState(() => _fontSizeBase += 2.0); }),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Text("Search Word: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(bottom: 10, left: 10),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearSearch) : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text("Searches for '$query': ", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Text(currentViewMode, style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, size: 18, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "Overview", child: Text("Overview", style: TextStyle(fontSize: 13))),
                      const PopupMenuItem(value: "Synonyms", child: Text("Synonyms, ordered by frequency", style: TextStyle(fontSize: 13))),
                      const PopupMenuItem(value: "Antonyms", child: Text("Antonyms", style: TextStyle(fontSize: 13))),
                    ],
                    onSelected: (val) => setState(() => currentViewMode = val),
                  ),
                  const Spacer(),
                  Text("Senses: ${filteredWords.length}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
          const Divider(height: 1, thickness: 1),

          // 4. WordNet Okuma Ekranı (Klasik Çıktı)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: filteredWords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.travel_explore, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(query.isEmpty ? "Welcome to WordNet Browser.\nEnter a word to search." : "No senses found for '$query'.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      )
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView(
                        padding: const EdgeInsets.all(20.0),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Text("The word '$query' has ${filteredWords.length} senses in WordNet:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSizeBase, color: Theme.of(context).primaryColor)),
                          const SizedBox(height: 20),
                          ...List.generate(filteredWords.length, (index) {
                            WordModel w = filteredWords[index];
                            var parsedData = _getParsedData(w);
                            
                            if (currentViewMode == "Synonyms" && parsedData["synonyms"].isEmpty) return const SizedBox.shrink();
                            if (currentViewMode == "Antonyms" && parsedData["antonyms"].isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClassicSenseRow(index, w, parsedData),
                                
                                if (currentViewMode == "Synonyms" || currentViewMode == "Overview")
                                  ...parsedData["synonyms"].map<Widget>((syn) => Padding(
                                    padding: const EdgeInsets.only(left: 32.0, bottom: 6.0),
                                    child: Text("=> Synonym: $syn", style: TextStyle(fontSize: _fontSizeBase - 2, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                                  )).toList(),

                                if (currentViewMode == "Antonyms" || currentViewMode == "Overview")
                                  ...parsedData["antonyms"].map<Widget>((ant) => Padding(
                                    padding: const EdgeInsets.only(left: 32.0, bottom: 6.0),
                                    child: Text("=> Antonym: $ant", style: TextStyle(fontSize: _fontSizeBase - 2, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                  )).toList(),
                                
                                if (index < filteredWords.length - 1) 
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(color: Colors.grey.withOpacity(0.2)),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Alt Bar
          Container(
            height: 28,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(query.isNotEmpty ? "$currentViewMode of '$query'" : "Ready", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
