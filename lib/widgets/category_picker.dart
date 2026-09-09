import 'package:flutter/material.dart';

import '../models/category.dart';
import 'category_visual.dart';

/// Listeden seçilebilir bir "yaprak" kategori döndürür (üst grubu atlar).
Category? ilkSecilebilirKategori(List<Category> kategoriler) {
  for (final kategori in kategoriler) {
    var cocuguVar = false;
    for (final diger in kategoriler) {
      if (diger.parentId == kategori.id) {
        cocuguVar = true;
        break;
      }
    }
    if (!cocuguVar) return kategori;
  }
  return kategoriler.isNotEmpty ? kategoriler.first : null;
}

/// İki aşamalı kategori seçici.
///
/// Üst düzeyde kategori/üst gruplar görünür; çocuğu olan bir gruba dokununca
/// alt kategorileri (yapraklar) açılır ve seçim yapılır. Seçim her zaman
/// "yaprak" kategori üzerinden yapılır.
class CategoryPicker extends StatefulWidget {
  /// Tipine göre filtrelenmiş kategori listesi (üst + alt birlikte).
  final List<Category> kategoriler;
  final int? seciliId;
  final ValueChanged<Category> onSec;

  const CategoryPicker({
    super.key,
    required this.kategoriler,
    required this.seciliId,
    required this.onSec,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  int? _acikUstId;

  List<Category> get _kokler =>
      widget.kategoriler.where((c) => c.parentId == null).toList();

  List<Category> _cocuklar(int ustId) =>
      widget.kategoriler.where((c) => c.parentId == ustId).toList();

  bool _cocuguVar(int id) => _cocuklar(id).isNotEmpty;

  @override
  void initState() {
    super.initState();
    _secilininKokunuAc();
  }

  void _secilininKokunuAc() {
    for (final kategori in widget.kategoriler) {
      if (kategori.id == widget.seciliId && kategori.parentId != null) {
        _acikUstId = kategori.parentId;
        return;
      }
    }
    _acikUstId = null;
  }

  @override
  void didUpdateWidget(CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seçim silindiyse (örn. tip değişince) üst açıklığı sıfırla.
    if (widget.seciliId == null && oldWidget.seciliId != null) {
      _acikUstId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final acikUstId = _acikUstId;
    if (acikUstId != null) {
      final cocuklar = _cocuklar(acikUstId);
      if (cocuklar.isEmpty) {
        _acikUstId = null;
        return _kokWrap(context, null);
      }
      return _altWrap(context, acikUstId, cocuklar);
    }
    return _kokWrap(context, null);
  }

  Widget _kokWrap(BuildContext context, int? zorunluKok) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kategori in _kokler)
          ChoiceChip(
            avatar: Icon(
              kategoriIkon(kategori),
              size: 18,
              color: kategoriRengi(kategori),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kategori.name),
                if (_cocuguVar(kategori.id))
                  const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
            selected: kategori.id == widget.seciliId,
            onSelected: (_) {
              if (_cocuguVar(kategori.id)) {
                setState(() => _acikUstId = kategori.id);
              } else {
                widget.onSec(kategori);
              }
            },
          ),
      ],
    );
  }

  Widget _altWrap(
    BuildContext context,
    int ustId,
    List<Category> cocuklar,
  ) {
    Category? ust;
    for (final k in _kokler) {
      if (k.id == ustId) {
        ust = k;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ust != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.arrow_back, size: 18),
                label: Text(ust.name),
                onPressed: () => setState(() => _acikUstId = null),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cocuk in cocuklar)
              ChoiceChip(
                avatar: Icon(
                  kategoriIkon(cocuk),
                  size: 18,
                  color: kategoriRengi(cocuk),
                ),
                label: Text(cocuk.name),
                selected: cocuk.id == widget.seciliId,
                onSelected: (_) => widget.onSec(cocuk),
              ),
          ],
        ),
      ],
    );
  }
}
