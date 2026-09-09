import 'record_type.dart';

/// Tek bir gelir/gider kaydı.
class TransactionRecord {
  final int? id;
  final RecordType type;
  final int amountKurus;
  final int categoryId;
  final String date; // ISO "yyyy-MM-dd"

  /// Kaydın ait olduğu "hesap dönemi" etiketi ("yyyy-MM").
  ///
  /// Hesap kesim günü kapalıyken takvim ayıyla aynıdır; kesim günü tanımlıysa
  /// kayıt, kesimden sonraki günlerdeyse bir sonraki ayın dönemine yazılır.
  final String donem;
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
    required this.donem,
    this.note = '',
    this.recurringId,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'type': type.toDb,
        'amount_kurus': amountKurus,
        'category_id': categoryId,
        'date': date,
        'donem': donem,
        'note': note,
        'recurring_id': recurringId,
        'created_at': createdAt,
      };

  factory TransactionRecord.fromMap(Map<String, Object?> m) {
    final date = m['date'] as String;
    final donem = (m['donem'] as String?) ?? '';
    return TransactionRecord(
      id: m['id'] as int?,
      type: recordTypeFromDb(m['type'] as int),
      amountKurus: m['amount_kurus'] as int,
      categoryId: m['category_id'] as int,
      date: date,
      // Boşsa (eski/önbellek satır) takvim ayı varsay.
      donem: donem.isNotEmpty && donem.length >= 7
          ? donem.substring(0, 7)
          : date.substring(0, 7),
      note: (m['note'] as String?) ?? '',
      recurringId: m['recurring_id'] as int?,
      createdAt: (m['created_at'] as String?) ?? '',
    );
  }

  TransactionRecord copyWith({
    int? id,
    RecordType? type,
    int? amountKurus,
    int? categoryId,
    String? date,
    String? donem,
    String? note,
    int? recurringId,
  }) =>
      TransactionRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        amountKurus: amountKurus ?? this.amountKurus,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        donem: donem ?? this.donem,
        note: note ?? this.note,
        recurringId: recurringId ?? this.recurringId,
        createdAt: createdAt,
      );
}
