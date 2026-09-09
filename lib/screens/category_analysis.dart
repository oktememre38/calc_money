import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aggregate.dart';
import '../models/category.dart';
import '../models/monthly_summary.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';

/// Kategoriye göre o yılın toplamlarını gösteren liste.
/// Bir kategoriye dokununca o kategorinin ay ay değişimi açılır.
class CategoryAnalysisPage extends StatefulWidget {
  const CategoryAnalysisPage({super.key});

  @override
  State<CategoryAnalysisPage> createState() => _CategoryAnalysisPageState();
}

class _CategoryAnalysisPageState extends State<CategoryAnalysisPage> {
  int _yil = DateTime.now().year;
  bool _yukleniyor = true;
  Map<int, Aggregate> _toplamlar = <int, Aggregate>{};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final repo = context.read<AppState>().islemler;
    final toplamlar = await repo.kategoriYillikToplamlar(_yil);
    if (!mounted) return;
    setState(() {
      _toplamlar = toplamlar;
      _yukleniyor = false;
    });
  }

  void _oncekiYil() {
    _yil -= 1;
    _yukle();
  }

  void _sonrakiYil() {
    _yil += 1;
    _yukle();
  }

  void _buYilaDon() {
    _yil = DateTime.now().year;
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Yalnızca o yıl içinde kaydı olan kategorileri listele.
    final kategoriler = <Category>[];
    for (final kategori in state.kategoriListesi) {
      final agg = _toplamlar[kategori.id];
      if (agg == null) continue;
      if (_tipTutari(kategori, agg) > 0) kategoriler.add(kategori);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Analizi')),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                YearSelector(
                  year: _yil,
                  onOnceki: _oncekiYil,
                  onSonraki: _sonrakiYil,
                  onBuguneDon: _buYilaDon,
                ),
                const SizedBox(height: 8),
                if (kategoriler.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    child: Column(
                      children: [
                        Icon(
                          Icons.query_stats,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_yil yılı için kayıt yok.\nÖnce Kayıtlar\'dan gelir/gider ekle.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final kategori in kategoriler)
                    _KategoriSatir(
                      kategori: kategori,
                      toplam: _tipTutari(kategori, _toplamlar[kategori.id]!),
                      yil: _yil,
                    ),
              ],
            ),
    );
  }
}

/// Kategorinin türüne göre (gider/gelir) gösterilecek tutarı seçer.
int _tipTutari(Category kategori, Aggregate agg) =>
    kategori.isGider ? agg.expense : agg.income;

class _KategoriSatir extends StatelessWidget {
  final Category kategori;
  final int toplam;
  final int yil;

  const _KategoriSatir({
    required this.kategori,
    required this.toplam,
    required this.yil,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = kategori.isGider ? giderRengi(context) : gelirRengi(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CategoryMonthPage(
                kategori: kategori,
                yil: yil,
              ),
            ),
          );
        },
        leading: CategoryAvatar(category: kategori),
        title: Text(kategori.name),
        subtitle: const Text('Aylık değişimi gör'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(toplam),
              style: tema.textTheme.titleSmall
                  ?.copyWith(color: renk, fontWeight: FontWeight.bold),
            ),
            Text(
              '$yil toplamı',
              style: tema.textTheme.labelSmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir kategorinin yıl içindeki ay ay toplamlarını gösterir.
class CategoryMonthPage extends StatefulWidget {
  final Category kategori;
  final int yil;

  const CategoryMonthPage({
    super.key,
    required this.kategori,
    required this.yil,
  });

  @override
  State<CategoryMonthPage> createState() => _CategoryMonthPageState();
}

class _CategoryMonthPageState extends State<CategoryMonthPage> {
  bool _yukleniyor = true;
  List<MonthlySummary> _aylar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final repo = context.read<AppState>().islemler;
    final aylar = await repo.kategoriYillikAylik(widget.yil, widget.kategori.id);
    if (!mounted) return;
    setState(() {
      _aylar = aylar;
      _yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final kategori = widget.kategori;
    final renk = kategori.isGider ? giderRengi(context) : gelirRengi(context);

    final degerler = [
      for (final ozet in _aylar) _tipTutari(kategori, ozet.aggregate),
    ];
    final enBuyuk =
        degerler.fold<int>(0, (max, d) => d > max ? d : max);
    final yilToplami =
        degerler.fold<int>(0, (toplam, d) => toplam + d);
    final buAy = DateTime.now().year == widget.yil
        ? DateTime.now().month
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(kategori.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.yil} • ${formatMoney(yilToplami)}',
                style: tema.textTheme.titleSmall?.copyWith(
                  color: renk,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryAvatar(category: kategori),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${widget.yil} yılı • ${kategori.name}',
                                style: tema.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aylık değişim — tutarlar kayıtlarına göre:',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final ozet in _aylar)
                  _AyTutariSatir(
                    month: ozet.month,
                    tutar: _tipTutari(kategori, ozet.aggregate),
                    renk: renk,
                    enBuyuk: enBuyuk,
                    vurgulu: ozet.month == buAy,
                  ),
              ],
            ),
    );
  }
}

class _AyTutariSatir extends StatelessWidget {
  final int month;
  final int tutar;
  final Color renk;
  final int enBuyuk;
  final bool vurgulu;

  const _AyTutariSatir({
    required this.month,
    required this.tutar,
    required this.renk,
    required this.enBuyuk,
    required this.vurgulu,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bos = tutar == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              monthName(month),
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: vurgulu ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bos ? 0 : tutar / enBuyuk,
                minHeight: 8,
                backgroundColor: tema.colorScheme.surfaceContainerHighest,
                color: renk,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              bos ? '—' : formatMoney(tutar),
              textAlign: TextAlign.right,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: bos
                    ? tema.colorScheme.onSurfaceVariant
                    : (vurgulu ? renk : null),
                fontWeight: vurgulu && !bos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
