import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'models.dart';

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
  double _fontSizeBase = 14.0; 
  List<String> searchHistory = [];
  bool showGloss = true;
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
    return {"definition": definition, "synonyms": synonyms, "antonyms": antonyms};
  }

  Widget _buildClassicSenseRow(int index, String mainWord, Map<String, dynamic> parsedData) {
    List<String> syns = List<String>.from(parsedData["synonyms"]);
    String def = parsedData["definition"];
    
    List<String> allWords = [if (mainWord != "WordNet Terimi") mainWord, ...syns];
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
          // Aranan kelime WordNet klasiğindeki gibi kırmızı (veya temanın vurgu renginde) olur
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
              text: TextSpan(
                style: TextStyle(fontSize: _fontSizeBase, fontFamily: 'Georgia', height: 1.5),
                children: spans,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await _tts.stop();
              await Future.delayed(const Duration(milliseconds: 150));
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
        title: const Text("WordNet Browser", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.text_decrease), tooltip: 'Yazıyı Küçült', onPressed: () { if (_fontSizeBase > 10.0) setState(() => _fontSizeBase -= 2.0); }),
          IconButton(icon: const Icon(Icons.text_increase), tooltip: 'Yazıyı Büyüt', onPressed: () { if (_fontSizeBase < 24.0) setState(() => _fontSizeBase += 2.0); }),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arama Kutusu ve Klasik Dropdown Menüler
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _performSearch,
                        style: TextStyle(fontSize: _fontSizeBase),
                        decoration: InputDecoration(
                          hintText: "Search Word...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch) : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (query.isNotEmpty)
                  Row(
                    children: [
                      Text("Searches for $query: ", style: TextStyle(fontSize: _fontSizeBase - 2, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: currentViewMode,
                        underline: const SizedBox(),
                        style: TextStyle(fontSize: _fontSizeBase - 2, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: "Overview", child: Text("Overview")),
                          DropdownMenuItem(value: "Synonyms", child: Text("Synonyms")),
                          DropdownMenuItem(value: "Antonyms", child: Text("Antonyms")),
                        ],
                        onChanged: (val) => setState(() => currentViewMode = val!),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // Klasik Oku(ma) Ekranı
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: filteredWords.isEmpty
                  ? Center(child: Text(query.isEmpty ? "Enter a word to search." : "No senses found for '$query'.", style: TextStyle(fontSize: _fontSizeBase, color: Colors.grey)))
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
                              if (currentViewMode == "Antonyms")
                                ...parsedData["antonyms"].map<Widget>((ant) => Padding(
                                  padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
                                  child: Text("=> Antonym: $ant", style: TextStyle(fontSize: _fontSizeBase - 1, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                )).toList(),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
