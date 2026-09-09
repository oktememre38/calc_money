import 'record_type.dart';

/// Tekrarlayan sabit kayıt: abonelik, kira, fatura (gider) veya kira geliri,
/// fon/temettü getirisi gibi tekrarlayan gelir.
///
/// Her ayın `dayOfMonth` gününde bildirim ile hatırlatılır; aylık kayda
/// otomatik işlenmez (kullanıcı "Aylara ekle" ile istediği aylara ekler).
class RecurringExpense {
  final int? id;
  final String name;
  final RecordType type;
  final int amountKurus;
  final int dayOfMonth; // 1..28
  final int categoryId;
  final bool notify;
  final bool active;
  final String createdAt;

  const RecurringExpense({
    this.id,
    required this.name,
    this.type = RecordType.gider,
    required this.amountKurus,
    required this.dayOfMonth,
    required this.categoryId,
    this.notify = true,
    this.active = true,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type.toDb,
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
        type: recordTypeFromDb((m['type'] as int?) ?? 1),
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
    RecordType? type,
    int? amountKurus,
    int? dayOfMonth,
    int? categoryId,
    bool? notify,
    bool? active,
  }) =>
      RecurringExpense(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        amountKurus: amountKurus ?? this.amountKurus,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        categoryId: categoryId ?? this.categoryId,
        notify: notify ?? this.notify,
        active: active ?? this.active,
        createdAt: createdAt,
      );
}
