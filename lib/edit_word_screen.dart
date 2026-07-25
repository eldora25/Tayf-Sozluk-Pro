import 'package:flutter/material.dart';
import 'models.dart';

enum EditAction { update, delete, copy, move }

class EditWordScreen extends StatefulWidget {
  final WordModel word;
  final List<String> availableLibraries;
  final Function(EditAction, WordModel) onAction;

  const EditWordScreen({
    super.key,
    required this.word,
    required this.availableLibraries,
    required this.onAction,
  });

  @override
  State<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends State<EditWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _wordText;
  late String _level;
  late String _library;
  
  late List<TextEditingController> _meaningControllers;
  late List<TextEditingController> _exampleControllers;

  @override
  void initState() {
    super.initState();
    _wordText = widget.word.word;
    _level = widget.word.level;
    _library = widget.word.libraryName;

    _meaningControllers = widget.word.meanings.isNotEmpty 
        ? widget.word.meanings.map((m) => TextEditingController(text: m)).toList()
        : [TextEditingController()];
        
    _exampleControllers = widget.word.examples.isNotEmpty
        ? widget.word.examples.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) { c.dispose(); }
    for (var c in _exampleControllers) { c.dispose(); }
    super.dispose();
  }

  WordModel _getUpdatedWord() {
    return WordModel(
      word: _wordText.trim(),
      meanings: _meaningControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      examples: _exampleControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      level: _level,
      libraryName: _library,
      correctCount: widget.word.correctCount,
      wrongCount: widget.word.wrongCount,
    );
  }

  void _submitAction(EditAction action) {
    if (action == EditAction.delete) {
      widget.onAction(action, widget.word);
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onAction(action, _getUpdatedWord());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sanal kütüphaneleri filtrele (Kopyalama/Taşıma hedefi olamazlar)
    var realLibraries = widget.availableLibraries.where((lib) => lib != 'Tekrarlanması Gerekenler').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelimeyi Düzenle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Sil',
            onPressed: () => _submitAction(EditAction.delete),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _wordText,
              decoration: const InputDecoration(labelText: "Kelime", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
              onSaved: (v) => _wordText = v!,
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Anlamlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => setState(() => _meaningControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._meaningControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Kelimenin anlamı...", border: OutlineInputBorder()),
                validator: (v) => _meaningControllers.indexOf(controller) == 0 && v!.isEmpty ? "En az bir anlam girmelisiniz" : null,
              ),
            )),
            
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Örnek Cümleler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () => setState(() => _exampleControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._exampleControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Örnek cümle...", border: OutlineInputBorder()),
              ),
            )),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: "Seviye", border: OutlineInputBorder()),
              items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _level = v!),
            ),
            
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: realLibraries.contains(_library) ? _library : realLibraries.first,
              decoration: const InputDecoration(labelText: "Kütüphane", border: OutlineInputBorder()),
              items: realLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _library = v!),
            ),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: () => _submitAction(EditAction.update),
                    child: const Text("GÜNCELLE"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () => _submitAction(EditAction.copy),
                    child: const Text("KOPYALA"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    onPressed: () => _submitAction(EditAction.move),
                    child: const Text("TAŞI"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
