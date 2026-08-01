# 🚀 Lexis Eldora

Lexis Eldora, sıradan bir sözlük uygulamasının çok ötesinde; **Aralıklı Tekrar Sistemi (SRS - Spaced Repetition System)**, zeki quiz algoritmaları, otonom "mitoz bölünme" kelime zekâsı ve sanatsal olarak oyunlaştırılmış (gamified) bir arayüz ile donatılmış yeni nesil bir dil öğrenme asistanı ve zihin laboratuvarıdır.

Uygulama, milyonlarca kelimelik devasa sözlük veritabanlarını (Babylon, FreeDict vb.) çökmeksizin işleyebilen "Zırhlı Parser" mimarisine sahiptir.

---

## ✨ Öne Çıkan Gelişmiş Özellikler

### 1. 🛡️ Zırhlı İçe Aktarma (Import) ve Temizleme Motoru
Standart CSV/JSON okuyucuların çöktüğü veya veri yuttuğu devasa dosyalar için özel olarak tasarlanmış manuel okuma motoru kullanır.
* **Akıllı Temizleme:** Sözlüklerdeki gereksiz sembolleri `(-III, ;, _, vb.)` ve ASCII çöp karakterleri otonom olarak temizler.
* **Alt-Kelime (Sub-word) Ayrıştırma:** Aynı satırdaki `abandon, abandons, abandoning` gibi yapıları algılar ve her birini bağımsız birer kelime kartı olarak veritabanına ekler.
* **Multiline CSV Zırhı:** Tırnak işaretleri arasında alt satıra (Enter) geçen karmaşık Babylon dosyalarını firesiz ve sıfır kayıpla işler.

### 2. 🧬 Mitoz Bölünme (Hücre Çoğalması) Zekâsı & Eşsizlik Koruması
Öğrenme sürecini ezberden çıkarıp kalıcı ustalığa taşıyan en benzersiz sistemdir.
* Çoklu anlama veya örneğe sahip bir kelime Quiz'de sorulduğunda, sistem **sadece o an sorulan anlamı** orijinal kelimeden koparır.
* Koparılan bu anlam, ISAR veritabanına tamamen bağımsız yeni bir "Saf Kart" (Örn: `Word - Anlam 2`) olarak eklenir ve kendisine özel şifreli bir **DNA Damgası** alır.
* **Büyük/Küçük Harf Koruması:** Sistem tamamen eşsizdir. Oluşan bir mitoz kartı, büyük/küçük harf fark etmeksizin sistemde zaten varsa, kendini çoğaltmaz ve veritabanını çöpe çevirmez.

### 3. 🧠 Zeki Quiz ve Oyunlaştırılmış Ekonomi (TP)
* **Cezalı TP Ekonomisi:** Quizlerde veya eşleştirme oyunlarında yanlış yapıldığında sistem eksi puan yazar ve "Tayf Puanı (TP)" kazanımını düşürür. Seriyi koruyan Buz Kalkanı zorlu bir hedeftir (100 TP).
* **Mantıksal Çeldiriciler:** Quiz şıklarındaki yanlış cevaplar rastgele seçilmez. Başka kelimelerin anlam havuzundan özenle çekilir ve asıl kelimenin hiçbir anlamıyla çakışmadığı teyit edilir.
* **Animasyonlu Şölen:** Quiz esnasında TP kazandığınızda elmaslar uçuşur, neon flash patlamaları yaşanır. Seviye 5'e (Mezuniyet) ulaşan kelimelerde devasa bir konfeti şöleni başlar.

### 4. 🎨 Sanatsal "Glassmorphism" Arayüz
Kullanıcıyı öğrenmeye teşvik eden dinamik ve hiyerarşik görsel ödül sistemi:
* **Buzlu Cam (Frosted Glass):** Alt ve üst menüler buzlu cam efektiyle tasarlanmıştır. Arkasından kayan kelimeler modern ve premium bir derinlik yaratır.
* **Aurora Arka Plan:** Ana ekranda nefes alan, yavaşça hareket eden Aurora degrade arka planları odaklanmayı ve meditasyon hissini artırır.
* **Kademeli (Staggered) Animasyonlar:** Quiz şıkları ve kelime listeleri ekrana küt diye düşmez; yaylanarak ve sırayla (delay) kayarak şık bir şekilde belirir.

### 5. ⚠️ İncelenecek Kelimeler (Karantina) Sistemi
* Kelimeleri çalışırken "!" (Sarı Neon Ünlem) butonuna bastığınızda, kart anında orijinal havuzundan koparılır ve "İncelenecek Kelimeler" karantinasına gönderilir.
* Kullanıcılar bu sayede quizde denk geldikleri hatalı veya düzeltilmeye muhtaç kelimeleri daha sonra ilgilenmek üzere kenara ayırabilirler.

### 6. 🗣️ Kapsamlı ve Akıllı Seslendirme (TTS)
* **Otomatik Dil Tespiti:** Kütüphane ismindeki (İng-Tr) veya kelime içindeki Türkçe karakterlere göre konuşma dilini otomatik belirler.
* **Kesintisiz Çoklu Okuma:** Kart arkası okutulduğunda sadece ilk anlamı değil, tüm anlamları ve örnek cümleleri insansı bir akıcılıkla sonuna kadar okur.
* **Pro İpucu:** Özel import dosyalarında dosya adında `ing-tr` kullanarak veya dosyanın ilk satırına `#tts:ing-tr` parametresi eklenerek ses motoru manuel yönlendirilebilir.

---

## 🛠️ Teknik Altyapı
* **Dil & Framework:** Dart & Flutter
* **Lokal Veritabanı:** ISAR Database (NoSQL, Yüksek Performans)
* **Ses Motoru:** Flutter TTS
* **Sistem Mimarisi:** Zırhlı AST (Derleyiciyi boğmayan izole metot yapısı)

***********************************************
**Geliştirici: Tayfun YAMAK (Eldora)**

**Sürüm: V1.0.x**

**Motto: Mükemmelleşmiş arayüz, zırhlı altyapı.**
***********************************************
