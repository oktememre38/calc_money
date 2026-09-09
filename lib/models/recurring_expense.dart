/// Tekrarlayan (sabit) gider: abonelik, kira, fatura vb.
///
/// Her ayın `dayOfMonth` gününde bildirim ile hatırlatılır; aylık gider kaydına
/// otomatik işlenmez (kullanıcı kaydı kendisi ekler).
class RecurringExpense {
  final int? id;
  final String name;
  final int amountKurus;
  final int dayOfMonth; // 1..28
  final int categoryId;
  final bool notify;
  final bool active;
  final String createdAt;

  const RecurringExpense({
    this.id,
    required this.name,
    required this.amountKurus,
    required this.dayOfMonth,
    required this.categoryId,
    this.notify = true,
    this.active = true,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'amount_kurus': amountKurus,
        'day_of_month': dayOfMonth,
        'category_id': categoryId,
        'notify': notify ? 1 : 0,
        'active': active ? 1 : 0,
        'created_at': createdAt,
      };

  factory RecurringExpense.fromMap(Map<String, Object?> m) => RecurringExpense(
        id: m['id'] as int?,
        name: m['name'] as String,
        amountKurus: m['amount_kurus'] as int,
        dayOfMonth: m['day_of_month'] as int,
        categoryId: m['category_id'] as int,
        notify: (m['notify'] as int) == 1,
        active: (m['active'] as int) == 1,
        createdAt: (m['created_at'] as String?) ?? '',
      );

  RecurringExpense copyWith({
    int? id,
    String? name,
    int? amountKurus,
    int? dayOfMonth,
    int? categoryId,
    bool? notify,
    bool? active,
  }) =>
      RecurringExpense(
        id: id ?? this.id,
        name: name ?? this.name,
        amountKurus: amountKurus ?? this.amountKurus,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        categoryId: categoryId ?? this.categoryId,
        notify: notify ?? this.notify,
        active: active ?? this.active,
        createdAt: createdAt,
      );
}
