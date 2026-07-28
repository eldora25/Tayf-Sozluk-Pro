import 'package:flutter/material.dart';
import '../models/word_model.dart';

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
  late List<String> _currentLibraries;
  
  final List<TextEditingController> _meaningControllers = [TextEditingController()];
  final List<TextEditingController> _exampleControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _currentLibraries = List.from(widget.availableLibraries);
    if (!_currentLibraries.contains('+ Yeni Kütüphane Oluştur')) {
      _currentLibraries.add('+ Yeni Kütüphane Oluştur');
    }
    _library = widget.availableLibraries.isNotEmpty ? widget.availableLibraries.first : 'Varsayılan';
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) { c.dispose(); }
    for (var c in _exampleControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _showNewLibraryDialog() async {
    TextEditingController newLibCtrl = TextEditingController();
    String? newLibName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Kütüphane"),
        content: TextField(
          controller: newLibCtrl,
          decoration: const InputDecoration(hintText: "Kütüphane adını girin", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (newLibCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, newLibCtrl.text.trim());
              }
            }, 
            child: const Text("Oluştur")
          ),
        ],
      ),
    );

    if (newLibName != null && newLibName.isNotEmpty) {
      setState(() {
        if (!_currentLibraries.contains(newLibName)) {
          _currentLibraries.insert(_currentLibraries.length - 1, newLibName);
        }
        _library = newLibName;
      });
    } else {
      setState(() {
        if (!_currentLibraries.contains(_library)) {
          _library = _currentLibraries.first;
        }
      });
    }
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
            DropdownButtonFormField<String>(
              value: _library,
              decoration: const InputDecoration(labelText: "Kütüphane", border: OutlineInputBorder()),
              items: _currentLibraries.map((e) {
                if (e == '+ Yeni Kütüphane Oluştur') {
                  return DropdownMenuItem(
                    value: e, 
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(e, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    )
                  );
                }
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (v) {
                if (v == '+ Yeni Kütüphane Oluştur') {
                  _showNewLibraryDialog();
                } else {
                  setState(() => _library = v!);
                }
              },
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
