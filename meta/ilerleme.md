# İlerleme Günlüğü — CalcMoney

Bu dosya tarihli, kısa maddelerle projenin durumunu tutar. En yeni madde en üsttedir.
Her tamamlanan iş için yeni bir bölüm ekle.

## 2026-09-09 (14. oturum) — v0.8.1: "Aylara ekle"de kayıtlı ayların tikini kaldırma
- Kullanıcı: seçilen ayların tikini geri kaldıramıyordu (kayıtlı aylar kilitliydi).
- Çözüm: `widgets/recurring_months_sheet.dart` yeniden yazıldı — artık her ayın tikini
  kaldırmak serbest. Kayıtlı bir ayın tiki kaldırılırsa o aya ait kayıt **silinir**
  ("Uygula" ile); boş aylar seçilerek eklenebilir. "Boş ayları seç" / "Kayıtlıları kaldır" /
  "Temizle" kısayolları eklendi; sonuç snackbar ile özetlenir.
- `state/app_state.dart`: `tekrarlayanAyKayitlariniKaldir` — yalnızca bu sabit kayıttan
  üretilmiş (bağlı `recurring_id` veya birebir eski şablon) kayıtları siler.
- Sürüm: `0.8.1+12`. analyze temiz, test 16/16, `flutter build apk --release` başarılı (52,4 MB).

## 2026-09-09 (13. oturum) — v0.8.0: taksit bitişi + bildirimler kaldırıldı
- **Sonlu sabit kayıt (taksit):** Sabit kayıt formuna "Toplam ay" alanı eklendi (boş = sürekli;
  taksit için 5 gibi). Bir sabit kayda bağlı (`recurring_id`) oluşturulan aylık kayıt sayısı
  `toplam_ay` değerine ulaşınca sabit kayıt **otomatik silinir** (geçmiş aylık kayıtlar kalır).
  DB **v7** (`recurring_expenses.toplam_ay`). `models/recurring_expense.dart` (toplamAy, notify
  çıktı), `state/app_state.dart` (`_sonlandirilmasiGerekenleriSil` — sabit liste her yenilenişinde
  ve kayıt ekleme sonrasında çalışır), `data/transaction_repository.dart` (`countByRecurring`),
  `widgets/recurring_editor.dart` (alan + açıklama), `recurring_page.dart` (satırda "N ay" bilgisi).
- **Hatırlatma/bildirim tamamen kaldırıldı** (kullanıcı isteği): `flutter_local_notifications` +
  `timezone` paketleri ve `lib/services/notification_service.dart` silindi; `AppState` bildirim
  çağrıları çıktı; `AndroidManifest.xml`'den izinler (POST_NOTIFICATIONS vb.) ve bildirim
  alıcıları kaldırıldı; editörde "hatırlatma" anahtarı ve satırlardaki zil/"hatırlatma açık"
  gösterimi silindi. Gün seçici "Kayıt günü" olarak kaldı (aylara eklenirken kaydın gününü belirler).
- `pubspec.yaml`: `0.8.0+11` (+ `share_plus`/`file_picker` kalır; eski bildirim paketleri çıktı).
- `flutter analyze` temiz, `flutter test` 16/16, `flutter build apk --release` başarılı (52,3 MB,
  aynı kalıcı keystore imzası — v0.7.0 üzerine güncelleme sorunsuz kurulur).
- Not: Dokümanlar güncellendi (`proje-bilgisi.md` vizyon/kararlar/veri modeli/mimari,
  `kurulum-rehberi.md` bölüm 3 artık release keystore kurulumunu anlatıyor).

## 2026-09-09 (12. oturum) — v0.7.0: Gelir/Gider bölümleri + yeni kategoriler + hesap kesim günü
Bu sürüm, kullanıcının istediği üç işi birden içerir (tek sürüm kararı):
- **Sabit Kayıtlar sayfası hiyerarşisi:** Düz kategori listesi yerine artık her zaman
  görünen **"Giderler" ve "Gelirler" üst bölümleri** var; her bölümde o türde kaydı olan
  kategori grupları (açılır/kapanır) yer alıyor. Boş bölümler "kayıt yok" uyarısı gösteriyor.
  `screens/recurring_page.dart` (yeniden yapılandırıldı: `_TipBolumu`, `_KategoriGrubu`).
- **Yeni gider kategorileri:** "Alışveriş" (shopping_bag) ve **"Taksit"** (credit_card) eklendi.
  Taksitli alışverişler Sabit Kayıtlar → Taksit altında kaydedilip mevcut "Aylara ekle" ile
  istenen aylara işleniyor. DB **v6** göçü: mevcut kurulumlarda eksik tohum kategorileri eklenir.
- **Hesap kesim günü:** Ayarlar (Genel Bakış'taki dişli ikonu → `screens/ayarlar_page.dart`, yeni)
  tek genel kesim günü (1–28 / Kapalı) seçtiriyor. Kural: kesim gününe kadar (dahil) kayıt o ayın,
  kesimden sonrası **sonraki ayın** dönemine işlenir. Uygulama: `transactions.donem` (yyyy-MM)
  etiketi saklanır (DB v6), tüm aylık/yıllık sorgular takvim `date` yerine `donem` etiketine göre
  gruplar; kesim günü değişince `TransactionRepository.donemleriYenidenHesapla` ile tüm kayıtlar
  yeniden etiketlenir. Görünüm "bugünün dönemi"ne göre açılır (AppState.suDonemAy), yıl/analiz
  sayfalarındaki "bu ay" vurgusu da dönem etiketini kullanır.
- **Ek düzeltme:** `screens/dagilim.dart` içinde bozuk karakterle (mojibake) kayıtlı 3 metin
  (başlık/yorum/boş durum) düzeltildi.
- **Veri yedeği (.db):** Ayarlar → "Veri yedeği" — tüm veritabanı tek `.db` dosyası olarak
  paylaşılıp (share_plus) geri yüklenebilir (file_picker + SQLite başlık doğrulaması).
  Yeni paketler: `share_plus`, `file_picker`. `app_database.dart` (kopyala/geri yükle),
  `app_state.dart` (`yedekOlustur`, `yedekGeriYukle`), `ayarlar_page.dart`.
- **Kalıcı release imzası:** Artık APK'lar bilgisayara özel debug anahtarıyla değil, kalıcı bir
  keystore ile imzalanıyor (`android/key.properties` — git'e girmez; dosya
  `C:\Users\User\keystores\calcmoney-release.jks`, PAROLAYI YEDEKLE). `build.gradle.kts` anahtarı
  okuyamazsa debug imzaya düşer. Çift PC kullanımı için aynı keystore dosyasının iki makinede de
  aynı yolu göstermesi gerekir. Bu sürümden itibaren telefonda ilk kurulum eski (debug) imzalı
  sürümle çakışır → eski uygulama SİLİNİP kurulur (eski veriye erişim yoksa kaybolur; sonrasında
  yedek alma/geri yükleme ile korunur).
- Dosyalar: `app_database.dart` (v6), `models/transaction_record.dart` (donem),
  `data/transaction_repository.dart`, `state/app_state.dart` (kesim ayarı + dönem + yedek),
  `utils/dates.dart` (`donemEtiketi`), `widgets/category_visual.dart`, `screens/recurring_page.dart`,
  `screens/ayarlar_page.dart` (yeni: kesim + yedek), `screens/overview_page.dart` (dişli),
  `annual_page.dart`, `category_analysis.dart`, `dagilim.dart`, `android/app/build.gradle.kts`
  (release imza), `pubspec.yaml`/`pubspec.lock` → `0.7.0+10` (+share_plus, +file_picker).
- Sürüm: `0.7.0+10`. `flutter analyze` temiz, `flutter test` 16/16, `flutter build apk --release`
  başarılı (54,4 MB).
- Not: Telefonda KALDIRIP yeni APK'yı KUR (ilk seferlik imza geçişi; veriler eski anahtara
  erişim yoksa kaybolur). Kurduktan sonra Ayarlar → "Yedek al" ile ilk yedeğini hemen al.
  GitHub'daki v0.7.0 etiketi/eski APK hatalı imzalıydı; doğru commit'e taşınıp yeni APK yüklenecek.

## 2026-09-09 (11. oturum) — Yeni makinede geliştirme ortamı kuruldu
Reponun yeni klonlandığı bu makinede sıfırdan kurulum yapıldı (önceden Flutter/Java/Android SDK yoktu):
- Flutter **3.47.3** stable → `C:\flutter` (Dart 3.13.3). `C:\flutter\bin` kullanıcı PATH'ine eklendi.
- JDK **Temurin 17.0.20.1** → `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot` (`JAVA_HOME`).
- Android Studio 2026.1.4.7 kuruldu (`C:\Program Files\Android\Android Studio`) — derleme gerekmiyor, IDE için.
- Android SDK → `C:\Android\Sdk` (`ANDROID_HOME` = `ANDROID_SDK_ROOT`): cmdline-tools 19.0,
  platform-tools, `platforms;android-36`, `build-tools;36.0.0`. Lisanslar kabul edildi.
- Doğrulama: `flutter doctor` Android toolchain ✓, `flutter analyze` temiz, `flutter test` 12/12.
- Not: `flutter` PATH'i için **yeni bir terminal** açmak gerekir.

## 2026-09-09 (10. oturum) — v0.6.1: dağılım detayı + hızlı ay atlama
- **Donut detayı:** Genel Bakış'ta dağılım kartına dokununca **detay ekranı** açılıyor
  (Gider/Gelir geçişli; her kategori için çubuk + tutar + %; toplam). Dosya
  `screens/dagilim.dart` (yeni; `DagilimKarti` + `DagilimDetayPage`).
- **Ay atlama:** "Eylül 2026" başlığına dokununca takvim açılır, seçilen günün ayına atlanır
  (Genel Bakış ve Kayıtlar). `widgets/common.dart` (`aySeciciGoster`, `MonthSelector.onTitleTap`).
- Not: Ay dağılım verisini toplayan sorgu `ayKategoriDagilimi` `data/transaction_repository.dart`'ta.
- Sürüm: `0.6.1+9`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,5 MB).

## 2026-09-09 (9. oturum) — v0.6.0: alt kategoriler ("Faturalar" üst kategorisi)
- **İstek:** Fatura türleri (Su/Elektrik/Doğalgaz/İnternet/Telefon) "Faturalar" altında toplansın.
- **Karar:** Gerçek alt kategori (hierarşi) — kullanıcı seçimi.
- **Veri:** DB v5 → `categories.parent_id` eklendi. "Faturalar" üst kategorisi + alt kategoriler
  kuruldu; mevcut Su/Elektrik/Doğalgaz/İnternet kategorileri aynı kimlikle Faturalar'a taşındı
  (kayıtlar korunur). Telefon alt kategorisi yoksa eklendi. `app_database.dart` (göç + tohum),
  `models/category.dart` (parentId).
- **Seçici:** Yeni `widgets/category_picker.dart` — iki aşamalı: önce üst kategori/üst gruplar,
  üst gruba dokununca alt kategoriler açılır ("← Faturalar" ile geri). Kayıt & sabit editörlerinde
  kullanıldı; varsayılan seçim yaprak kategori olur.
- **Sabit Kayıtlar:** Gruplama üst kategoriye göre (örn. Faturalar başlığı altında faturalar);
  her satırın alt yazısında yaprak kategori adı görünür. `screens/recurring_page.dart`.
- **Ay dağılım diyagramı (Genel Bakış):** "Son kayıtlar" kartı kaldırıldı; yerine seçili ayın
  **donut (yuvarlak) dağılım** kartı geldi — Gider/Gelir geçişli, alt kategoriler üst kategoride
  toplanır, yanında % + tutar listesi. `widgets/distribution_chart.dart` (yeni),
  `data/transaction_repository.dart` (`ayKategoriDagilimi`), `screens/overview_page.dart`.
- Sürüm: `0.6.0+8`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,3 MB).

## 2026-09-09 (8. oturum) — v0.5.0: arama+filtre, ortalama & karşılaştırma
- **Arama + filtre (Kayıtlar):** Sayfanın üstünde arama kutusu (not/kategori adına göre)
  + ay içinde kullanılan kategorilerin tek seçimli filtre çipleri ("Tümü" + kategoriler).
  Filtre açıkken "X / N kayıt gösteriliyor" + "Filtreyi temizle". Sayfa Stateful oldu,
  `screens/records_page.dart` baştan yazıldı.
- **Ortalama & karşılaştırma (Kategori Analizi):** Kategori ay-detayında üst kart artık
  şunları gösteriyor: **Aylık ortalama** (kayıtlı ay başına), **Geçen yıl toplamı + % değişim**,
  **Son iki kayıtlı ay arası % değişim**. `screens/category_analysis.dart` (geçen yıl sorgusu).
- Sürüm: `0.5.0+7`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,3 MB).

## 2026-09-09 (7. oturum) — v0.4.0: karanlık tema, geri al, açılır/kapanır gruplar, kopyalama
Bu sürüm aynı zamanda v0.3.2'nin iki düzeltmesini de içerir (sabit→aylık güncelleme, analizde yıl okları).
- **Karanlık tema:** Açık/gece tema. Tercih DB'deki yeni `settings` tablosunda saklanır (DB v4).
  Genel Bakış üstündeki 🌙/☀ ikonuyla değişir. `theme.dart` (dark), `app.dart`/`main.dart`
  (provider sarmalama + themeMode), `state/app_state.dart` (tema ayarı).
- **Silmeyi geri al (undo):** Kayıt ve sabit kayıt silmelerinde "Geri al" çubuğu.
  `app_state.dart` (son silinen tamponu + `sonSilineniGeriAl`), `records_page.dart`,
  `recurring_page.dart` (snackbar).
- **Sabit grupları açılır/kapanır:** Kategori başlığına dokununca içindekiler açılır/kapanır
  (ExpansionTile). `screens/recurring_page.dart`.
- **Kayıt kopyalama (klonla):** Kayıt satırındaki ⋮ menüsünde "Kopyala" — yeni kayıt olarak
  ön doldurulmuş açılır. `widgets/transaction_editor.dart` (`kopya` parametresi), `records_page.dart`.
- Sürüm: `0.4.0+6`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,3 MB).

## 2026-09-09 (6. oturum) — v0.3.2: sabit kayıt düzenlenince aylık kayıtlar da güncellenir (bug düzeltmesi)
- **Bug:** Sabit kaydın kategorisi değiştirilince, o sabit kayıttan oluşturulmuş aylık
  kayıtlar eski kategoride kalıyordu.
- **Neden:** Aylık kayıtlar oluşturulduğu andaki değerleri saklıyor; sabit kayıtla bağları yoktu.
- **Çözüm:** DB v3 göçü — `transactions` tablosuna `recurring_id` sütunu. "Aylara ekle" ve
  "bu ay için kayıt ekle" ile üretilen kayıtlar artık sabit kayda **bağlı**. Sabit kayıt
  düzenlenince bağlı kayıtlar + eski sürümlerde üretilmiş (birebir eski değerlerle eşleşen)
  kayıtlar otomatik eşitleniyor (kategori/tutar/isim/tip).
- **Dosyalar:** `app_database.dart` (v3), `models/transaction_record.dart` (recurringId),
  `data/transaction_repository.dart` (`esitleTekrarlayanKayitlari`), `state/app_state.dart`
  (bağlama + eşitleme), `widgets/transaction_editor.dart`.
- Sürüm: `0.3.2+5`. `flutter analyze` temiz, `flutter test` 12/12, `flutter build apk` başarılı (53,0 MB).
- **Ek düzeltme:** Kategori Analizi'nde seçilen yılda kayıt yoksa yıl okları kayboluyordu;
  yıl seçici artık her durumda görünüyor (boş yıldan ileri/geri gitmek mümkün).
- **Test notu:** Kullanıcı, güncelleme sonrası sabit kaydı bir kez düzenleyip kaydederse
  eski aylık kayıtlar da düzelir.

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
