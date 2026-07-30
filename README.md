# 🚀 Tayf Sözlük Pro

Tayf Sözlük Pro, sıradan bir sözlük uygulamasının çok ötesinde; **Aralıklı Tekrar Sistemi (SRS - Spaced Repetition System)**, zeki quiz algoritmaları, otonom "mitoz bölünme" kelime zekâsı ve sanatsal olarak oyunlaştırılmış (gamified) bir arayüz ile donatılmış yeni nesil bir dil öğrenme asistanıdır.

Uygulama, milyonlarca kelimelik devasa sözlük veritabanlarını (Babylon, FreeDict vb.) çökmeksizin işleyebilen "Zırhlı Parser" mimarisine sahiptir.

---

## ✨ Öne Çıkan Gelişmiş Özellikler

### 1. 🛡️ Zırhlı İçe Aktarma (Import) ve Temizleme Motoru
Standart CSV/JSON okuyucuların çöktüğü veya veri yuttuğu devasa dosyalar için özel olarak tasarlanmış manuel okuma motoru kullanır.
* **Akıllı Temizleme:** Sözlüklerdeki gereksiz sembolleri `(-III, ;, _, vb.)` ve ASCII çöp karakterleri otonom olarak temizler.
* **Alt-Kelime (Sub-word) Ayrıştırma:** Aynı satırdaki `abandon, abandons, abandoning` gibi yapıları algılar ve her birini bağımsız birer kelime kartı olarak veritabanına ekler.
* **Multiline CSV Zırhı:** Tırnak işaretleri arasında alt satıra (Enter) geçen karmaşık Babylon dosyalarını firesiz ve sıfır kayıpla işler.

### 2. 🧬 Mitoz Bölünme (Hücre Çoğalması) Zekâsı
Öğrenme sürecini ezberden çıkarıp kalıcı ustalığa taşıyan en benzersiz sistemdir.
* Çoklu anlama veya örneğe sahip bir kelime Quiz'de sorulduğunda, sistem **sadece o an sorulan anlamı** orijinal kelimeden koparır.
* Koparılan bu anlam, ISAR veritabanına tamamen bağımsız yeni bir "Öğrenme Kartı" (Örn: `Word - Anlam 2`) olarak eklenir.
* Orijinal kart, kalan anlamlarıyla havuzda sırasını beklemeye devam ederken, bilinen anlam kendi SRS yolculuğuna başlar.

### 3. 🧠 Zeki Quiz ve Çeldirici Makinesi
* **Mantıksal Çeldiriciler:** Quiz şıklarındaki yanlış cevaplar rastgele seçilmez. Başka kelimelerin anlam havuzundan özenle çekilir ve **asıl kelimenin hiçbir anlamıyla çakışmadığı** algoritma tarafından teyit edilir.
* **Taşmaz Arayüz:** Şık metinleri ne kadar uzun olursa olsun (max 6 satır), butonlar asla patlamaz, ekrana dinamik olarak sığar.
* **Çakışma Kilidi:** Quiz'den gönderilen Biliyorum/Tekrar sinyallerinin, ana ekrandaki ses motorunu ve kart atlama yapısını bozmasını engelleyen otonom bir güvenlik kilidi vardır.

### 4. 🎨 Oyunlaştırılmış (Gamified) Sanatsal Arayüz
Kullanıcıyı öğrenmeye teşvik eden dinamik ve hiyerarşik görsel ödül sistemi:
* **Ortalanmış Güvenli Kapsüller:** Üst menüde (AppBar) yer alan Ateş (Seri) ve Elmas (TP) ikonları, hiçbir cihazda taşmayacak şekilde tam ortaya, "MainAxisSize.min" kuralıyla sabitlenmiştir.
* **Kat Kat Büyüyen SRS Çerçeveleri:** Kart seviyesi arttıkça, çerçevenin kalınlığı otonom olarak artar (Seviye 1'den 5'e doğru genişler).
* **Zıt Kontrast Renkler:** Her SRS seviyesinin karakteri vardır: Sarı (1), Neon Mor (2), Buz Mavisi (3), Ateş Kırmızısı (4) ve Zümrüt Yeşili (5).
* **Evrimleşen Taç Sistemi:** Kartların üzerinde seviye 1'de küçük bir amblemle başlayan ikon, seviye 5'e ulaşıldığında yapraklar, elmaslar ve yıldızlarla dolu sanatsal bir "Kraliyet Tacı"na (Crown) dönüşür.

### 5. 🗣️ Kapsamlı ve Akıllı Seslendirme (TTS)
* **Otomatik Dil Tespiti:** Kütüphane ismindeki (İng-Tr) veya kelime içindeki Türkçe karakterlere göre konuşma dilini otomatik belirler.
* **Kesintisiz Çoklu Okuma:** Kart arkası okutulduğunda sadece ilk anlamı değil, **tüm anlamları ve örnek cümleleri** aralarına nokta (es/nefes) koyarak insansı bir akıcılıkla sonuna kadar okur.
* **Pro İpucu (Manuel Yönlendirme):** Özel import dosyalarında dosya adında `ing-tr` kullanarak veya dosyanın ilk satırına `#tts:ing-tr` parametresi eklenerek ses motoru manuel olarak yönlendirilebilir.

### 6. ⚙️ Asenkron Yönetim ve Öncelik Zırhı
* **Aciliyet Kilidi:** Uygulama açıldığında destede "Günü Gelmiş" SRS kartları varsa, sistem önceki kalınan indeksi siler ve kullanıcıyı zorla 0. indekse (en başa) atarak bu kartları gösterir.
* **Dinamik Düzenleme:** Listeler (ManageListScreen) üzerinden kelimeler (mitozla bölünmüş olanlar dahil) düzenlendiğinde, asenkron (`Future`) yapı sayesinde tüm ana listeler, havuzlar ve ekranlar anında eşzamanlı olarak yenilenir.

### 7. 📬 Gelişmiş "İstek / Hata Bildir" Sistemi
* Kullanıcılara otomatik olarak eşsiz bir cihaz/kullanıcı ID'si atanır.
* Kullanıcılar, sorunlarını ve isteklerini uygulama içindeki şık "Report Screen" üzerinden yazabilir.
* Sistem o anki zaman damgası, kullanıcı ID'si, mesaj ve **Sistem Loglarını** içeren bir `.txt` dosyası oluşturarak konuyu ve paketi doğrudan e-posta istemcisine (`tayfunyamak@gmail.com` adresine yollanmak üzere) aktarır.

---

## 🛠️ Teknik Altyapı
* **Dil & Framework:** Dart & Flutter
* **Lokal Veritabanı:** ISAR Database (NoSQL, Yüksek Performans)
* **Ses Motoru:** Flutter TTS
* **Dosya İşlemleri:** File Picker, Path Provider
* **Dışa/İçe Aktarım:** CSV, JSON, TXT parsing, Share Plus

---

## 📂 Önerilen İçe Aktarma (Import) Formatları

Sistemin tts dilini otonom tanıması için dosyalarınızın başına `#tts:ing-tr` (veya hedeflenen dil) parametresini ekleyebilirsiniz.

**1. TXT Formatı**


```text
#tts:ing-tr
apple : elma ; meyve
book : kitap ; rezervasyon yapmak
```

2. CSV Formatı

 ```  
#tts:ing-tr
Word,Meaning,Example,Level
apple,elma ||| meyve,I ate an apple.,Başlangıç


```
**3. JSON Formatı**

```

[
  {
    "tts_language": "ing-tr",
    "word": "resilient",
    "meanings": ["dirençli", "çabuk iyileşen"],
    "examples": ["She is a resilient person."],
    "level": "İleri"
  }
]


```
***********************************************
Geliştirici: Tayfun YAMAK (Eldora)

Sürüm: V1.0.x

Motto: Mükemmelleşmiş arayüz, zırhlı altyapı.
***********************************************
