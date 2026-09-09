# İlerleme Günlüğü — CalcMoney

Bu dosya tarihli, kısa maddelerle projenin durumunu tutar. En yeni madde en üsttedir.
Her tamamlanan iş için yeni bir bölüm ekle.

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
