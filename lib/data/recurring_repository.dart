import '../models/recurring_expense.dart';
import 'app_database.dart';

/// Tekrarlayan sabit giderler için veri erişimi.
class RecurringRepository {
  final AppDatabase _db;

  RecurringRepository(this._db);

  Future<List<RecurringExpense>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'recurring_expenses',
      orderBy: 'day_of_month ASC, name ASC',
    );
    return rows.map(RecurringExpense.fromMap).toList();
  }

  Future<int> insert(RecurringExpense kayit) async {
    final db = await _db.database;
    return db.insert('recurring_expenses', kayit.toMap());
  }

  Future<void> update(RecurringExpense kayit) async {
    final db = await _db.database;
    await db.update(
      'recurring_expenses',
      kayit.toMap(),
      where: 'id = ?',
      whereArgs: [kayit.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('recurring_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
