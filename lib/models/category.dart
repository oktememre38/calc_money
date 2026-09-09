/// Kategori (gelir veya gider kategorisi). Alt kategoriler için [parentId] kullanılır.
class Category {
  final int id;
  final String name;

  /// 0 = gelir, 1 = gider
  final int typeDb;
  final String icon;
  final int color;

  /// Üst kategori id'si; yoksa bu kategori üst düzeydir.
  final int? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.typeDb,
    required this.icon,
    required this.color,
    this.parentId,
  });

  bool get isGider => typeDb == 1;

  bool get altKategori => parentId != null;

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int,
        name: m['name'] as String,
        typeDb: m['type'] as int,
        icon: m['icon'] as String,
        color: m['color'] as int,
        parentId: m['parent_id'] as int?,
      );
}
