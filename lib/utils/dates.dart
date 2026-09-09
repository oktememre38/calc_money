/// Tarih yardımcıları. Tarihler veritabanında ISO "yyyy-MM-dd" olarak saklanır.
library;

const List<String> turkishMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String monthName(int month) => turkishMonths[month - 1];

String dateKey(DateTime d) {
  final ay = d.month.toString().padLeft(2, '0');
  final gun = d.day.toString().padLeft(2, '0');
  return '${d.year}-$ay-$gun';
}

String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

String monthYearLabel(int year, int month) => '${monthName(month)} $year';

/// "2026-09-09" => "9 Eylül 2026"
String dayLabelFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  final gun = int.parse(parts[2]);
  final ay = int.parse(parts[1]);
  final yil = int.parse(parts[0]);
  return '$gun ${monthName(ay)} $yil';
}

/// Günün ayın kaçıncı günü olduğunu metin olarak verir (ör. "9 Eylül").
String dayShortLabelFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  final gun = int.parse(parts[2]);
  final ay = int.parse(parts[1]);
  return '$gun ${monthName(ay)}';
}

/// Bir tarihin "hesap dönemi" etiketini döndürür ("yyyy-MM").
///
/// [kesimGunu] 0 ise dönem takvim ayıyla aynıdır. Aksi halde kullanıcının
/// hesap kesim günüdür (1..28): kesim gününe kadar (dahil) olan tarihler o
/// ayın dönemine, kesimden SONRAKİ günler ise bir sonraki ayın dönemine
/// sayılır.
/// Örnek: kesim günü 10 iken 20 Eylül tarihi -> "2026-10" (Ekim dönemi).
String donemEtiketi(DateTime tarih, int kesimGunu) {
  if (kesimGunu <= 0 || tarih.day <= kesimGunu) return monthKey(tarih);
  return monthKey(DateTime(tarih.year, tarih.month + 1, 1));
}
