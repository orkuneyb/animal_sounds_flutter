# Animal Sounds — büyüme analizi (15 Kasım 2026)

Play'de yayındaki sürüm: v1.4.0+12, 10 B+ indirme, 5,0 puan, 24 yorum, 30 hayvan, 8 dil.
Bu dalda hazırlanan sürüm: v1.5.0+13, 50 hayvan, yeni çizimler ve yeni arayüz (ayrıntı 9. bölümde). Henüz yayınlanmadı.
Rakipler mağaza sayfalarından incelendi; bu makinede emülatör olmadığı için hiçbiri kurulup oynanmadı.

## 1. En önemli sonuçlar

1. **Bulunabilirlik sorunu var, ürün sorunu değil.** "animal sounds" aramasında 20., "hayvan sesleri" aramasında 19. sıradayız; "for kids", "for toddlers", "çocuklar için" aramalarının ilk ~20 sonucunda yokuz. Play'in "Benzer" rayında tek bir hayvan sesi uygulaması çıkmıyor; mağaza bizi bu kümeyle eşleştirmiyor.
2. **Mağaza sayfası zayıf kurulmuş.** Başlık 30 karakterin 13'ünü kullanıyor, kategori "Casual" oyun (rakiplerin çoğu Educational), tanıtım videosu yok, Türkçe kısa açıklama Türkçe karaktersiz.
3. **İçerik azdı.** Rakipler 50–170 hayvan sunuyor; yayındaki sürümde 30 hayvan var, 1.5.0 ile 50'ye çıktı.
4. **Tutundurma özellikleri sessizce bozuktu.** Haftalık görevler hiç ilerlemiyordu, 20 başarıdan 3'ü açılamıyordu. Bu oturumda düzeltildi.
5. **Yorum istemi hiç çıkmıyordu.** Açılış sayacı her açılışta eziliyordu; 10 B indirmede 24 yorumun nedeni bu. 1.5.0'da düzeltildi.
6. **Güçlü yanımız rakiplerin en çok şikâyet aldığı yerler:** her dilde sesli anlatım, çevrimdışı çalışma, ucuz tek seferlik reklam kaldırma, günlük keşif ve rozetler.

## 2. Mağaza sayfası bulguları

| Konu | Şu an | Öneri |
|---|---|---|
| Başlık (EN) | "Animal Sounds" (13) | "Animal Sounds for Kids: Learn" (29) |
| Başlık (TR) | "Hayvan Sesleri" (14) | "Hayvan Sesleri: Çocuk Oyunları" (30) |
| Kısa açıklama (EN) | "Learn 30+ animal sounds with quizzes…" | "50 animal sounds for toddlers: quiz, guess the sound, coloring. Works offline." (78), 1.5.0 yayınlanınca; o zamana kadar "30" |
| Kısa açıklama (TR) | "30+ hayvan sesi, bilgi yarismasi, boyama ve gunluk kesiflerle ogren!" | "50 hayvan sesi: bilgi yarışması, sesi tahmin et, boyama. İnternetsiz çalışır." (77), 1.5.0 yayınlanınca; o zamana kadar "30" |
| Kategori | Casual (oyun) | Educational |
| Video | Yok | Bu oturumda üretildi, YouTube'a yüklenmeli |
| Ekran görüntüleri | 8 adet, küçük telefon ve küçük yazı | Bu oturumda yeniden üretildi |
| Simge | Yapay zekâ kırmızı panda; uygulamada panda yok, çizim tarzı da farklı | Uygulamadaki bir hayvanla (aslan) yeni simge |

Düzeltilecek metin hataları:
- "30+" yazıyor, yayındaki sürümde tam 30 hayvan var. 1.5.0 yayınlanınca "50" yazın.
- İngilizce açıklamada "no in-app purchases required" var; sayfa "Uygulama içi satın alma" etiketli. Cümleyi "tek seferlik isteğe bağlı reklam kaldırma" olarak değiştirin.
- Türkçe açıklamada "KARŞIAŞTIRMA" yazım hatası var.
- `store_listings.txt` içindeki Türkçe metnin tamamı Türkçe karaktersiz; Console'a oradan kopyalanırsa hata geri gelir.

Politika riski: Data safety "veri toplanmıyor" diyor, ancak uygulama Firebase Analytics, Crashlytics ve AdMob kullanıyor. Families programında bu beyan uyuşmazlığı uygulamanın kaldırılmasına kadar gidebilir. Formu güncelleyin ve uygulamaya gizlilik politikası bağlantısı ekleyin.

## 3. Rakipler

| Rakip | İndirme | Puan / yorum | Hayvan | Görsel | Gelir | Video |
|---|---|---|---|---|---|---|
| EMC Apps — Animal Sounds | 5 M+ | 4,5 / 12,9 B | 170+ | Fotoğraf | Reklam | Yok |
| Papumba — Animal Sounds | 5 M+ | 4,0 / 39,7 B | 80+ | Çizgi film | Uygulama içi satın alma | Yok |
| Micky Appz — 150 Animal Sounds | 5 M+ | 4,1 / 37 B | 150+ | Fotoğraf | Reklam + satın alma | Var |
| PXL Apps — Animal Sounds | 1 M+ | 4,2 / 109 B | 160+ | Fotoğraf | Reklam + reklam kaldırma | Yok |
| Dream_Studio — Animal Sounds | 1 M+ | 4,5 / 8,9 B | doğrulanamadı | Fotoğraf | Reklam + satın alma | Yok |
| Sadgun — Animal Sounds for Kids | 1 M+ | 3,9 / 2,7 B | doğrulanamadı | Çizgi film | Reklam + satın alma | Yok |
| Mama papa — Kids learn | 1 M+ | 4,0 / 5,7 B | doğrulanamadı | Fotoğraf | Reklam | Yok |
| Amaya Kids — games for babies | 500 B+ | 3,9 / 1,1 B | 90+ | Animasyonlu çizgi film | Yalnız çiftlik ücretsiz | Var |
| Beyazay — Hayvan Sesleri Tanı-Bul | 500 B+ | TR 4,3 / 1,2 B | 50 | Çizgi film | Reklam | Var |
| Alyaka — Bebek Oyunları | 100 B+ | TR 4,9 | 35 | Çizgi film | Reklamsız, tek seferlik Premium | Yok |

Rakiplerde olup bizde olmayan: çok daha fazla hayvan, habitat sahneleri, yapboz/hafıza/eşleştirme oyunları, şarkı ve ninniler, zil sesi yapma, "Teacher Approved" rozeti (Papumba, Mama papa, Amaya), 13–42 dil.

Bizde olup onlarda görülmeyen: günlük keşif ve seri, 20 başarı, haftalık görevler, karşılaştırma modu, ses kaydı, kullanım istatistikli ebeveyn paneli, her dilde sesli anlatım.

Rakip yorumlarında tekrar eden şikâyetler: çocuğun reklama basıp uygulamadan çıkması, seslendirmenin gerçekten yerelleşmemesi, çevrimdışı çalışmama, arama olmaması, ücret duvarı. İlk üçü bizim güçlü olduğumuz yerler; mağaza metninde öne çıkarılmalı.

## 4. Uygulama bulguları

### 15 Kasım'da düzeltilenler

| Sorun | Düzeltme |
|---|---|
| Haftalık görevler hiç ilerlemiyordu (`ChallengeProvider.incrementProgress` hiçbir yerden çağrılmıyordu) | Ses, bilgi, quiz, favori, keşif ve oyun olaylarına bağlandı; her görev açıklamasındaki koşulu sayıyor (ör. "5 çiftlik hayvanı dinle" yalnızca farklı çiftlik hayvanlarını, "ipucusuz quiz" yalnızca ipucu kullanılmayan quizi) |
| `first_favorite`, `collector`, `super_collector` başarıları açılamıyordu | Favori sayısına bağlandı |
| 7 günlük seri rozeti 4. günde, 30 günlük 8. günde açılıyordu | Seri uzunluğu artık doğrudan ilerleme değeri |
| "30 hayvanın hepsini dinle" aynı hayvanı 30 kez çalınca açılıyordu | Artık tekil hayvan sayılıyor (bilgi sayfası rozeti de) |
| Başarı penceresine iki kez dokununca alttaki sayfa da kapanıyordu | Pencere yalnızca bir kez kapanıyor; aynı anda açılan iki pencere de kendiliğinden kapanıyor |
| Keşfet sekmesinde koleksiyon satırı dar telefonlarda taşıyordu | Sığdığı kadar kutu gösteriyor |
| Ses seviyeleri arasında ~27 LU fark vardı (yunus çok yüksek, yılan neredeyse sessiz) | 25 dosya yeniden kodlandı, 5'i zaten hedefteydi. 28 dosya -15 ile -18 LUFS arasında; domuz -19,9'da kaldı. Fark ~27 LU'dan ~5 LU'ya indi |

15 Kasım sonunda 125 test geçiyordu; 16 Kasım sonunda 146.

Telefonda denendi (OPPO CPH2109, Android 12): yayın derlemesi kurulu 1.3.0'ın üstüne güncelleme olarak kuruldu ve çökmeden açıldı. Favori rozeti, görev ilerlemesi (farklı hayvan sayımı, quiz), koleksiyon satırı, başarı penceresine çift dokunma ve yeniden açılışta ilerlemenin korunması telefonda doğrulandı. Seri rozeti, oyun görevleri ve aynı anda açılan iki pencere yalnızca testlerle doğrulandı. Sesler ölçüldü ama kulakla dinlenmedi; 11–17 dB yükseltilen ayı, timsah, kurbağa, baykuş, yılan ve kurt seslerinde dip gürültüsü artmış olabilir, yayından önce telefonda dinleyin.

"Deniz Sesleri" görevi artık ana ekrandaki Su grubundaki hayvanları sayıyor (yunus, balina, timsah, fok).

### Açık kalanlar (önem sırasıyla)

Aşağıdaki listede 1, 3 (ses sayfasındaki reklam düğmesi ve banner kayması), 4, 6, 7, 8 ve 10'un tablet ve ölü kod kısımları 1.5.0'da kapandı; 5 büyük ölçüde kapandı (9. bölüme bakın). 2 (ebeveyn kapısı), 9 (kedi ve çita ses kalitesi), quizdeki ödüllü reklamlar, onboarding ve erişilebilirlik etiketlerinin tamamı hâlâ açık.

1. **Yorum istemi.** Yalnızca ebeveyn paneli açılınca tetikleniyor; ayrıca açılış sayacı büyük olasılıkla eziliyor (`main.dart` → `usage_stats_provider.dart`, cihazda doğrulanmadı). Tetiği ebeveyn kapısının geçildiği her ana ve satın alma sonrasına taşıyın.
2. **Ebeveyn kapısı zayıf.** 4 şıklı, sınırsız deneme; rastgele dokunan çocuk geçer. Satın alma bu kapının arkasında.
3. **Çocuk ekranında ödüllü reklam çağrısı.** Ses sayfasında "eğlenceli bilgi için reklam izle" düğmesi var; aynı bilgi bilgi sayfasında ücretsiz. Banner yüklenince içeriği aşağı itiyor, yanlış dokunma riski yaratıyor.
4. **9 hayvan hiçbir kategoride yok:** penguen, zebra, timsah, yılan, kurbağa, koala, kanguru, çita, tilki. Kategori bilgisi iki ayrı yerde tutuluyor.
5. **Karşılaştırma çubukları İngilizce dışında yanlış.** Sayılar çevrilmiş metinden ayrıştırılıyor; Arapçada hepsi sıfır çıkıyor.
6. **Bilgi sayfası 2–6 yaş için fazla metin ağırlıklı.** "Males: 1.7-2.5 meters" gibi veriler, 30×30 dokunma hedefleri, başlık görselinde hayvanın başı kesiliyor.
7. **Ana ekranda bilgi düğmesi hayvanın yüzünün üstüne biniyor.**
8. **Çizim tarzı tutarsız.** 30 görsel farklı kaynaklardan; penguen Linux maskotu Tux (kullanımı çizerine atıf şartına bağlı, uygulamada atıf yok). Çözünürlük 256 px ile 2000 px arasında. Görsellerin kaynak ve lisans kaydı depoda yok.
9. **Ses kalitesi.** Kedi 8 kHz, çita 11 kHz; seviye düzeldi ama bu dosyalar yeniden kaynaklanmalı.
10. Onboarding yok, tablet düzeni 2 sütunda sabit, erişilebilirlik etiketi yok, `lib/pages/home.dart` (882 satır) ölü kod.

## 5. Bu oturumda üretilen mağaza dosyaları

`docs/store-assets/en-US/` ve `docs/store-assets/tr-TR/` altında:
- `phone_01.png` … `phone_08.png` — 1080×1920 ekran görüntüleri, güncel sürümün gerçek ekranlarından
- `feature_graphic.png` — 1024×500 banner
- `promo_video.mp4` — 31,5 sn, 1920×1080, uygulamanın kendi hayvan sesleriyle

Her klasördeki `onizleme.jpg` sekiz ekran görüntüsünü tek sayfada gösterir.

Video hareketli ekran kaydı değil, gerçek ekranlardan kurulmuş bir slayt gösterisi. Diğer 6 dil için görsel üretilmedi. Quiz ve tahmin ekranlarının içeriği her çekimde rastgele değişir; yeniden üretirseniz penguenin (Tux) karede olmadığını kontrol edin.

Yeniden üretmek için:

```bash
flutter test scripts/store_assets/capture_test.dart --dart-define=SHOT_LOCALE=tr-TR --dart-define=SHOT_STEPS=all
```

```bash
python scripts/store_assets/compose.py
```

```bash
python scripts/store_assets/video.py
```

## 6. Play Console'da yapılacaklar

1. Yeni ekran görüntülerini ve banner'ı EN ve TR için yükleyin.
2. Videoyu YouTube'a yükleyin (herkese açık veya liste dışı, reklamsız) ve bağlantısını ekleyin.
3. Başlık ve kısa açıklamayı 2. bölümdeki önerilerle değiştirin; metin hatalarını düzeltin.
4. Kategoriyi Educational yapın.
5. Data safety formunu güncelleyin.
6. Başlık ve ekran görüntülerini mağaza deneyi (A/B) olarak yayınlayın; dönüşüm farkını ölçün.

## 7. Yeni hayvanlar

20 yeni hayvan 1.5.0'da eklendi; ayrıntı 9. bölümde. Yeni bir hayvan eklemek için: `scripts/art/svg/<ad>.svg` çizimi, `assets/animal_sounds/<ad>.mp3` sesi, `animal_repository.dart` sonuna bir satır, `scripts/i18n/new_animals/` altına 8 dilde 10 metin ve `python scripts/i18n/add_animals.py <ad>`.

## 8. Önerilen sıra

1. Play Console adımları (6. bölüm) — kod gerektirmez, en hızlı etki.
2. 1.5.0'ı yayınlamadan önce: 20 yeni sesi dinleyin, panda sesinin kaynağına karar verin, yeni çevirileri okutun.
3. 1.5.0'ı yayınlayın; mağaza metnini ve görsellerini aynı anda güncelleyin.
4. Sonraki sürüm: yeni simge, ebeveyn kapısı, quizde yeni hayvanlar, Keşfet/Oyunlar/Profil sekmelerinin yeni düzeni, hafıza/eşleştirme oyunu, onboarding.

## 9. 16 Kasım güncellemesi: 1.5.0

Bu bölüm, yukarıdaki analizden sonra yapılanları özetler. Üstteki bölümlerde "açık" görünen bazı maddeler burada kapanmıştır.

### Yapılanlar

- **50 hayvan.** 20 yeni hayvan eklendi: keçi, eşek, tavuk, hindi, kaz, papağan, kartal, karga, martı, guguk kuşu, tavus kuşu, güvercin, kuğu, sırtlan, geyik, panda, fok, cırcır böceği, fare, sincap.
- **Tek tarzda çizimler.** 50 hayvanın hepsi yeniden çizildi. Kaynak dosyalar `scripts/art/svg/` altında; `python scripts/art/render.py` uygulama görsellerini üretir. Linux pengueni (Tux) ve karışık kaynaklı eski görseller kaldırıldı.
- **Yeni sesler.** Kaynak ve lisans kaydı `docs/credits/sounds.md` içinde. 13'ü kamu malı ya da CC0, 7'si CC BY (atıf gerektirir); atıflar uygulamada Profil > Ses kaynakları sayfasında.
- **Yeni ana ekran.** Yazılı çipler yerine resimli gruplar (Çiftlik, Vahşi, Kuşlar, Su, Minikler). Kartta yalnızca hayvan ve adı var. Tablette sütun sayısı artıyor.
- **Yeni ses ekranı.** Hayvanın kendi rengi, büyük oynat düğmesi, oklarla ya da kaydırarak sonraki hayvana geçiş. "Bilgi için reklam izle" düğmesi kaldırıldı.
- **Yeni bilgi ekranı.** Nerede yaşar, ne yer, ne kadar büyük: her biri bir resim ve bir kelime, dokununca sesli okunur. Uzun metinler "Daha fazla bilgi" altında.
- **Veri tek kaynakta.** Hayvan eklemek artık `animal_repository.dart` içinde tek satır; gruplar, koleksiyon, görevler ve rozet hedefleri bu listeden türetiliyor. Bir test, her hayvanın görseli, sesi ve 8 dildeki metni olduğunu denetliyor.
- **Yorum istemi hatası.** Açılış sayacı her açılışta kayıtlı değerle eziliyordu, bu yüzden "5 açılış" koşulu hiç sağlanmıyordu. Düzeltildi.
- **Reklam alanı.** Ana ekranda banner için yer baştan ayrılıyor; reklam yüklenince içerik aşağı kaymıyor. Tam ekran reklam yalnızca ses ekranı listeden açılırken sayılıyor, ok tuşlarında değil.

146 test geçiyor. Yayın derlemesi OPPO CPH2109 (Android 12) üzerinde denendi: grup filtresi, ses ekranı, oklarla geçiş, bilgi ekranı, ses kaydı paneli, yeni bir hayvanın sesi ve ses kaynakları sayfası.

Bu sürümde benim inisiyatifimle yapılan iki şey: sürüm numarası 1.5.0+13 yapıldı; kullanılmayan dört dosya silindi (`lib/pages/home.dart`, kategori modeli, sağlayıcısı ve deposu).

### Eklenemeyenler ve bilinen sınırlar

- **Su aygırı, gergedan, mors:** çizimleri hazır (`scripts/art/unused/`), lisansı güvenilir ses bulunamadı. **Tavşan:** bulunan kayıt büyük olasılıkla kafes gürültüsü, eklenmedi.
- **Panda sesi sizin kararınız.** Wikimedia Commons'ta kamu malı olarak işaretli, ama yükleyen kişi anonim ve kayıt bilgisi yok; su aygırı ve gergedan kayıtlarını aynı nedenle reddettim. Emin olmak isterseniz pandayı çıkarın (49 hayvan kalır) ya da başka bir kayıtla değiştirin.
- **Sesler kulakla dinlenmedi.** Bölümler dosya açıklaması ve seviye ölçümüyle seçildi. Yayından önce 20 yeni sesi telefonda dinleyin; özellikle fare (pes kaydırılmış ultrasonik kayıt), karga (arka plan gürültüsü), keçi ve kaz (sürü), geyik (elk böğürmesi).
- **Çeviriler ana dili konuşan biri tarafından okunmadı.** 20 yeni hayvanın Rusça, Portekizce, Hintçe, Arapça, Almanca ve İspanyolca metinleri gözden geçirilmeli.
- **Karşılaştırma ekranı:** birim ve ondalık virgül ayrıştırması düzeltildi; İngilizce, Türkçe, Almanca, İspanyolca ve Portekizcede 50 hayvanın hepsi testle doğrulandı. Arapçadaki eski 30 hayvanın metinleri Arap rakamı kullandığı için orada çubuklar hâlâ boş; Rusça ve Hintçe testle doğrulanmadı.
- **Quiz** yeni hayvanlar için soru içermiyor; "Sesi Tahmin Et" oyunu 50 hayvanın hepsini kullanıyor.
- Keşfet, Oyunlar ve Profil sekmeleri yeni renkleri aldı ama düzenleri eski.
- Uygulama simgesi hâlâ eski kırmızı panda.

### Mağaza metni

Hayvan sayısı artık 50. Kısa açıklama önerileri:
- EN: "50 animal sounds for toddlers: quiz, guess the sound, coloring. Works offline." (78)
- TR: "50 hayvan sesi: bilgi yarışması, sesi tahmin et, boyama. İnternetsiz çalışır." (77)

Uzun açıklamadaki "30+" ve "all 30 animals" ifadeleri "50" olarak güncellenmeli. `docs/store-assets/` altındaki ekran görüntüleri, banner ve video yeni tasarımla yeniden üretildi.
