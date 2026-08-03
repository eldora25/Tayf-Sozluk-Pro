import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
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
  List<WordModel> _searchResults = [];
  bool _isLoading = false;

  void _searchWord(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    String lowerQuery = query.toLowerCase().trim();

    try {
      // YENİ: Doğrudan Isar veritabanından WordNet kelimelerini hızlıca çek
      List<WordModel> results = await isar.wordModels
          .filter()
          .libraryNameEqualTo('WordNet Veritabanı')
          .and()
          .wordContains(lowerQuery, caseSensitive: false)
          .limit(50)
          .findAll();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WordNet Browser", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "WordNet'te İngilizce Ara (Örn: apple, run)...",
                prefixIcon: const Icon(Icons.travel_explore, color: Colors.indigo),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchWord('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.indigo.withOpacity(0.05),
              ),
              onChanged: _searchWord,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty ? "Arama yapmak için bir kelime yazın." : "Sonuç bulunamadı.",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      WordModel item = _searchResults[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.indigo.withOpacity(0.2), width: 1.5),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            item.word,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                          ),
                          subtitle: Text("WordNet [${item.pos.toUpperCase()}]", style: TextStyle(color: Colors.indigo.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Tanım (Definition):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                                  const SizedBox(height: 4),
                                  ...item.meanings.map((m) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Text("• $m", style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
                                      )),
                                  if (item.examples.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 4),
                                    ...item.examples.map((e) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
                                        )),
                                  ]
                                ],
                              ),
                            ),
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
