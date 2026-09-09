import 'record_type.dart';

/// Tekrarlayan sabit kayıt: abonelik, kira, fatura (gider) veya kira geliri,
/// fon/temettü getirisi gibi tekrarlayan gelir; ayrıca sonlu taksitler.
///
/// `dayOfMonth` (1..28) kaydın "Aylara ekle" ile eklendiğinde hangi güne
/// yazılacağını belirler. `toplamAy` 0 ise kayıt süreklidir; 0'dan büyükse
/// (ör. 5 taksit) o sayıda aylık kayıt oluşturulunca kayıt otomatik silinir.
class RecurringExpense {
  final int? id;
  final String name;
  final RecordType type;
  final int amountKurus;
  final int dayOfMonth; // 1..28
  final int categoryId;

  /// 0 = sürekli; >0 ise toplam oluşturulacak ay sayısı (taksit/bitiş).
  final int toplamAy;
  final bool active;
  final String createdAt;

  const RecurringExpense({
    this.id,
    required this.name,
    this.type = RecordType.gider,
    required this.amountKurus,
    required this.dayOfMonth,
    required this.categoryId,
    this.toplamAy = 0,
    this.active = true,
    this.createdAt = '',
  });

  bool get sonlu => toplamAy > 0;

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type.toDb,
        'amount_kurus': amountKurus,
        'day_of_month': dayOfMonth,
        'category_id': categoryId,
        'toplam_ay': toplamAy,
        'active': active ? 1 : 0,
        'created_at': createdAt,
      };

  factory RecurringExpense.fromMap(Map<String, Object?> m) => RecurringExpense(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: recordTypeFromDb((m['type'] as int?) ?? 1),
        amountKurus: m['amount_kurus'] as int,
        dayOfMonth: m['day_of_month'] as int,
        categoryId: m['category_id'] as int,
        toplamAy: (m['toplam_ay'] as int?) ?? 0,
        active: (m['active'] as int) == 1,
        createdAt: (m['created_at'] as String?) ?? '',
      );

  RecurringExpense copyWith({
    int? id,
    String? name,
    RecordType? type,
    int? amountKurus,
    int? dayOfMonth,
    int? categoryId,
    int? toplamAy,
    bool? active,
  }) =>
      RecurringExpense(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        amountKurus: amountKurus ?? this.amountKurus,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        categoryId: categoryId ?? this.categoryId,
        toplamAy: toplamAy ?? this.toplamAy,
        active: active ?? this.active,
        createdAt: createdAt,
      );
}
