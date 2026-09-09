/// Para yardımcıları.
///
/// Para her zaman tamsayı KURUŞ olarak saklanır (ör. 12,5 TL => 1250).
/// Görüntülemede ₺'ye çevrilir; kayan nokta (double) ile işlem yapılmaz.
library;

/// Kuruş cinsinden tutarı "₺1.234,56" biçiminde yazar. Negatifse başına "-" eklenir.
String formatMoney(int kurus) {
  final negatif = kurus < 0;
  final mutlak = kurus.abs();
  final lira = mutlak ~/ 100;
  final kuruş = mutlak % 100;
  final sonuc = '₺${_binlikAyir(lira)},${kuruş.toString().padLeft(2, '0')}';
  return negatif ? '-$sonuc' : sonuc;
}

String _binlikAyir(int deger) {
  final s = deger.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Kuruş değerini form alanı için "149,99" gibi metne çevirir.
String kurusToGirdi(int kurus) {
  final lira = kurus ~/ 100;
  final kuruş = kurus % 100;
  if (kuruş == 0) return '$lira';
  return '$lira,${kuruş.toString().padLeft(2, '0')}';
}

/// Kullanıcının girdiği metni kuruşa çevirir. Boş/geçersizse null döner.
///
/// Desteklenen biçimler: "1234", "12,5", "12,99", "1.234,56", "1234.56",
/// "1.234.56" (virgül yoksa son nokta ondalık kabul edilir), "1.500" (binlik ayracı).
int? parseToKurus(String giris) {
  var s = giris.trim().replaceAll('₺', '').replaceAll(' ', '').trim();
  if (s.isEmpty) return null;

  if (s.contains(',')) {
    // Virgül ondalıksa noktalar binlik ayracıdır.
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (s.contains('.')) {
    final sonNokta = s.lastIndexOf('.');
    final sonGrupUzunluk = s.length - sonNokta - 1;
    if (sonGrupUzunluk >= 1 && sonGrupUzunluk <= 2) {
      // Son noktayı ondalık ayracı kabul et, öncekileri binlik kabul et.
      final noktasiz = s.replaceAll('.', '');
      final kesim = noktasiz.length - sonGrupUzunluk;
      s = '${noktasiz.substring(0, kesim)}.${noktasiz.substring(kesim)}';
    } else {
      // Binlik ayracı; tüm noktaları kaldır.
      s = s.replaceAll('.', '');
    }
  }

  final deger = double.tryParse(s);
  if (deger == null || deger < 0) return null;
  return (deger * 100).round();
}
