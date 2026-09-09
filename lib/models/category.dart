/// Kategori (gelir veya gider kategorisi).
class Category {
  final int id;
  final String name;

  /// 0 = gelir, 1 = gider
  final int typeDb;
  final String icon;
  final int color;

  const Category({
    required this.id,
    required this.name,
    required this.typeDb,
    required this.icon,
    required this.color,
  });

  bool get isGider => typeDb == 1;

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int,
        name: m['name'] as String,
        typeDb: m['type'] as int,
        icon: m['icon'] as String,
        color: m['color'] as int,
      );
}
