# Proje Bilgisi — CalcMoney

## Vizyon / Kullanıcı hikayesi
Kullanıcı her ay düzenli giderlerini (kira, su, doğalgaz, elektrik, internet,
market alışverişi, AI/dizi-film abonelikleri vb.) ve gelirlerini tek bir yere
kaydeder. Uygulama:
- **Aylık gelir – gider dengesini** gösterir.
- Tüm yılın kayıtlarını tutar; yıllık **toplam giren / çıkan** parayı ve aylık
  dökümü sunar.
- Sabit (tekrarlayan) gider/gelirleri ve sonlu taksitleri tek yerden yönetir.

## Kararlar (değişmeden önce buraya bak)
- **Platform:** Flutter (tek kod, Android hedefli; iOS ileride). Dart >= 3.3.
- **Veri deposu:** Cihaz içi **SQLite** (`sqflite`). Bulut/hesap sistemi YOK (şimdilik).
- **Veri sahipliği:** Tüm veri telefonda; yedek için DB dosyası paylaşımı ileride eklenebilir.
- **Para gösterimi:** Türk Lirası, `₺` simgesi. Para **tamsayı kuruş** olarak saklanır
  (`amount_kurus`), kayan nokta (double) hatasından kaçınılır.
- **Arayüz dili:** Türkçe.
- **Durum yönetimi:** `provider` + tek `AppState` (ChangeNotifier). Stream değil,
  repo yazma sonrası yeniden yükleme yaklaşımı.
- **Bildirim:** YOK (v0.8.0'dan itibaren tamamen kaldırıldı — hatırlatıcı/alarm
  istenmedi; uygulama yalnızca kayıt ve denge tutar).
- **Kategori modeli:** Ön tanımlı kategori seti DB'ye tohumlanır. Kullanıcı kategori eklemesi
  henüz yok (sonraki adım).
- **Tekrarlayan kayıt günü:** 1–28 arası. (29–31 günlük aylar karmaşıklığından kaçınıldı.)
  Tekrarlayan kayıt, aylık gider kaydına **otomatik işlenmez**; kullanıcı "Aylara ekle" ile
  istediği ayları seçer, kayıt o ayın `day_of_month` gününe yazılır.
- **Sonlu sabit kayıt (taksit):** Sabit kayda opsiyonel `toplam_ay` girilir (0 = sürekli).
  O sabit kayda bağlı oluşturulan aylık kayıt sayısı `toplam_ay`'a ulaşınca sabit kayıt
  otomatik silinir (aylık kayıtlar durur).
- **"Aylara ekle" (v0.8.1):** Pencerede kayıtlı ayların tiki kaldırılabilir; bu, o aya ait
  kaydı geri alır (yalnızca o sabit kayıttan üretilmiş kayıtlar silinir). Boş aylar seçilerek
  eklenmeye devam edilir.
- **Hesap dönemi (kesim günü):** Varsayılan dönem takvim ayıdır. Ayarlar'dan tek genel
  "hesap kesim günü" (1–28) seçilebilir: kesim gününe kadar (dahil) eklenen kayıt o ayın,
  kesimden SONRASI bir sonraki ayın dönemine işlenir. Her kayıt, ait olduğu dönemin
  `yyyy-MM` etiketini `transactions.donem` sütununda saklar; aylık/yıllık gruplama takvim
  tarihi yerine bu etiket üzerinden yapılır. Kesim günü değişince tüm kayıtların etiketi
  yeniden hesaplanır.
- **Ön tanımlı kategoriler:** Tohum seti zamanla genişleyebilir (yeni kategoriler DB göçüyle
  eklenir, mevcut kullanıcı verisi korunur). Kullanıcı tanımlı kategori hâlâ yol haritasında.
- **Yedekleme:** Veri yedeği, tüm veritabanının tek `.db` dosyası olarak dışa/içe aktarılmasıdır
  (Ayarlar → Veri yedeği; share_plus ile paylaş, file_picker ile geri yükle). Yedek içe aktarılırken
  SQLite başlık imzası doğrulanır; mevcut verinin üzerine yazar. Şimdilik CSV/JSON yok.

## Veri modeli
- `categories(id, name, type[0=gelir,1=gider], icon, color, parent_id)`
- `transactions(id, type[0/1], amount_kurus[pozitif], category_id, date[yyyy-MM-dd],
  donem[yyyy-MM hesap dönemi etiketi], note, created_at, recurring_id)`
- `recurring_expenses(id, name, amount_kurus, day_of_month[1-28], category_id, type,
  notify[0/1 kullanılmıyor], toplam_ay[0=sürekli, N=sonlu], active[0/1], created_at)`

Aylık/yıllık sorgular `transactions.donem` etiketiyle (`LIKE '2026-09%'`, yıl `substr(donem,1,4)`) gruplar.
`date` gerçek tarihi, `donem` ise kesim gününe göre hesaplanan dönem etiketini tutar.

## Mimari (lib/)
```
lib/
  main.dart                  bootstrap: DB aç, AppState başlat, runApp
  app.dart                   MaterialApp (tr lokalizasyon, tema)
  theme.dart
  models/                    Category, RecordType, TransactionRecord, RecurringExpense, Aggregate
  data/                      app_database.dart (şema + tohum kategoriler)
                             *_repository.dart (kategori, işlem, tekrarlayan)
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
- Tekrarlayan sabit gider/gelir ve sonlu taksit yönetimi ("Aylara ekle")

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

Tamamlanan (v0.5.0):
- [x] **Arama + filtre**: kayıtlarda kategori/not'a göre arama & filtre (v0.5.0)
- [x] **Ortalama & karşılaştırma**: kategori analizinde aylık ortalama, geçen yıla/son iki aya göre % değişim (v0.5.0)

Tamamlanan (v0.6.0):
- [x] **Alt kategoriler**: "Faturalar" üst kategorisi altında Su/Elektrik/Doğalgaz/İnternet/Telefon
      (DB v5 parent_id, iki aşamalı seçici, sabitler üst kategoriye göre gruplanır)

Tamamlanan (v0.7.0):
- [x] **Sabit Kayıtlar sayfasında "Giderler"/"Gelirler" üst bölümleri** — her bölüm altında
      o türde kaydı olan kategori grupları; boş bölüm "kayıt yok" uyarısı gösterir (kullanıcı isteği)
- [x] **Yeni gider kategorileri:** Alışveriş, Taksit (taksitlendirme — kredi kartı taksitleri;
      aynı "Aylara ekle" ile istenen aylara işlenir) (DB v6 göçü, mevcut kurulumlar korunur)
- [x] **Hesap kesim günü ayarı (tek genel):** Ayarlar (Genel Bakış dişli ikonu). Kesim gününe
      kadar olan kayıtlar o ayın, sonrası sonraki ayın dönemine işlenir.
      `transactions.donem` etiketi (DB v6) + sorgular dönem etiketine göre; kesim değişince
      tüm kayıtlar yeniden hesaplanır.
- [x] **Veri yedeği (dışa/içe aktarma .db):** Ayarlar → "Veri yedeği" ile tek `.db` dosyası
      paylaşılabilir (Drive/e-posta) ve aynı dosyadan geri yüklenebilir (SQLite doğrulamalı).
      Yeni paketler: `share_plus`, `file_picker`.

Tamamlanan (v0.8.0):
- [x] **Sonlu sabit kayıt (taksit bitişi):** Sabit kayıt formunda "Toplam ay" (0=sürekli).
      Bağlı aylık kayıt sayısı o değere ulaşınca sabit kayıt otomatik silinir (DB v7).
- [x] **Hatırlatma/bildirim kaldırıldı:** `flutter_local_notifications` + `timezone` paketleri,
      `notification_service.dart`, Android izinleri/alıcıları ve "hatırlatma" gösterimleri
      tamamen çıktı; uygulama yalnızca gelir/gider dengesi tutar.

Bekleyen — yol haritası (öncelik önerisi sırasıyla):
- [ ] v0.6.x — **Kategori bütçe/limitleri**: kategoriye aylık limit, ilerleme çubuğu, aşınca uyarı
- [ ] Bekleyen eski: Kullanıcı tanımlı kategori, kategorili grafikler (pasta/çubuk), "beklenen giderler" önerisi, ana ekran widget'ı, iOS derleme
