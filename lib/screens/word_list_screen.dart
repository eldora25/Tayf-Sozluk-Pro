import 'package:flutter/material.dart';
import '../models/word_model.dart';

class WordListScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(WordModel) onWordDeleted;

  const WordListScreen({Key? key, required this.words, required this.onWordDeleted}) : super(key: key);

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.words.where((w) => w.word.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Kelime Listesi")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Kelime ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text("Listelenecek kelime bulunamadı."))
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ExpansionTile(
                          title: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                          subtitle: Text("${item.libraryName} / ${item.level}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              widget.onWordDeleted(item);
                              setState(() {});
                            },
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Alignment(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ...item.meanings.map((m) => Text("• $m")),
                                    const SizedBox(height: 8),
                                    const Text("Örnek Cümleler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    item.examples.isEmpty 
                                        ? const Text("Örnek bulunmuyor.") 
                                        : InkWithoutMaterial(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: item.examples.map((e) => Text("» $e")).toList())),
                                  ],
                                ),
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
