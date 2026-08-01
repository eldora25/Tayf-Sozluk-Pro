import 'package:flutter/material.dart';
import 'models.dart';

class WordListScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(WordModel) onDelete;
  final Function(WordModel)? onLearned; 

  const WordListScreen({super.key, required this.words, required this.onDelete, this.onLearned});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  String searchQuery = '';

  Widget _buildAnimatedItem(BuildContext context, int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 20) * 50)), 
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ZIRHLI FORMAT: Derleyicinin AST derinliğinde çökmemesi için Mitoz Rozeti dışarı aktarıldı
  Widget _buildMitosisBadge(WordModel item) {
    final String dnaCode = "DNA-" + item.id.toString().padLeft(6, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30, width: 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 6, offset: const Offset(-2, 0)),
                  BoxShadow(color: Colors.purpleAccent.withOpacity(0.6), blurRadius: 6, offset: const Offset(2, 0)),
                ],
              ),
              child: const Text(
                "\u{1F9EC}", 
                style: TextStyle(
                  fontSize: 10, 
                  shadows: [
                    Shadow(color: Colors.orangeAccent, blurRadius: 10),
                    Shadow(color: Colors.purpleAccent, blurRadius: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 10),
                  const SizedBox(width: 4),
                  Text(dnaCode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = widget.words.where((w) => 
      w.word.toLowerCase().contains(searchQuery.toLowerCase()) ||
      w.meanings.join(' ').toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 110.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Kelime Listesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Kelime veya Anlam Ara...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),
          ),
          filteredList.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text("Kelime bulunamadı.", style: TextStyle(fontSize: 16, color: Colors.grey))),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      
                      final bool isMitosis = item.libraryName.startsWith('\u{1F9EC}');
                      final String dismissKey = item.word + '_' + index.toString();
                      final String heroTag = 'hero_word_' + item.word;
                      final String subtitleText = item.libraryName + " / " + item.level;
                      
                      return _buildAnimatedItem(
                        context, 
                        index,
                        RepaintBoundary(
                          child: Dismissible(
                            key: Key(dismissKey),
                            direction: widget.onLearned != null 
                                ? DismissDirection.horizontal 
                                : DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
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
                                final learnCb = widget.onLearned;
                                if (learnCb != null) learnCb(item);
                              }
                            },
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isMitosis ? BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5) : BorderSide.none
                              ),
                              color: isMitosis ? Colors.purpleAccent.withOpacity(0.05) : Theme.of(context).cardColor,
                              child: ExpansionTile(
                                title: Hero(
                                  tag: heroTag,
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Text(item.word, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isMitosis ? Colors.purpleAccent : Colors.deepPurple)),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(subtitleText),
                                    if (isMitosis) _buildMitosisBadge(item), // ZIRHLI ÇAĞRI
                                  ],
                                ),
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
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                        ...item.meanings.map((m) => Text("• $m", style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4))),
                                        const SizedBox(height: 8),
                                        if (item.examples.isNotEmpty) const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                        ...item.examples.map((e) => Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4))),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),
        ],
      ),
    );
  }
}
