# CalcMoney — Gelir / Gider Takip Uygulaması

Android telefonlar için **Flutter** ile yazılmış, veriyi **cihaz üzerinde (SQLite)** tutan,
Türkçe bir gelir-gider takip uygulaması.

## Özellikler
- Gelir ve gider kayıtları (kategori, tutar, tarih, not)
- Aylık gelir / gider / denge özeti
- Yıllık toplamlar (12 aylık döküm)
- Tekrarlayan sabit giderler (kira, su, doğalgaz, abonelikler...) ve aylık **hatırlatma bildirimi**

## Hızlı başlangıç (Flutter kurulu bir makinede)
```
flutter create --org com.calcmoney --platforms=android,ios --project-name calc_money .
flutter pub get
flutter analyze
flutter run
```
> `flutter create` yalnızca platform klasörlerini (android/ios) üretir; `lib/` kodları korunur.
> Android için gereken ekstra yapılandırma (desugaring, izinler) için **meta/kurulum-rehberi.md** dosyasına bakın.

## Dokümantasyon
`meta/` klasörü projenin beynidir: hedef, kararlar, ilerleme günlüğü ve yeni makinede devam rehberi oradadır.
- `meta/README.md` — içindekiler
- `meta/proje-bilgisi.md` — hedef, kararlar, veri modeli
- `meta/ilerleme.md` — ilerleme günlüğü (güncel durum)
- `meta/kurulum-rehberi.md` — sıfırdan çalıştırma adımları

## Mimari özeti
`lib/` içinde: `models/` (veri modelleri), `data/` (SQLite + repository'ler),
`services/` (bildirim), `state/` (AppState), `screens/` (sayfalar), `widgets/` (ortak arayüz parçaları).
Para birimi tamsayı **kuruş** olarak saklanır (ondalık hata olmaması için).
