import 'package:flutter/material.dart';
import 'models.dart';

class WordListScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(WordModel) onDelete;
  final Function(WordModel)? onLearned; // YENİ: Sağa kaydırarak öğrenildi işareti

  const WordListScreen({super.key, required this.words, required this.onDelete, this.onLearned});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    var filteredList = widget.words.where((w) => 
      w.word.toLowerCase().contains(searchQuery.toLowerCase()) ||
      w.meanings.join(' ').toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Kelime Listesi")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Kelime veya Anlam Ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                
                // YENİ: KAYDIRARAK İŞLEM (SWIPE TO ACTION)
                return Dismissible(
                  key: Key('${item.word}_$index'),
                  direction: widget.onLearned != null 
                      ? DismissDirection.horizontal 
                      : DismissDirection.endToStart,
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                  ),
                  secondaryBackground: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      widget.words.remove(item);
                    });
                    if (direction == DismissDirection.endToStart) {
                      widget.onDelete(item);
                    } else if (direction == DismissDirection.startToEnd) {
                      if (widget.onLearned != null) widget.onLearned!(item);
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ExpansionTile(
                      // YENİ: HERO ANİMASYONU 
                      title: Hero(
                        tag: 'hero_word_${item.word}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                        ),
                      ),
                      subtitle: Text("${item.libraryName} / ${item.level}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          widget.onDelete(item);
                          setState(() {});
                        },
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ...item.meanings.map((m) => Text("• $m")),
                              const SizedBox(height: 8),
                              if (item.examples.isNotEmpty) const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ...item.examples.map((e) => Text("» $e")),
                            ],
                          ),
                        )
                      ],
                    ),
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
