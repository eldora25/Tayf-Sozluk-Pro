import 'package:flutter/material.dart';
import '../models/word_model.dart';

class AddWordScreen extends StatefulWidget {
  final List<String> libraries;
  final Function(WordModel) onWordAdded;

  const AddWordScreen({Key? key, required this.libraries, required this.onWordAdded}) : super(key: key);

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _word = '';
  final List<TextEditingController> _meaningControllers = [TextEditingController()];
  final List<TextEditingController> _exampleControllers = [TextEditingController()];
  String _selectedLevel = 'Genel';
  late String _selectedLibrary;

  @override
  void initState() {
    super.initState();
    _selectedLibrary = widget.libraries.first;
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) {
      c.dispose();
    }
    for (var c in _exampleControllers) {
      c.dispose();
    }
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
              decoration: const InputDecoration(labelText: "Kelime (İngilizce / Hedef Dil)", border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? "Bu alan boş bırakılamaz" : null,
              onSaved: (v) => _word = v ?? '',
            ),
            const SizedBox(height: 16),
            
            // Dinamik Anlam Ekleme Bölümü
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text("Anlamlar (Çoklu Giriş)", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => setState(() => _meaningControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._meaningControllers.map((controller) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextFormField(controller: controller, decoration: const InputDecoration(hintText: "Anlam girin...", border: OutlineInputBorder())),
            )),
            const SizedBox(height: 16),

            // Dinamik Örnek Cümle Ekleme Bölümü
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text("Örnek Cümleler", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () => setState(() => _exampleControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._exampleControllers.map((controller) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextFormField(controller: controller, decoration: const InputDecoration(hintText: "Örnek cümle veya kullanım...", border: OutlineInputBorder())),
            )),
            const SizedBox(height: 16),

            // Seviye ve Kütüphane Seçimi
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: const InputDecoration(labelText: "Seviye", border: OutlineInputBorder()),
              items: ['A1','A2','B1','B2','C1','C2','Genel'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLevel = v ?? 'Genel'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLibrary,
              decoration: const InputDecoration(labelText: "Kütüphane", border: OutlineInputBorder()),
              items: widget.libraries.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLibrary = v ?? 'test'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  
                  List<String> meanings = _meaningControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  List<String> examples = _exampleControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                  if (meanings.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En az bir anlam girmelisiniz!")));
                    return;
                  }

                  widget.onWordAdded(WordModel(
                    word: _word,
                    meanings: meanings,
                    examples: examples,
                    level: _selectedLevel,
                    libraryName: _selectedLibrary,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet ve Kütüphaneye Ekle", style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
