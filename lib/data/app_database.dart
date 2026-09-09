import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite veritabanı: açılış, şema ve varsayılan kategori tohumları.
class AppDatabase {
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<void> open() async {
    await database;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'calc_money.db'),
      version: 6,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _db = db;
    return db;
  }

  Future<void> _onUpgrade(Database db, int eski, int yeni) async {
    if (eski < 2) {
      // v2: sabit kayıtlar artık gelir de olabilir. Mevcut satırlar gider (1) sayılır.
      await db.execute(
        'ALTER TABLE recurring_expenses ADD COLUMN type INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (eski < 3) {
      // v3: aylık kayıtlar hangi sabit kayıttan oluşturulduysa ona bağlanır.
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurring_id INTEGER',
      );
    }
    if (eski < 4) {
      // v4: basit anahtar/değer ayar tablosu (örn. tema).
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (eski < 5) {
      // v5: kategorilere üst kategori (alt kategori) desteği.
      await db.execute(
        'ALTER TABLE categories ADD COLUMN parent_id INTEGER',
      );
      await _faturaGoc(db);
    }
    if (eski < 6) {
      // v6: işlemlere "hesap dönemi" etiketi (yyyy-MM). Mevcut satırlar
      // takvim ayına göre doldurulur (kesim günü kapalı).
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN donem TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "UPDATE transactions SET donem = substr(date, 1, 7) WHERE donem = ''",
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_trans_donem ON transactions(donem)',
      );
      await _yeniKategorileriEkle(db);
    }
  }

  /// v6 ile gelen yeni gider kategorilerini eksikse ekler (var olan kurulumlar).
  Future<void> _yeniKategorileriEkle(Database db) async {
    for (final tohum in _giderTohum) {
      await _kategoriBulVeyaEkle(
        db,
        name: tohum['name'] as String,
        type: 1,
        icon: tohum['icon'] as String,
        color: tohum['color'] as int,
      );
    }
  }

  /// "Faturalar" üst kategorisini kurar ve Su/Elektrik/Doğalgaz/İnternet/
  /// Telefon gibi varsa mevcut kategorileri altına taşır (kimlikleri korunur).
  Future<void> _faturaGoc(Database db) async {
    final ustId = await _kategoriBulVeyaEkle(
      db,
      name: 'Faturalar',
      type: 1,
      icon: 'receipt_long',
      color: 0xFF006064,
    );
    for (final cocuk in _faturaCocuklar) {
      final cocukId = await _kategoriBulVeyaEkle(
        db,
        name: cocuk['name'] as String,
        type: 1,
        icon: cocuk['icon'] as String,
        color: cocuk['color'] as int,
      );
      await db.update(
        'categories',
        {'parent_id': ustId},
        where: 'id = ?',
        whereArgs: [cocukId],
      );
    }
  }

  Future<int> _kategoriBulVeyaEkle(
    Database db, {
    required String name,
    required int type,
    required String icon,
    required int color,
  }) async {
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return db.insert('categories', {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        parent_id INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amount_kurus INTEGER NOT NULL CHECK (amount_kurus >= 0),
        category_id INTEGER NOT NULL REFERENCES categories(id),
        date TEXT NOT NULL,
        donem TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        recurring_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_trans_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_trans_donem ON transactions(donem)');
    await db.execute('''
      CREATE TABLE recurring_expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL DEFAULT 1,
        amount_kurus INTEGER NOT NULL CHECK (amount_kurus >= 0),
        day_of_month INTEGER NOT NULL CHECK (day_of_month BETWEEN 1 AND 28),
        category_id INTEGER NOT NULL REFERENCES categories(id),
        notify INTEGER NOT NULL DEFAULT 1,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final batch = db.batch();
    for (final seed in _gelirTohum) {
      batch.insert('categories', {...seed, 'type': 0});
    }
    for (final seed in _giderTohum) {
      batch.insert('categories', {...seed, 'type': 1});
    }
    await batch.commit(noResult: true);

    // "Faturalar" üst kategorisi ve alt kategorileri.
    final ustId = await db.insert('categories', {
      'name': 'Faturalar',
      'type': 1,
      'icon': 'receipt_long',
      'color': 0xFF006064,
    });
    for (final cocuk in _faturaCocuklar) {
      await db.insert('categories', {...cocuk, 'type': 1, 'parent_id': ustId});
    }
  }

  static const _gelirTohum = <Map<String, Object>>[
    {'name': 'Maaş', 'icon': 'payments', 'color': 0xFF1565C0},
    {'name': 'Ek Gelir', 'icon': 'add_card', 'color': 0xFF00838F},
    {'name': 'Kira Geliri', 'icon': 'home_work', 'color': 0xFF6A1B9A},
    {'name': 'Yatırım', 'icon': 'trending_up', 'color': 0xFF2E7D32},
    {'name': 'Diğer Gelir', 'icon': 'savings', 'color': 0xFF455A64},
  ];

  static const _giderTohum = <Map<String, Object>>[
    {'name': 'Kira', 'icon': 'apartment', 'color': 0xFF5D4037},
    {'name': 'Market', 'icon': 'shopping_cart', 'color': 0xFF2E7D32},
    {'name': 'Abonelik', 'icon': 'subscriptions', 'color': 0xFF7B1FA2},
    {'name': 'Ulaşım', 'icon': 'directions_bus', 'color': 0xFFEF6C00},
    {'name': 'Sağlık', 'icon': 'medical_services', 'color': 0xFFC62828},
    {'name': 'Eğlence', 'icon': 'movie', 'color': 0xFFAD1457},
    {'name': 'Eğitim', 'icon': 'school', 'color': 0xFF283593},
    {'name': 'Giyim', 'icon': 'checkroom', 'color': 0xFF6D4C41},
    {'name': 'Alışveriş', 'icon': 'shopping_bag', 'color': 0xFF00838F},
    {'name': 'Taksit', 'icon': 'credit_card', 'color': 0xFF5E35B1},
    {'name': 'Diğer', 'icon': 'category', 'color': 0xFF616161},
  ];

  static const _faturaCocuklar = <Map<String, Object>>[
    {'name': 'Su', 'icon': 'water_drop', 'color': 0xFF0277BD},
    {'name': 'Doğalgaz', 'icon': 'local_fire_department', 'color': 0xFFE65100},
    {'name': 'Elektrik', 'icon': 'bolt', 'color': 0xFFF9A825},
    {'name': 'İnternet', 'icon': 'wifi', 'color': 0xFF00695C},
    {'name': 'Telefon', 'icon': 'phone_android', 'color': 0xFF00838F},
  ];
}
