import 'record_type.dart';

/// Tek bir gelir/gider kaydı.
class TransactionRecord {
  final int? id;
  final RecordType type;
  final int amountKurus;
  final int categoryId;
  final String date; // ISO "yyyy-MM-dd"
  final String note;

  /// Bu kayıt bir sabit kayıttan oluşturulduysa o sabit kaydın id'si (yoksa null).
  final int? recurringId;
  final String createdAt;

  const TransactionRecord({
    this.id,
    required this.type,
    required this.amountKurus,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.recurringId,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'type': type.toDb,
        'amount_kurus': amountKurus,
        'category_id': categoryId,
        'date': date,
        'note': note,
        'recurring_id': recurringId,
        'created_at': createdAt,
      };

  factory TransactionRecord.fromMap(Map<String, Object?> m) => TransactionRecord(
        id: m['id'] as int?,
        type: recordTypeFromDb(m['type'] as int),
        amountKurus: m['amount_kurus'] as int,
        categoryId: m['category_id'] as int,
        date: m['date'] as String,
        note: (m['note'] as String?) ?? '',
        recurringId: m['recurring_id'] as int?,
        createdAt: (m['created_at'] as String?) ?? '',
      );

  TransactionRecord copyWith({
    int? id,
    RecordType? type,
    int? amountKurus,
    int? categoryId,
    String? date,
    String? note,
    int? recurringId,
  }) =>
      TransactionRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        amountKurus: amountKurus ?? this.amountKurus,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        note: note ?? this.note,
        recurringId: recurringId ?? this.recurringId,
        createdAt: createdAt,
      );
}
