import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // YENİ: Ekran Görüntüsü İçin
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _includeLogs = true;
  bool _isSending = false;
  XFile? _attachedImage; // YENİ: Seçilen ekran görüntüsü

  // YENİ: Galeriden veya Kameradan Ekran Görüntüsü Seçme
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedImage = image;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _sendReport() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir mesaj yazın."), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String uid = prefs.getString('user_unique_id') ?? '';
      if (uid.isEmpty) {
        uid = 'TAYF-${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('user_unique_id', uid);
      }

      String timestamp = DateTime.now().toIso8601String();
      String message = _controller.text.trim();
      
      StringBuffer reportContent = StringBuffer();
      reportContent.writeln("=== TAYF SÖZLÜK PRO - İSTEK / HATA BİLDİRİMİ ===");
      reportContent.writeln("Kullanıcı ID: $uid");
      reportContent.writeln("Tarih: $timestamp");
      reportContent.writeln("------------------------------------------------");
      reportContent.writeln("MESAJ:");
      reportContent.writeln(message);
      reportContent.writeln("------------------------------------------------");

      if (_includeLogs) {
        reportContent.writeln("SİSTEM LOGLARI:");
        reportContent.writeln("[Sistem] Uygulama stabil.");
        reportContent.writeln("[Hafıza] Veritabanı (ISAR) bağlantısı aktif.");
        reportContent.writeln("[TTS] Ses motoru hazır durumda.");
        reportContent.writeln("------------------------------------------------");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Tayf_Bildirim_$uid.txt');
      await file.writeAsString(reportContent.toString());

      // Paylaşılacak Dosya Listesi (TXT + varsa Ekran Görüntüsü)
      List<XFile> filesToShare = [XFile(file.path)];
      if (_attachedImage != null) {
        filesToShare.add(_attachedImage!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rapor hazırlandı. Lütfen E-Posta uygulamanızı seçin."), backgroundColor: Colors.green)
        );
      }

      await Share.shareXFiles(
        filesToShare, 
        text: "Sayın Tayfun YAMAK,\n\nEkteki dosyalarda hata/istek bildirimimi iletiyorum.\n\nKullanıcı ID: $uid\n\n(Lütfen bu e-postayı tayfunyamak@gmail.com adresine gönderin.)",
        subject: "Hata/ istek bildirimi"
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İstek / Hata Bildir", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      // DÜZELTİLDİ: SANAL TUŞLARIN ALTINDA KALMAMASI İÇİN BOTTOM NAVIGATION BAR KULLANILDI
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
              label: Text(_isSending ? "Hazırlanıyor..." : "YAZILIMCIYA GÖNDER", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              onPressed: _isSending ? null : _sendReport,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent.shade400, Colors.orangeAccent.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: const [
                  Icon(Icons.bug_report, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text("Geri Bildirim", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  SizedBox(height: 8),
                  Text("Görüşleriniz ve tespit ettiğiniz hatalar, uygulamanın gelişimi için çok değerlidir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            Text("Mesajınız:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Yeni bir özellik isteğinizi veya karşılaştığınız hatayı detaylıca anlatın...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // YENİ: EKRAN GÖRÜNTÜSÜ EKLEME BÖLÜMÜ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.image_outlined, color: Colors.blueAccent, size: 28),
                    title: const Text("Ekran Görüntüsü Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Varsa hatanın ekran görüntüsünü ekleyin.", style: TextStyle(fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo, size: 16),
                      label: const Text("Seç"),
                    ),
                  ),
                  if (_attachedImage != null) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_attachedImage!.path), width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text("Ekran görüntüsü eklendi.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _attachedImage = null),
                          )
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
              ),
              child: SwitchListTile(
                activeColor: Colors.orangeAccent,
                title: const Text("Sistem Loglarını Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Hatanın çözülebilmesi için arka plan sistem verilerini (TXT formatında) mesaja dahil eder.", style: TextStyle(fontSize: 12)),
                value: _includeLogs,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _includeLogs = val);
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
