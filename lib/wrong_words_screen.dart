import 'package:flutter/material.dart';
import '../models/word_model.dart';

class WrongWordsScreen extends StatelessWidget {
  final List<WrongWordModel> wrongWords;

  const WrongWordsScreen({Key? key, required this.wrongWords}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yanlış Kelimeler")),
      body: wrongWords.isEmpty
          ? const Center(child: Text("Harika! Hiç yanlış kelimeniz yok."))
          : ListView.builder(
              itemCount: wrongWords.length,
              itemBuilder: (context, index) {
                final item = wrongWords[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(item.wordInfo.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("Anlamı: ${item.wordInfo.meanings.join(', ')}\nKaynak: ${item.wordInfo.libraryName} / ${item.wordInfo.level}"),
                    trailing: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(item.wrongCount.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
