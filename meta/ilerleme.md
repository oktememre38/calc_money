# İlerleme Günlüğü — CalcMoney

Bu dosya tarihli, kısa maddelerle projenin durumunu tutar. En yeni madde en üsttedir.
Her tamamlanan iş için yeni bir bölüm ekle.

## 2026-09-09 (5. oturum) — v0.3.1: açılış ekranı + kayıt satırları zenginleşti
- **Açılış (splash) ekranı:** Uygulama açılınca CalcMoney logosu (kumbara ikonu + "CalcMoney"
  + "Gelir · Gider · Takip") ~1,7 sn görünüp yumuşak geçişle Genel Bakış'a gidiyor.
  `screens/splash_page.dart` (yeni), `app.dart`'ta ilk ekran splash oldu. Paket eklenmedi.
- **Kayıtlar satırları:** Gün başlıkları yerine her satırda artık **kategori adı** (başlık) +
  alt satırda **tarih • not** + sağda **tutar** görünüyor. (`screens/records_page.dart`)
- Sürüm: `0.3.1+4`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,0 MB).

## 2026-09-09 (4. oturum) — v0.3.0: sabit gelir + gruplama + kategori analizi
Kullanıcı istekleriyle birlikte uygulanan 5 madde:
1. **Sabit kayıtlar gelir/gider olabiliyor:** DB v2 göçü (`recurring_expenses` → `type` sütunu,
   mevcut kayıtlar gider sayılır, veri KAYBOLMAZ). Editor'de Gelir/Gider seçimi + gelir kategorileri.
2. **Sabitler sayfası kategoriye göre gruplandı** (gider kategorileri önce); sayfada aylık sabit
   gelir/gider özet kartı eklendi.
3. **Genel Bakış'ta "aylık sabit gelir + sabit gider"** kartı.
4. **"Aylara ekle" penceresi:** daha önce eklenen aylar "kayıtlı" görünüp kilitli; yalnızca boş aylar seçilebiliyor.
5. **Kategori Analizi:** Genel Bakış ve Kayıtlar'ın üstündeki analiz ikonuyla açılıyor; kategoriye
   dokununca o yılın ay ay değişimi (çubuk + tutar). Yıllık kategori toplamları.
- Ayrıca: toplu ekleme tipi (gelir kaydı gider yerine yanlış eklenmez), bildirim metni gelir/gider'e göre.
- Dosyalar: `app_database.dart` (v2 göç), `models/recurring_expense.dart`, `state/app_state.dart`,
  `data/transaction_repository.dart` (kategori sorguları), `widgets/recurring_editor.dart`,
  `widgets/recurring_months_sheet.dart`, `screens/recurring_page.dart`, `screens/overview_page.dart`,
  `screens/records_page.dart`, yeni `screens/category_analysis.dart`.
- Sürüm: `0.3.0+3`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,0 MB).
- Not: Telefona kurarken KALDIRMA; üzerine güncelle. İlk açılışta DB göçü otomatik çalışır.

## 2026-09-09 (3. oturum) — Sabit giderleri "aylara tik atıp" toplu ekleme (v0.2.0)
- **İstek:** Sabit giderler her ay "⋮ menü → bu ay için kayıt ekle" ile elle eklenmesin;
  kullanıcı istediği aylara tik atsın, onlar otomatik kayda geçsin.
- **Tasarım kararı (kullanıcı onayladı):** Tam otomatik yerine **kontrolü kullanıcıda** olan
  "ay seç" yöntemi → çift kayıt riski yok.
- **Yapılan:** Sabit gider satırına dokununca yeni **"Aylara ekle"** penceresi açılıyor
  (bu aydan itibaren +12 ay, tik listesi). İşaretlenen her ay için sabit giderin gününde,
  tutarı/kategorisi/ismiyle bir **gider kaydı** oluşuyor. Çift kayıt koruması: aynı ayda
  birebir aynı kayıt (kategori+tutar+not) varsa o ay atlanıyor; sonuç snackbar ile özetleniyor
  ("3 aya eklendi, 1 ay zaten kayıtlıydı").
- **Dosyalar:** `widgets/recurring_months_sheet.dart` (yeni pencere),
  `state/app_state.dart` (`tekrarlayanTopluEkle`), `screens/recurring_page.dart` (satır onTap bağlama).
- **Sürüm:** `0.2.0+2`. Doğrulama: `flutter analyze` temiz, `flutter test` 12/12,
  `flutter build apk` başarılı (52,8 MB).
- **Sonraki:** Güncellemeyi telefona kur (KALDIRMADAN, üzerine) ve dene.

## 2026-09-09 (2. oturum) — Flutter + Android kurulumu tamamlandı; ilk derleme başarılı
**Bu makinenin ortamı (devam için önemli):**
- Flutter **3.47.2** stable → `E:\flutter` (Dart 3.13.2). `E:\flutter\bin` kullanıcı PATH'inde.
- Android SDK → `E:\Android\Sdk` (`ANDROID_HOME` = `ANDROID_SDK_ROOT` = bu adres, kullanıcı ortam değişkeni).
  Kurulu: `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`. Derleme sırasında otomatik olarak
  NDK 28.2 ve `platform-34` de eklendi. Komut satırı araçları `E:\Android\Sdk\cmdline-tools\latest`.
- Lisanslar kabul edildi; `flutter doctor` Android toolchain: ✓.
- Not: Windows masaüstü (Visual Studio C++) uyarısı hedefimiz olmadığı için yok sayılır.

**Yapılanlar:**
- `flutter create --org com.calcmoney --platforms=android,ios --project-name calc_money .` ile
  `android/` ve `ios/` üretildi (lib kodları korundu). Şablon `test/widget_test.dart` silindi.
- `flutter analyze` başlangıçta 20 sorun buldu → hepsi düzeltildi (Türkçe karakterli değişken adları,
  `MediaQuery.viewInsetsOf` kullanımı, `zonedSchedule`'ın `UILocalNotificationDateInterpretation` enum'ı, `const` uyarıları vb.).
- Android bildirim ayarları eklendi: `android/app/build.gradle.kts` → desugaring 2.1.5 açıldı;
  `AndroidManifest.xml` → bildirim izinleri (POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE,
  SCHEDULE_EXACT_ALARM) + zamanlanmış bildirim alıcıları eklendi; uygulama etiketi "CalcMoney".
- **Sonuç:** `flutter analyze` temiz, `flutter test` 12/12 geçti,
  `flutter build apk --debug` başarılı → `build\app\outputs\flutter-apk\app-debug.apk`.

**Sıradaki adım (cihaz):** Gerçek telefon USB ile bağlanıp geliştirici modu açılınca
`flutter run` (veya APK'yı telefona kur). Uygulamayı elle test et: ekleme, ay/yıl özeti, sabit gider + bildirim.

## 2026-09-09 — Proje kurulumu ve ilk kod (MVP kod tabanı)
- Karar alındı: Flutter + cihaz içi SQLite + kapsam "Temel + hatırlatıcılar".
  Detaylar: `meta/proje-bilgisi.md`.
- Git deposu başlatıldı (`main` dalı). `.gitignore`, `README.md` eklendi.
- `meta/` klasörü oluşturuldu: proje bilgisi, ilerleme günlüğü, kurulum rehberi.
  Amaç: başka bir makinede birebir devam edebilmek.
- `pubspec.yaml` + `analysis_options.yaml` eklendi (paketler: sqflite, provider,
  intl, timezone, flutter_local_notifications, flutter_localizations).
- Yazılan Flutter kod tabanı (henüz çalıştırılamadı — bu makinede Flutter yok):
  - Modeller: Category, TransactionRecord, RecurringExpense, Aggregate
  - SQLite şeması + varsayılan kategori tohumları (gelir/gider)
  - Repository'ler: kategori, işlem (ay/yıl toplam sorguları), tekrarlayan
  - Bildirim servisi (aylık tekrar, tz, izin isteme)
  - AppState (ChangeNotifier) — tek veri kaynağı
  - Arayüz: alt sekmeli kabuk, Genel Bakış, Kayıtlar, Yıllık, Abonelikler sayfaları
    + gelir/gider kaydı ve abonelik ekleme/düzenleme sheet'leri
  - Para (kuruş↔₺) ve tarih yardımcıları, temel widget'lar

**Güncel durum:** Kod yazıldı, ancak `flutter analyze`/derleme YAPILMADI (Flutter SDK
yok). Flutter kurulduğu makinede `meta/kurulum-rehberi.md`'deki adımlar izlenerek
çalıştırılmalı, hatalar giderilmeli, telefon/emülatörde manuel test yapılmalıdır.

**Sıradaki adımlar:**
1. Flutter'ı kur (kurulum rehberi) → `flutter create` + `pub get` + `flutter analyze`.
2. Lint/derleme hatalarını düzelt; uygulamayı cihazda çalıştır.
3. Manuel test senaryoları (ekleme, ay/yıl özeti, abonelik + bildirim).
4. Kullanıcı tanımlı kategori ekleme (proje bilgisi → sonraki adımlar).
