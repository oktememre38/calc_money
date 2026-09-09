# Kurulum Rehberi — Yeni Makinede Ayağa Kaldırma

Bu rehber, projeyi **sıfır bir makinede** (veya bu makinede Flutter kurulunca)
çalıştırmak ve geliştirmeye devam etmek içindir. Adımları sırayla uygula.

> İpucu: Bu repoyu açan bir yapay zeka ajanı önce `meta/README.md` ve
> `meta/proje-bilgisi.md`'yi okumalıdır. Kök `AGENTS.md` da buna işaret eder.

---

## 1. Ön koşullar
- Git (kurulu).
- Flutter SDK (stable) → https://docs.flutter.dev/get-started/install
  - Windows'ta SDK'yı indirip bir klasöre (örn. `C:\flutter`) aç, `bin` klasörünü PATH'e ekle.
- Android geliştirme:
  - Android Studio (veya en azından Android SDK + platform-tools `adb`).
  - `flutter doctor` çıktısında Android toolchain "OK" olmalı.
  - Telefon: Geliştirici seçenekleri + USB hata ayıklama açık; `adb devices` ile görünmeli.
  - (İstersen Android Studio emülatörü de kullanılabilir.)

Kontrol:
```
flutter --version
flutter doctor
adb devices
```

## 2. Projeyi klonla ve platform dosyalarını üret
```powershell
git clone <repo-url> CalcMoney
cd CalcMoney
flutter create --org com.calcmoney --platforms=android,ios --project-name calc_money .
flutter pub get
```
`flutter create .` **sadece** `android/`, `ios/` platform klasörlerini üretir;
`lib/` kodlarımıza ve `pubspec.yaml`'a dokunmaz.

## 3. Release imza yapılandırması (keystore)
APK'lar kalıcı bir keystore ile imzalanır (v0.7.0+). Bu repo `public` olduğundan anahtar dosyası
**git'e girmez**; her geliştirme makinesinde elle kurulur:
- Keystore dosyasını makinede tut (örn. `C:\Users\<kullanici>\keystores\calcmoney-release.jks`).
- `android/key.properties` oluştur (gitignore'da):
```
storePassword=...
keyPassword=...
keyAlias=calcmoney
storeFile=C:/Users/<kullanici>/keystores/calcmoney-release.jks
```
- `build.gradle.kts` bu dosyayı okur; dosya yoksa geliştirme için debug imzaya düşer.
- UYARI: Anahtar + parola kaybolursa mevcut kullanıcılar güncelleme alamaz; iki yerde yedekle.
- İki bilgisayar kullanılıyorsa **aynı keystore dosyası** her iki makinede de aynı yolu göstermeli.

## 4. Analiz ve çalıştır
```powershell
flutter analyze
flutter run -d <cihaz-idsi>     # adb devices ile listele
```
- İlk Android derlemesi uzun sürebilir (Gradle indirmeleri).
- Bağımlılık çakışması olursa: `flutter pub upgrade` dene; hâlâ çözülmezse
  `pubspec.yaml` sürüm kısıtlarına bak (paketlerin güncel büyük sürümlerini kontrol et).

## 5. Çalışma sonrası test senaryoları
1. İlk açılış: varsayılan kategoriler görünmeli.
2. Bir gelir + birkaç gider ekle → Genel Bakış'ta ay dengesi doğru mu?
3. Geçmiş bir aya geç (oklar) → kayıtlar ve toplamlar.
4. Yıllık sekmesi → 12 ay dökümü + yıl toplamı.
5. Sabit kayıt ekle (örn. "Netflix", 149.99, ayın 5'i, Abonelik) → "Aylara ekle" ile ay seç,
   kayıt o güne yazıldı mı? Sonlu taksit için "Toplam ay" gir → o sayıda kayıt sonrası
   sabit kayıt otomatik siliniyor mu?
6. Ayarlar → Yedek al → .db dosyası oluşuyor mu; geri yükleyince veri geliyor mu?
7. Kayıt düzenleme, silme (onay sorusu), gelir/gider tipi değiştirme.

## 6. Geliştirme döngüsü notları
- Dart kodu `lib/` altındadır; değiştirip `flutter run` (hot reload) ile dene.
- Bir özellik tamamlanınca `meta/ilerleme.md`'ye tarihli madde ekle.
- `flutter analyze` çıktısı temiz olmalı (flutter_lints).
- Test: `flutter test` (utils testleri vardır; widget testleri zamanla eklenir).
