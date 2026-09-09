# Proje Bilgisi — CalcMoney

## Vizyon / Kullanıcı hikayesi
Kullanıcı her ay düzenli giderlerini (kira, su, doğalgaz, elektrik, internet,
market alışverişi, AI/dizi-film abonelikleri vb.) ve gelirlerini tek bir yere
kaydeder. Uygulama:
- **Aylık gelir – gider dengesini** gösterir.
- Tüm yılın kayıtlarını tutar; yıllık **toplam giren / çıkan** parayı ve aylık
  dökümü sunar.
- Tekrarlayan sabit giderler için her ay **hatırlatma bildirimi** gönderir.

## Kararlar (değişmeden önce buraya bak)
- **Platform:** Flutter (tek kod, Android hedefli; iOS ileride). Dart >= 3.3.
- **Veri deposu:** Cihaz içi **SQLite** (`sqflite`). Bulut/hesap sistemi YOK (şimdilik).
- **Veri sahipliği:** Tüm veri telefonda; yedek için DB dosyası paylaşımı ileride eklenebilir.
- **Para gösterimi:** Türk Lirası, `₺` simgesi. Para **tamsayı kuruş** olarak saklanır
  (`amount_kurus`), kayan nokta (double) hatasından kaçınılır.
- **Arayüz dili:** Türkçe.
- **Durum yönetimi:** `provider` + tek `AppState` (ChangeNotifier). Stream değil,
  repo yazma sonrası yeniden yükleme yaklaşımı.
- **Bildirimler:** `flutter_local_notifications` + `timezone`. Her aktif abonelik için
  ayın belirli gününde tekrarlanan tek bir zamanlanmış bildirim kullanılır
  (`matchDateTimeComponents: dayOfMonthAndTime`). Her açılışta/degisiklikte
  bildirimler yeniden programlanır (kendi kendini iyileştirir).
- **Kategori modeli:** Ön tanımlı kategori seti DB'ye tohumlanır. Kullanıcı kategori eklemesi
  henüz yok (sonraki adım).
- **Tekrarlayan gider günü:** 1–28 arası. (29–31 günlük aylar karmaşıklığından kaçınıldı.)
  Tekrarlayan kayıt, aylık gider kaydına **otomatik işlenmez**; hatırlatıcı + hızlı
  "kayıt ekle" ön doldurma sağlar. Kullanıcı gerçekleşen kaydı onaylayıp ekler.

## Veri modeli
- `categories(id, name, type[0=gelir,1=gider], icon, color)`
- `transactions(id, type[0/1], amount_kurus[pozitif], category_id, date[yyyy-MM-dd], note, created_at)`
- `recurring_expenses(id, name, amount_kurus, day_of_month[1-28], category_id, notify[0/1], active[0/1], created_at)`

Sorgular, ISO `yyyy-MM-dd`/`yyyy-MM` ön ekiyle (`LIKE '2026-09%'`) aylık/yıllık gruplama yapar.

## Mimari (lib/)
```
lib/
  main.dart                  bootstrap: DB aç, AppState başlat, runApp
  app.dart                   MaterialApp (tr lokalizasyon, tema)
  theme.dart
  models/                    Category, RecordType, TransactionRecord, RecurringExpense, Aggregate
  data/                      app_database.dart (şema + tohum kategoriler)
                             *_repository.dart (kategori, işlem, tekrarlayan)
  services/notification_service.dart
  state/app_state.dart       tek ChangeNotifier: veri + görünüm (ay/yıl) durumu
  screens/                   home_shell (alt sekmeler), overview, records,
                             annual, recurring + add/edit bottom sheet'leri
  widgets/                   kategori ikon/renk, para yazıcı, boş durum vb.
  utils/                     money.dart (kuruş ↔ ₺), dates.dart (Türkçe ay adları)
```

## Kapsam
MVP (ilk sürüm — mevcut):
- Kayıt ekleme/düzenleme/silme (gelir-gider, kategori, tutar, tarih, not)
- Aylık liste + aylık gelir/gider/denge
- Yıllık döküm (12 ay + yıl toplamı)
- Tekrarlayan sabit gider yönetimi + aylık bildirim

Sonraki adımlar:
Tamamlanan (v0.3.0):
- [x] Kategoriye dokununca o kategorinin **aylık değişim/toplam görünümü** (örn. Su: Eylül 400, Ekim 320, Kasım 500...) — değişken giderleri (su/elektrik/doğalgaz/market) takip için — kullanıcı isteği (3. oturum)
- [x] Özet/Genel Bakış, sabit giderlerin yanında **"aylık sabit gelirler"**i de göstersin — kullanıcı isteği (3. oturum)
- [x] "Sabitler" bölümü **gelir + gider** tekrarlayan kayıtları desteklesin. Veritabanına tip sütunu eklendi (v2 göç, mevcut veriler korunur) — kullanıcı isteği (3. oturum)
- [x] Sabit Kayıtlar sayfasında kayıtlar **kategoriye göre gruplansın** — kullanıcı isteği (3. oturum)
- [x] "Aylara ekle" penceresinde, o ay zaten aynı sabit kayıtla kayıtlıysa ay **"kayıtlı"** görünüp kilitlensin — kullanıcı isteği (3. oturum)

Tamamlanan (v0.4.0):
- [x] Sabit Kayıtlar grupları **açılır/kapanır** (ExpansionTile) — kullanıcı isteği
- [x] **Silmeyi geri al (undo)** — kayıt ve sabit kayıt için "Geri al" çubuğu
- [x] **Karanlık tema** (DB `settings`, Genel Bakış ikonu)
- [x] **Kayıt kopyalama (klonla)** — kayıt menüsünde "Kopyala"

Bekleyen — yol haritası (öncelik önerisi sırasıyla):
- [ ] v0.5.x — **Kategori bütçe/limitleri**: kategoriye aylık limit, ilerleme çubuğu, aşınca uyarı
- [ ] v0.5.x — **Ortalama & karşılaştırma**: kategori analizinde ay ortalaması, önceki aya/geçen yıla göre % değişim
- [ ] v0.5.x — **Arama + filtre**: kayıtlarda kategori/not/tutar aralığı arama & filtre
- [ ] v0.6.x — **Yedekleme / dışa aktarma**: tüm veriyi dosya olarak dışa aktar (CSV/JSON) + geri yükle — veri kaybına karşı en kritik
- [ ] Bekleyen eski: Kullanıcı tanımlı kategori, kategorili grafikler (pasta/çubuk), "beklenen giderler" önerisi, ana ekran widget'ı, iOS derleme
