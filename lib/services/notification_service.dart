import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/recurring_expense.dart';
import '../utils/money.dart';

/// Aylık sabit gider hatırlatmaları için bildirim planlama.
///
/// Her aktif + "notify" açık tekrarlayan gider için ayın belirlenen gününde
/// tekrarlanan tek bir zamanlanmış bildirim tutulur. Uygulama her açılışında ve
/// her değişiklikte `senkronize` çağrılır (kendi kendini iyileştirir).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _kanalId = 'aylik_hatirlatmalar';
  static const _kanalAd = 'Aylık Hatırlatmalar';

  bool _hazir = false;

  Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));

      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _kanalId,
          _kanalAd,
          description: 'Tekrarlayan giderler için aylık hatırlatma',
          importance: Importance.high,
        ),
      );
      // Android 13+ için çalışma zamanı bildirim izni iste.
      await androidImpl?.requestNotificationsPermission();
      _hazir = true;
    } catch (e) {
      debugPrint('Bildirim servisi başlatılamadı: $e');
      _hazir = false;
    }
  }

  /// Tüm zamanlanmış bildirimleri iptal edip güncel listeye göre yeniden kurar.
  Future<void> senkronize(List<RecurringExpense> liste) async {
    if (!_hazir) return;
    try {
      await _plugin.cancelAll();
      final simdi = tz.TZDateTime.now(tz.local);

      for (final kayit in liste) {
        if (!kayit.active || !kayit.notify) continue;
        final id = kayit.id;
        if (id == null) continue;

        var zaman = tz.TZDateTime(
          tz.local,
          simdi.year,
          simdi.month,
          kayit.dayOfMonth,
          9,
        );
        if (!zaman.isAfter(simdi)) {
          zaman = _gelecekAy(zaman, kayit.dayOfMonth);
        }

        await _plugin.zonedSchedule(
          id,
          'Gider hatırlatması',
          '${kayit.name}: ${formatMoney(kayit.amountKurus)}',
          zaman,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _kanalId,
              _kanalAd,
              channelDescription: 'Tekrarlayan giderler için aylık hatırlatma',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Bildirim zamanlama hatası: $e');
    }
  }

  Future<void> iptalEt() async {
    if (!_hazir) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Bildirim iptal hatası: $e');
    }
  }

  tz.TZDateTime _gelecekAy(tz.TZDateTime mevcut, int gun) {
    var yil = mevcut.year;
    var ay = mevcut.month + 1;
    if (ay > 12) {
      ay = 1;
      yil += 1;
    }
    return tz.TZDateTime(tz.local, yil, ay, gun, 9);
  }
}
