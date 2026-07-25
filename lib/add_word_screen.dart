import 'package:flutter/material.dart';
import 'models.dart';

class AddWordScreen extends StatefulWidget {
  final List<String> availableLibraries;
  final Function(WordModel) onSave;

  const AddWordScreen({super.key, required this.availableLibraries, required this.onSave});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _word = '';
  String _level = 'Genel';
  late String _library;
  
  final List<TextEditingController> _meaningControllers = [TextEditingController()];
  final List<TextEditingController> _exampleControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _library = widget.availableLibraries.isNotEmpty ? widget.availableLibraries.first : 'Varsayılan';
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) { c.dispose(); }
    for (var c in _exampleControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Kelime Ekle")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Kelime", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
              onSaved: (v) => _word = v!,
            ),
            const SizedBox(height: 20),
            
            // Çoklu Anlam Alanı
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
            
            // Çoklu Örnek Cümle Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Örnek Cümleler (İsteğe Bağlı)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            // Kütüphane seçimi veya yeni kütüphane oluşturma
            DropdownButtonFormField<String>(
              value: _library,
              decoration: const InputDecoration(labelText: "Kütüphane", border: OutlineInputBorder()),
              items: widget.availableLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _library = v!),
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  
                  List<String> meanings = _meaningControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  List<String> examples = _exampleControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  
                  WordModel newWord = WordModel(
                    word: _word.trim(),
                    meanings: meanings,
                    examples: examples,
                    level: _level,
                    libraryName: _library,
                  );
                  
                  widget.onSave(newWord);
                  Navigator.pop(context);
                }
              },
              child: const Text("KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
