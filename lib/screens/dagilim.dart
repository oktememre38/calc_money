import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';

/// Bir ayın gelir/gider dağılımını yüzde + donut diyagramla gösteren kart.
///
/// Veriyi repository'den alır; alt kategoriler üst kategorilerinde toplanır
/// (örn. Su+Elektrik+... -> "Faturalar").
class DagilimKarti extends StatefulWidget {
  final int year;
  final int month;

  const DagilimKarti({super.key, required this.year, required this.month});

  @override
  State<DagilimKarti> createState() => _DagilimKartiState();
}

class _DagilimKartiState extends State<DagilimKarti> {
  bool _gider = true;
  bool _yukleniyor = true;
  List<({Category kategori, int toplam})> _dilimler = [];
  int _tipToplami = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final state = context.read<AppState>();
    final satirlar =
        await state.islemler.ayKategoriDagilimi(widget.year, widget.month);
    if (!mounted) return;

    final tip = _gider ? 1 : 0;
    final toplamlar = <int, int>{};
    for (final satir in satirlar) {
      if (satir.tip != tip) continue;
      final kategori = state.kategoriGetir(satir.categoryId);
      final kok = state.kategoriKokGetir(kategori);
      toplamlar[kok.id] = (toplamlar[kok.id] ?? 0) + satir.toplam;
    }

    final dilimler = <({Category kategori, int toplam})>[];
    toplamlar.forEach((id, tutar) {
      dilimler.add((kategori: state.kategoriGetir(id), toplam: tutar));
    });
    dilimler.sort((a, b) => b.toplam.compareTo(a.toplam));

    setState(() {
      _dilimler = dilimler;
      _tipToplami = dilimler.fold<int>(
        0,
        (toplam, d) => toplam + d.toplam,
      );
      _yukleniyor = false;
    });
  }

  void _tipDegistir(bool gider) {
    if (_gider == gider) return;
    setState(() {
      _gider = gider;
      _yukleniyor = true;
    });
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final baslik =
        '${monthName(widget.month)} ${widget.year} • ${_gider ? 'Gider' : 'Gelir'} dağılımı';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(baslik, style: tema.textTheme.titleSmall),
                ),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Gider'),
                      icon: Icon(Icons.south_west, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Gelir'),
                      icon: Icon(Icons.north_east, size: 16),
                    ),
                  ],
                  selected: {_gider},
                  onSelectionChanged: (secim) =>
                      _tipDegistir(secim.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_yukleniyor)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_dilimler.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Bu ay için ${_gider ? 'gider' : 'gelir'} kaydı yok.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _detayAc,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          dilimler: [
                            for (final d in _dilimler)
                              _DonutDilimi(
                                renk: kategoriRengi(d.kategori),
                                deger: d.toplam.toDouble(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final d in _dilimler)
                            _LegentSatir(
                              kategori: d.kategori,
                              tutar: d.toplam,
                              toplam: _tipToplami,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Toplam: ${formatMoney(_tipToplami)}',
                                style: tema.textTheme.labelMedium?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (!_yukleniyor && _dilimler.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Detay için dokun',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  }

  void _detayAc() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DagilimDetayPage(
          year: widget.year,
          month: widget.month,
        ),
      ),
    );
  }
}

class _LegentSatir extends StatelessWidget {
  final Category kategori;
  final int tutar;
  final int toplam;

  const _LegentSatir({
    required this.kategori,
    required this.tutar,
    required this.toplam,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final yuzde = toplam == 0 ? 0.0 : (tutar / toplam) * 100;
    final yuzdeMetin = yuzde >= 10
        ? '%${yuzde.round()}'
        : '%${yuzde.toStringAsFixed(1)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kategoriRengi(kategori),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kategori.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodySmall,
            ),
          ),
          Text(
            yuzdeMetin,
            style: tema.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutDilimi {
  final Color renk;
  final double deger;

  const _DonutDilimi({required this.renk, required this.deger});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutDilimi> dilimler;

  const _DonutPainter({required this.dilimler});

  @override
  void paint(Canvas canvas, Size size) {
    final toplam = dilimler.fold<double>(
      0,
      (t, d) => t + d.deger,
    );
    if (toplam <= 0) return;

    final merkez = Offset(size.width / 2, size.height / 2);
    final yaricap = size.width / 2 - 6;
    const kalinlik = 26.0;
    const bosluk = 0.03;
    final dikdortgen = Rect.fromCircle(center: merkez, radius: yaricap);
    var baslangic = -1.5708; // 12 yönünde başla

    for (final dilim in dilimler) {
      final acik = (dilim.deger / toplam) * 6.28319;
      final cekilecek = dilimler.length > 1 ? acik - bosluk : acik;
      if (cekilecek <= 0) continue;

      final boya = Paint()
        ..color = dilim.renk
        ..style = PaintingStyle.stroke
        ..strokeWidth = kalinlik
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(dikdortgen, baslangic, cekilecek, false, boya);
      baslangic += acik;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.dilimler != dilimler;
}

/// Bir ay�n gelir/gider da��l�m�n� detayl� g�steren tam ekran sayfa.
class DagilimDetayPage extends StatefulWidget {
  final int year;
  final int month;

  const DagilimDetayPage({super.key, required this.year, required this.month});

  @override
  State<DagilimDetayPage> createState() => _DagilimDetayPageState();
}

class _DagilimDetayPageState extends State<DagilimDetayPage> {
  bool _gider = true;
  bool _yukleniyor = true;
  List<({Category kategori, int toplam})> _dilimler = [];
  int _tipToplami = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final state = context.read<AppState>();
    final satirlar =
        await state.islemler.ayKategoriDagilimi(widget.year, widget.month);
    if (!mounted) return;

    final tip = _gider ? 1 : 0;
    final toplamlar = <int, int>{};
    for (final satir in satirlar) {
      if (satir.tip != tip) continue;
      final kategori = state.kategoriGetir(satir.categoryId);
      final kok = state.kategoriKokGetir(kategori);
      toplamlar[kok.id] = (toplamlar[kok.id] ?? 0) + satir.toplam;
    }

    final dilimler = <({Category kategori, int toplam})>[];
    toplamlar.forEach((id, tutar) {
      dilimler.add((kategori: state.kategoriGetir(id), toplam: tutar));
    });
    dilimler.sort((a, b) => b.toplam.compareTo(a.toplam));

    setState(() {
      _dilimler = dilimler;
      _tipToplami = dilimler.fold<int>(0, (toplam, d) => toplam + d.toplam);
      _yukleniyor = false;
    });
  }

  void _tipDegistir(bool gider) {
    if (_gider == gider) return;
    setState(() {
      _gider = gider;
      _yukleniyor = true;
    });
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${monthName(widget.month)} ${widget.year} � Da��l�m',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: true, label: Text('Gider')),
                  ButtonSegment(value: false, label: Text('Gelir')),
                ],
                selected: {_gider},
                onSelectionChanged: (secim) => _tipDegistir(secim.first),
              ),
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _dilimler.isEmpty
              ? Center(
                  child: Text(
                    'Bu ay i�in ${_gider ? 'gider' : 'gelir'} kayd� yok.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final d in _dilimler)
                              _DetaySatir(
                                kategori: d.kategori,
                                tutar: d.toplam,
                                toplam: _tipToplami,
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Toplam', style: tema.textTheme.titleSmall),
                                Text(
                                  formatMoney(_tipToplami),
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DetaySatir extends StatelessWidget {
  final Category kategori;
  final int tutar;
  final int toplam;

  const _DetaySatir({
    required this.kategori,
    required this.tutar,
    required this.toplam,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final yuzde = toplam == 0 ? 0.0 : (tutar / toplam) * 100;
    final yuzdeMetin = yuzde >= 10
        ? '%${yuzde.round()}'
        : '%${yuzde.toStringAsFixed(1)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              CategoryAvatar(category: kategori, boyut: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kategori.name,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: toplam == 0 ? 0 : tutar / toplam,
                        minHeight: 6,
                        color: kategoriRengi(kategori),
                        backgroundColor: tema.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(tutar),
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    yuzdeMetin,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
