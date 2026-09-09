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

## 3. Android yapılandırması (flutter_local_notifications için)
Aşağıdaki iki dosyayı el ile düzenle.

### a) `android/app/build.gradle.kts` (Kotlin DSL, yeni projelerde varsayılan)
Desugaring'i aç (paket java.time kullanır). `android { }` bloğundaki mevcut `compileOptions` içine ekle:
```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
```
Ayrıca dosya sonundaki `dependencies { }` bloğuna ekle:
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
> Proje hâlâ Groovy (`android/app/build.gradle`) kullanıyorsa karşılıkları:
> `compileOptions { coreLibraryDesugaringEnabled true }` ve
> `dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' }`

### b) `android/app/src/main/AndroidManifest.xml`
`<manifest>` içine izinler:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```
`<application>` içine bildirim alıcıları:
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```
> Not: Android 12+ cihazlarda zamanlanmış bildirimin tam zamanda gelmesi için
> `SCHEDULE_EXACT_ALARM` izni kullanıcı tarafından ayrıca verilebilir; uygulama
> hassas olmayan zamanlamayla da çalışır (bildirim yaklaşık zamanda gelir).

## 4. Analiz ve çalıştır
```powershell
flutter analyze
flutter run -d <cihaz-idsi>     # adb devices ile listele
```
- İlk Android derlemesi uzun sürebilir (Gradle indirmeleri).
- Bağımlılık çakışması olursa: `flutter pub upgrade` dene; hâlâ çözülmezse
  `pubspec.yaml` sürüm kısıtlarına bak (paketlerin güncel büyük sürümlerini kontrol et).

## 5. Çalışma sonrası test senaryoları
1. İlk açılış: varsayılan kategoriler görünmeli, bildirim izni sorulmalı.
2. Bir gelir + birkaç gider ekle → Genel Bakış'ta ay dengesi doğru mu?
3. Geçmiş bir aya geç (oklar) → kayıtlar ve toplamlar.
4. Yıllık sekmesi → 12 ay dökümü + yıl toplamı.
5. Abonelik ekle (örn. "Netflix", 149.99, ayın 5'i, Abonelik kategorisi) →
   bildirim programlandı mı (güncelleme sonrası kontrol için log).
6. Kayıt düzenleme, silme (onay sorusu), gelir/gider tipi değiştirme.

## 6. Geliştirme döngüsü notları
- Dart kodu `lib/` altındadır; değiştirip `flutter run` (hot reload) ile dene.
- Bir özellik tamamlanınca `meta/ilerleme.md`'ye tarihli madde ekle.
- `flutter analyze` çıktısı temiz olmalı (flutter_lints).
- Test: `flutter test` (utils testleri vardır; widget testleri zamanla eklenir).
