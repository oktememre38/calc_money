import '../models/aggregate.dart';
import '../models/monthly_summary.dart';
import '../models/transaction_record.dart';
import 'app_database.dart';

/// Gelir/gider kayıtları için veri erişimi.
class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Future<List<TransactionRecord>> listByMonth(int year, int month) async {
    final db = await _db.database;
    final prefix = _ayPrefiksi(year, month);
    final rows = await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }

  /// Tek bir ayın gelir/gider toplamı.
  Future<Aggregate> aggregateByMonth(int year, int month) async {
    final db = await _db.database;
    final prefix = _ayPrefiksi(year, month);
    final rows = await db.rawQuery(
      'SELECT '
      'COALESCE(SUM(CASE WHEN type = 0 THEN amount_kurus END), 0) AS gelir, '
      'COALESCE(SUM(CASE WHEN type = 1 THEN amount_kurus END), 0) AS gider '
      'FROM transactions WHERE date LIKE ?',
      ['$prefix%'],
    );
    final row = rows.first;
    return Aggregate(
      income: row['gelir'] as int,
      expense: row['gider'] as int,
    );
  }

  /// Bir yılın tüm ayları için özet (ay 1..12).
  Future<List<MonthlySummary>> aggregateByYear(int year) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT '
      'CAST(substr(date, 6, 2) AS INTEGER) AS ay, '
      'COALESCE(SUM(CASE WHEN type = 0 THEN amount_kurus END), 0) AS gelir, '
      'COALESCE(SUM(CASE WHEN type = 1 THEN amount_kurus END), 0) AS gider '
      'FROM transactions WHERE substr(date, 1, 4) = ? '
      'GROUP BY ay ORDER BY ay',
      ['$year'],
    );

    final map = <int, Aggregate>{};
    for (final row in rows) {
      map[row['ay'] as int] = Aggregate(
        income: row['gelir'] as int,
        expense: row['gider'] as int,
      );
    }
    return [
      for (var ay = 1; ay <= 12; ay++)
        MonthlySummary(month: ay, aggregate: map[ay] ?? const Aggregate()),
    ];
  }

  /// Bir yıl içinde her kategorinin gelir/gider toplamları (kategoriId -> toplam).
  Future<Map<int, Aggregate>> kategoriYillikToplamlar(int year) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT '
      'category_id, '
      'COALESCE(SUM(CASE WHEN type = 0 THEN amount_kurus END), 0) AS gelir, '
      'COALESCE(SUM(CASE WHEN type = 1 THEN amount_kurus END), 0) AS gider '
      'FROM transactions WHERE substr(date, 1, 4) = ? '
      'GROUP BY category_id',
      ['$year'],
    );
    return {
      for (final row in rows)
        row['category_id'] as int: Aggregate(
          income: row['gelir'] as int,
          expense: row['gider'] as int,
        ),
    };
  }

  /// Tek bir kategorinin bir yıldaki aylık toplamları (ay 1..12).
  Future<List<MonthlySummary>> kategoriYillikAylik(
    int year,
    int categoryId,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT '
      'CAST(substr(date, 6, 2) AS INTEGER) AS ay, '
      'COALESCE(SUM(CASE WHEN type = 0 THEN amount_kurus END), 0) AS gelir, '
      'COALESCE(SUM(CASE WHEN type = 1 THEN amount_kurus END), 0) AS gider '
      'FROM transactions '
      'WHERE substr(date, 1, 4) = ? AND category_id = ? '
      'GROUP BY ay ORDER BY ay',
      ['$year', categoryId],
    );

    final map = <int, Aggregate>{};
    for (final row in rows) {
      map[row['ay'] as int] = Aggregate(
        income: row['gelir'] as int,
        expense: row['gider'] as int,
      );
    }
    return [
      for (var ay = 1; ay <= 12; ay++)
        MonthlySummary(month: ay, aggregate: map[ay] ?? const Aggregate()),
    ];
  }

  /// Bir sabit kayıt düzenlendiğinde, o sabit kayıttan üretilmiş aylık kayıtları
  /// yeni değerlere eşitler. Hem doğrudan bağlı (`recurring_id`) kayıtlar hem de
  /// eski sürümlerde oluşturulup bağlanmamış ama birebir eski şablon değerleriyle
  /// eşleşen kayıtlar güncellenir.
  Future<void> esitleTekrarlayanKayitlari({
    required int recurringId,
    required int eskiTypeDb,
    required int eskiAmountKurus,
    required int eskiCategoryId,
    required String eskiNote,
    required int yeniTypeDb,
    required int yeniAmountKurus,
    required int yeniCategoryId,
    required String yeniNote,
  }) async {
    final db = await _db.database;

    // Henüz bağlanmamış ama eski şablon değerleriyle birebir eşleşen kayıtlar.
    await db.update(
      'transactions',
      {
        'type': yeniTypeDb,
        'amount_kurus': yeniAmountKurus,
        'category_id': yeniCategoryId,
        'note': yeniNote,
        'recurring_id': recurringId,
      },
      where: 'recurring_id IS NULL '
          'AND type = ? AND category_id = ? AND amount_kurus = ? AND note = ?',
      whereArgs: [eskiTypeDb, eskiCategoryId, eskiAmountKurus, eskiNote],
    );

    // Bağlı kayıtlar.
    await db.update(
      'transactions',
      {
        'type': yeniTypeDb,
        'amount_kurus': yeniAmountKurus,
        'category_id': yeniCategoryId,
        'note': yeniNote,
      },
      where: 'recurring_id = ?',
      whereArgs: [recurringId],
    );
  }

  Future<int> insert(TransactionRecord kayit) async {
    final db = await _db.database;
    return db.insert('transactions', kayit.toMap());
  }

  Future<void> update(TransactionRecord kayit) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      kayit.toMap(),
      where: 'id = ?',
      whereArgs: [kayit.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  String _ayPrefiksi(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
