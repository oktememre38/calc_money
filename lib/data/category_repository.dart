import '../models/category.dart';
import 'app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'type ASC, name ASC');
    return rows.map(Category.fromMap).toList();
  }
}
