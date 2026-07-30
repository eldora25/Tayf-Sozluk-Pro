
çalışan başarılı build Build #94: Commit bdb47fa
Build #99: Commit 0602bd7   3 . çalışan istatistikler,kelime düzenle, sil işlevi
Build #104: Commit 953ffad 4. çalışan quiz ayraları , yazılar vb
Build #129: Commit 58d7e79  5. çalışan optimizasyon sorunu var
Build #139: Commit 61a4f13 çalışan 6 optimizasyon ve birkaç ayar
Build #145: Commit a90dad3 çalışan 7 temalar
Build #152: Commit 1dc39d8 çalışan 8 istatistikler
Build #156: Commit ea33aa3 çalışan 9 optimizasyon
Build #166: Commit dfbe9f2 çalısan 10 optimizasyon

**************************************************************************
                     MODERNİZASYON
**************************************************************************
                         ISAR
**************************************************************************
Build #186: Commit 7a99799 ISAR DATABASE GEÇİŞİ YAPILDI
**************************************************************************
Leitner Algoritması, öğrenmeyi kolaylaştıran ve bilginin uzun süre akılda kalmasını sağlayan aralıklı tekrar (SRS) yöntemi kuruldu
**************************************************************************
Ateşli Seri (Streak) Sistemi: Kullanıcı art arda her gün uygulamaya girip kelime öğrendiğinde ana ekranda yanan bir ateş emojisi (🔥) ve "5 Günlük Seri!" yazısı gösteren sistem kuruldu. Bir gün girmezse seri kırılır. Seri Dondurma (Streak Freeze): Kullanıcının seriyi bozmamak için satın alabileceği veya kazanabileceği "pas geçme" hakkı sistemi kuruldu. Seri Dondurma (Buz Kalkanı ❄️) İçin Sistem ve Entegrasyonu yapıldı.
Kullanıcının uygulamada yaptığı her öğrenme işlemi (Kelimeyi 'Biliyorum' demek veya Quiz çözmek) ona Tayf Puan (TP 💎) kazandırır.
Eğer kullanıcı bir gün girmeyi unutursa ve serisinin kırılmasından korkarsa, menüdeki mağazadan biriktirdiği 50 TP karşılığında 1 Buz Kalkanı (❄️) satın alabilir.
Kalkan aktifken kullanıcı 1 gün uygulamaya girmese bile arka plandaki zaman damgası kontrolü "Kalkanı kırar" ama Seriyi korur.
**************************************************************************





Build #82: Commit 9bfde04  ilk apk buildi
Build #94: Commit bdb47fa   2,

Yeni özellikler eklendi 
özellik ekleme denemesi başarılı Build #99: Commit 0602bd7   3 . çalışan istatistikler,kelime düzenle, sil işlevi
özellik ekleme denemesi:Kütüphane ve Seviye seçimleri buraya taşındı. Cihazların sanal tuşlarının (navigasyon bar) butonu kapatmaması için ekran kaydırılabilir (SingleChildScrollView) yapıldı ve buton bir miktar yukarıya alındı.Quiz ekranı baştan aşağı yenilendi. Süre ölçer (Timer), doğru/yanlış sayaçları eklendi. Soru başına çoklu anlamlardan sadece biri seçiliyor ve doğru bilinmeden diğer soruya geçilmiyor. Doğru ve Yanlış tıklandığında ses efekti olarak TTS kullanılıyor.Footer (V.1.0... ve By: Tayfun YAMAK) eklendi. İhracat (Export) işlemi Android platformunun kısıtlamalarını aşmak için getDirectoryPath() ile kullanıcıya klasör seçtirilerek güvenli yola uyarlandı. Drawer'dan Kütüphane/Seviye Seç kaldırılıp sadece Ayarlara yönlendirildi.

Build #104: Commit 953ffad 4. başarılı up
özellik ekleme denemesi:Dışa aktarma işlemini "Paylaşım" üzerinden güvenle yapabilmek için share_plus eklentisini ekledik.
İstediğin hazır test paketini ve İngilizce sözlüğün bir kısmını içeren kütüphane dosyası. Bunu lib/ klasörü altına oluştur.Paketler menüsü eklendi.Seçenek kutuları kalınlaştırıldı, Quiz Sonu İstatistik Ekranı yapıldı ve "yanlış cevapta bekletip doğruyu bulana kadar geçmeme" özelliği koda işlendi.Paylaşma fonksiyonu, Footer'ın konumu ve ||| ayrıştırma mekanizması koda eklendi.
Build #129: Commit 58d7e79  Bu dosyaya uygulamanın her yerinden erişilebilen ve metnin İngilizce mi yoksa Türkçe mi olduğunu anında anlayan akıllı dil tespit motorunu (detectLanguage) ekledik İstediğin Kütüphane Yönetim merkezi! Kütüphaneleri listeler, öğrenme barlarını çizer, çark ikonuna basıldığında Ad Değiştirme, Silme ve Dışa Aktarma seçeneklerini sunar. Seçeneklerin ekrandan taşmasını önlemek için Satır sınırlandırması yapıldı. Çapraz dil seslendirmesi (Doğru/Yanlış, Correct/Wrong) entegre edildi. Sağ üste hoparlör aç/kapa butonu eklendi ve kelimeye dokunarak okutma sistemi kodlandı. İçe aktarılan Babylon dosyalarındaki #name, version gibi kelime yutan çöpleri silen filtre eklendi. Gelen metinler |||, ;, , ve \n işaretleriyle kusursuzca kısa maddelere bölündü ve akıllı dille seslendirme sisteme entegre edildi. Hazır paketler listesine 5. seçenek olarak Free-KH sözlüğü mor renkli tasarımıyla eklendi.

özellik ekleme denemesi:Öğrenilen, Yanlış Yapılan ve Tekrarlanması Gereken kelimelerin özel olarak yönetilebileceği, sayıların görülebileceği ve "Tümünü Sil" seçeneği barındıran yepyeni liste yönetim ekranımız.Quiz Soru Sayısı, Tema seçimi ve limitleri 2-50 arasına çekilen Eşik Değeri ayarları eklendi.Quiz, ayarlanan soru sayısına göre kelime havuzu oluşturur. Bitiminde hedef dile göre ("Tebrikler" / "Congratulations") sesli mesaj okur. Görsel tema sistemi ThemeData olarak tanımlandı. Drawer'a (Yan Menü) Yanlışlar, Tekrar Edilecekler ve Öğrenilenler listeleri sayılarıyla birlikte özel List Yönetim Ekranı'na gidecek şekilde eklendi. "Kelime Listesi" butonu artık sadece seçili kütüphaneyi getiriyor.

Build #145: Commit a90dad3 çalışan 7 özellik ekleme denemesi:Kütüphane isminden ve akıllı sistemden dil çıkaran fonksiyon eklendi.Sayfanın en altındaki taşıma ve kopyalama butonlarının sanal tuşların altında kalmaması için liste sonuna bottom: 120 padding eklendi.Doğru/Yanlış ve Tebrikler seslendirmesi çapraz dil mantığıyla güncellendi. "Await" beklemeleri kaldırılarak arayüzün saniyesinde tepki vermesi sağlandı.Detaylı istatistik ve kütüphane bazlı analiz ekranı.Kayıp menüler, global istatistik kayıtları ve akıllı dil motoru entegre edildi.

Build #152: Commit 1dc39d8 çalışan 8 özellik ekleme denemesi:(4. sekme olan "Öğrenme Hızı" arayüzü ve zaman hesaplama mantığı eklendi)
(Zaman damgaları belleğe eklendi, eylemler loglanmaya başlandı ve Drawer SafeArea ile alttan sanal tuşlardan kurtarıldı)

Build #156: Commit ea33aa3 çalışan 9 optimizasyon vb. (Dropdown menüsüne Pembe ve Rengarenk seçenekleri eklendi) (Akıllı ve öncelikli dil tespit motoru eklendi.) (Yavaşlatan dil değişimleri kaldırıldı. İngilizceye -> Correct, Türkçeye -> Doğru mantığı oturtuldu.) Babylon ve Tayf dosyaları için Arka Plan İşlemcisi (Isolate/Compute) sistemi kuruldu. Hem UTF-8 hem Latin1(Windows-1254) şifreleme desteği ve Yükleniyor (Loading) ekranı ile donma/çökme sorunları tamamen çözüldü.(Uygulamanın her yerinden erişilebilen hata yakalama motoru ve logları gösteren arayüz ekranı)(Ana fonksiyonda otomatik Hata Yakalayıcılar (FlutterError & PlatformDispatcher) eklendi. Isolate fonksiyonu RAM tüketimini azaltacak şekilde JSON tabanlı hale getirildi. Yan menüye (Drawer) Logger butonu kondu.)
