# Hayvan görselleri raporu

Tarih: 16 Kasım 2026. Kaynak: `should-cut-animals/` altındaki 20 görsel (1–19 arası 10'ar hayvan, 20. görselde kurbağa ve fare; her biri 1536×1024). Orijinaller yalnızca okundu, değiştirilmedi.

## Sonuç

| | Sayı |
|---|---|
| Kaynak görsel | 20 |
| Çizim | 192 |
| Benzersiz hayvan | 166 |
| Tekrar eden çizim (arşivlendi, silinmedi) | 26 |
| Kalite kontrolünden geçen hayvan | 153 (9'unun adı onayınıza sunuluyor) |
| Karar bekleyen hayvan | 13 (7 kesim kusuru, 5 belirsiz tür adı, 1'inde ikisi birden) |
| Uygulamadaki hayvan | 153 (50 eski + 103 yeni) |
| Yeni çizimle duran hayvan | 153 (tümü) |

- Dama deseni hiçbir görselde gerçek şeffaflık değildi; tümünde kaldırıldı. 17 ve 19 numaralı görsellerdeki manzara zemini (çimen, taş, yaprak, "170 / 200 çizim" yazısı) da temizlendi.
- Her çıktı 512×512, RGBA, gerçek şeffaf, kenarlarda en az 12 piksel boşluk, kayıpsız sıkıştırılmış PNG. Hiçbir çizim yeniden üretilmedi ya da değiştirilmedi.
- Kaynakta hayvanlar 300–530 piksel boyunda. 512 çıktı bu yüzden çoğunda bire bir, küçük çizilenlerde (ör. uğur böceği, palyaço balığı) hafif büyütülmüş durumda; kaynaktan daha keskin olamaz.

## Klasörler (`docs/animal-art/`)

| Yol | İçerik |
|---|---|
| `final/<id>.png` | Kalite kontrolünden geçen 153 hayvan |
| `needs-review/<id>.png` | Karar bekleyen 13 hayvan |
| `archive/` | Tekrar eden 26 çizim |
| `cut/` | 192 kesimin tamamı ve `report.json` (otomatik kontrol sonuçları) |
| `animals.json` | Her hayvanın kaydı: id, Türkçe ad, İngilizce ad, bilimsel ad, kategori, dosya yolu, kaynak görsel ve konum, tanıma güveni, kalite durumu, tekrar çizimleri, ses durumu |
| `needs-review.md` | Karar bekleyenler, adı onay bekleyenler ve tekrar sayılan çizimler |
| `ses-esleme.md` | Hangi hayvanın sesi var, hangisinin yok |
| `katalog-01…20.png` | Görsel başına kontrol kataloğu (açık ve koyu zeminde) |
| `kontrol-katalogu-1…5.png` | Tüm hayvanlar, Türkçe ad ve dosya adıyla |
| `species.json`, `sheets.json` | Elle tutulan tür tablosu ve görsel başına ad/not listesi |

Bilimsel ad yalnızca çizimin türü açıkça belli olan 82 hayvana yazıldı; "yılan", "kelebek", "baykuş" gibi genel çizimlerde boş bırakıldı.

## Uygulamada yapılan değişiklik

- Uygulama 50 hayvandan **153 hayvana** çıktı: 103 yeni hayvan listenin sonuna eklendi. İlk 50 hayvanın kimlikleri, sırası, favoriler ve kullanıcı verileri aynı.
- 153 hayvanın tümü yeni çizimle duruyor. **Kurbağa** ve **fare** 20. görselden kesildi. Bu görselin zemini düz beyaz olduğu için farenin kürk kenarında kalan ince beyaz hat temizlendi; farenin ayrı duran parçaları bıyık telleridir.
- Kararlarınızla yapılanlar: **hindi** 5. görseldeki çizimle değişti; **maymun** 14. görseldeki siyah maymun çizimini aldı ve "uluyan maymun" ayrı hayvan olmaktan çıktı (maymunun sesi ve metinleri aynı); **manda** "Afrika mandası" adıyla, uluyan maymunun listedeki yerine eklendi, böylece hiçbir hayvanın kimliği kaymadı; **leopar** onaylandı.
- Yerleştirilen üç resimde bilinen küçük kusur var ve onayınızla girdi: **kaplan** (sağ yanak tüyleri), **kedi** (bıyık uçları) ve **hindi** (sol kuyruk kenarında civcivden kalan küçük çentik).
- 9 hayvanın adı büyük olasılıkla doğru ama onayınıza sunuluyor (`needs-review.md`): timsah, gergedan böceği, ceylan, bülbül, jaguar, dingo, kum kedisi, ardıç kuşu, çalı çekirgesi.
- Resimler her ekranda oranı korunarak kutuya sığdırılıyor (5 yerde `cover` → `contain`).
- Fotoğraf pilotundan kalan 9 fotoğraf kaynak kaydı kaldırıldı, çünkü o fotoğraflar artık uygulamada değil. Ses kaynak kayıtları duruyor.
- `assets/animal_images` 4,3 MB'tan 33 MB'a çıktı. Kayıplı sıkıştırma yapılmadı.

### Yeni hayvanların metinleri

- Her yeni hayvan için 8 dilde ad, tanıtım, boy, ağırlık, ömür, yaşam alanı, beslenme ve 3 ilginç bilgi yazıldı (103 × 80 = 8.240 metin). Ayrıca her birine "nerede yaşar / ne yer / ne kadar büyük" resimli bilgileri verildi.
- Otomatik denetimden geçti: eksik ya da boş metin yok, birimler uygulamanın okuyabildiği biçimde, boy/ağırlık/ömür sayıları 8 dilde aynı, dil içinde tekrar eden hayvan adı yok.
- Metinleri ben yazdım; Türkçe ve İngilizce örnekleri okudum, ama 8.240 metnin tamamı bir insan tarafından okunmadı. Özellikle Hintçe, Arapça ve Rusça adları ana dili konuşan biri gözden geçirmeli.
- Yazarken emin olunamayan noktalar: böceklerin ve küçük deniz canlılarının ağırlıkları yaklaşık değerler; "köpekbalığı", "kaplumbağa", "ağaçkakan" gibi genel çizimlerde birçok türü kapsayan geniş aralıklar verildi; bazı ömürler (ibibik, yalıçapkını, sülün, opossum, rakun) doğadaki kısa ömre göre yazıldı; kelebekte "uzunluk" kanat açıklığıdır.

### Sesi olmayan hayvanlar

- 103 yeni hayvanın sesi yok. Hiçbir ses dosyası eklenmedi, silinmedi, yeniden adlandırılmadı ya da değiştirilmedi.
- Sesi olmayan hayvanda ses ekranı çalma düğmesi yerine sessiz bir simge ve "Sesi yakında" yazısı gösterir; mikrofon düğmesi gizlenir. Hiçbir durumda başka bir hayvanın sesi çalmaz.
- "Sesi tahmin et" oyunu yalnızca sesi olan hayvanları sorar. Karşılaştırma ve günlük keşif ekranları sesi olmayan hayvanı sessizce atlar.
- "Ses Ustası" rozeti sesi olan hayvan sayısına göre hesaplanır (şu an 50); rozet metinlerindeki sayı artık uygulama tarafından yazılıyor.
- **Ses eklemek için** dosyayı `assets/animal_sounds/<id>.mp3` adıyla koymanız yeterli; kod değişikliği gerekmez, çalma düğmesi kendiliğinden gelir. Beklenen adlar `ses-esleme.md` içinde.

### Doğrulama

- 154 testin tümü geçti (7'si sesi olmayan hayvan için yeni).
- Ana ekran, ses, bilgi ve karşılaştırma ekranları yeni hayvanlarla render edilip gözle kontrol edildi; son değişiklikten sonra maymun, hindi ve Afrika mandası ekranlarına ayrıca bakıldı.
- Android sürüm derlemesi başarılı; APK 74 MB'tan 96,5 MB'a çıktı (tüm işlemci mimarilerini içeren tek dosya; mağazanın kullanıcıya indirdiği paket daha küçüktür). Bağlı telefona kuruldu, açıldı, önceki favori yerinde duruyor. Telefonda yalnızca ana ekrana bakıldı.

## Henüz yapılmayanlar

- Karar bekleyen 13 hayvan (`needs-review.md`) eklenmedi.
- Sürüm numarası değiştirilmedi (1.5.0+13) ve mağaza görselleri eski haliyle duruyor.
- Hiçbir şey commit edilmedi.

## Yeniden üretme

```
build/venv/Scripts/python scripts/assets/run_sheets.py 1 2 … 20   # kes ve katalogla
build/venv/Scripts/python scripts/assets/build_library.py         # klasörler, kayıtlar, listeler
build/venv/Scripts/python scripts/i18n/merge_batches.py --apply   # yeni hayvanları listeye ekle
build/venv/Scripts/python scripts/i18n/add_animals.py <adlar>     # metinleri çeviri dosyalarına yaz
build/venv/Scripts/python scripts/assets/install_art.py           # onaylı resimleri uygulamaya kopyala
```

Tüm değişiklikler commit edilmemiş durumda; son commit'e (`b2feeff`) dönmek her şeyi geri alır.
