# AGENTS.md

**Proje:** CalcMoney — Flutter ile Türkçe gelir/gider takip uygulaması (Android, cihaz içi SQLite).

Her yeni oturumda (özellikle farklı bir bilgisayardan girildiğinde):
1. Önce `meta/README.md` → `meta/proje-bilgisi.md` oku (vizyon, kararlar, veri modeli, mimari).
2. `meta/ilerleme.md`'yi oku (güncel durum, sıradaki adımlar). Bir iş bitince buraya tarihli madde ekle.
3. Flutter kurulu değilse derleme YAPMA; `meta/kurulum-rehberi.md`'deki adımları izle.
4. UI ve dokümantasyon dili Türkçe.
5. Para değerleri her zaman tamsayı kuruş (`int amount_kurus`) olmalı; `double` ile para tutma.
6. Kod `lib/` altında modüler: `models/ data/ services/ state/ screens/ widgets/ utils/`.
7. Doğrulama komutları: `flutter analyze`, `flutter test`. Uygulama Android cihazda `flutter run`.

Kod yazarken "Kod stili" kurallarına uy (gereksiz yorum ekleme, mevcut desenleri izle).
