import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/record_type.dart';
import '../models/transaction_record.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/summary_bar.dart';
import '../widgets/transaction_editor.dart';
import 'category_analysis.dart';

/// Kayıtlar: seçili ayın gelir/gider listesi, özet, arama ve kategori filtresi.
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _arama = '';
  int? _kategoriId;

  bool get _filtreVar => _kategoriId != null || _arama.trim().isNotEmpty;

  List<TransactionRecord> _filtrele(
    AppState state,
    List<TransactionRecord> kayitlar,
  ) {
    final q = _arama.trim().toLowerCase();
    return kayitlar.where((kayit) {
      if (_kategoriId != null && kayit.categoryId != _kategoriId) return false;
      if (q.isEmpty) return true;
      final kategoriAdi = state.kategoriGetir(kayit.categoryId).name.toLowerCase();
      return kategoriAdi.contains(q) || kayit.note.toLowerCase().contains(q);
    }).toList();
  }

  /// Ay içinde kaydı olan kategoriler (listedeki sıraya göre).
  List<Category> _ayKategorileri(AppState state) {
    final kullanilan = <int>{};
    for (final kayit in state.ayKayitlari) {
      kullanilan.add(kayit.categoryId);
    }
    return [
      for (final kategori in state.kategoriListesi)
        if (kullanilan.contains(kategori.id)) kategori,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtreli = _filtrele(state, state.ayKayitlari);
    final ayKategorileri = _ayKategorileri(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıtlar'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryAnalysisPage(),
                ),
              );
            },
            icon: const Icon(Icons.query_stats),
            tooltip: 'Kategori analizi',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionEditor(context),
        tooltip: 'Kayıt ekle',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          MonthSelector(
            year: state.gorunenAy.year,
            month: state.gorunenAy.month,
            onOnceki: state.oncekiAy,
            onSonraki: state.sonrakiAy,
            onBuguneDon: state.buAyaDon,
            onTitleTap: () => _farkliAySec(context, state),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _AramaKutusu(
              deger: _arama,
              onDegis: (v) => setState(() => _arama = v),
            ),
          ),
          if (ayKategorileri.isNotEmpty)
            _KategoriFiltreleri(
              kategoriler: ayKategorileri,
              seciliId: _kategoriId,
              onSec: (id) => setState(() => _kategoriId = id),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AylikOzetBar(ozet: state.ayOzet),
          ),
          if (_filtreVar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filtreli.length} / ${state.ayKayitlari.length} kayıt gösteriliyor',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _arama = '';
                      _kategoriId = null;
                    }),
                    child: const Text('Filtreyi temizle'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: state.ayKayitlari.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long,
                    mesaj:
                        'Bu ay için henüz kayıt yok.\nSağ alttaki + butonu ile gelir veya gider ekleyebilirsin.',
                  )
                : filtreli.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        mesaj: 'Filtreye uygun kayıt yok.',
                      )
                    : _KayitListesi(state: state, kayitlar: filtreli),
          ),
        ],
      ),
    );
  }
}

class _AramaKutusu extends StatelessWidget {
  final String deger;
  final ValueChanged<String> onDegis;

  const _AramaKutusu({required this.deger, required this.onDegis});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onDegis,
      controller: null,
      decoration: InputDecoration(
        hintText: 'Ara: not veya kategori',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: deger.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onDegis(''),
              ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _KategoriFiltreleri extends StatelessWidget {
  final List<Category> kategoriler;
  final int? seciliId;
  final ValueChanged<int?> onSec;

  const _KategoriFiltreleri({
    required this.kategoriler,
    required this.seciliId,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tümü'),
              selected: seciliId == null,
              onSelected: (_) => onSec(null),
            ),
          ),
          for (final kategori in kategoriler)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  kategoriIkon(kategori),
                  size: 16,
                  color: kategoriRengi(kategori),
                ),
                label: Text(kategori.name),
                selected: kategori.id == seciliId,
                onSelected: (_) => onSec(kategori.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _KayitListesi extends StatelessWidget {
  final AppState state;
  final List<TransactionRecord> kayitlar;

  const _KayitListesi({required this.state, required this.kayitlar});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final kayit in kayitlar)
          _KayitSatiri(state: state, kayit: kayit),
      ],
    );
  }
}

class _KayitSatiri extends StatelessWidget {
  final AppState state;
  final TransactionRecord kayit;

  const _KayitSatiri({required this.state, required this.kayit});

  @override
  Widget build(BuildContext context) {
    final kategori = state.kategoriGetir(kayit.categoryId);
    final renk = tipRengi(context, kayit.type);
    final isaret = kayit.type == RecordType.gelir ? '+' : '-';
    final tarih = dayShortLabelFromKey(kayit.date);
    final altYazi = kayit.note.isNotEmpty ? '$tarih • ${kayit.note}' : tarih;
    final messenger = ScaffoldMessenger.of(context);

    return Dismissible(
      key: ValueKey(kayit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: giderRengi(context),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => onayIste(
        context,
        baslik: 'Kayıt silinsin mi?',
        mesaj: '${formatMoney(kayit.amountKurus)} tutarındaki kayıt',
      ),
      onDismissed: (_) {
        state.kayitSil(kayit);
        _geriAlGoster(messenger, state, 'Kayıt silindi');
      },
      child: ListTile(
        onTap: () => showTransactionEditor(context, mevcut: kayit),
        leading: CategoryAvatar(category: kategori),
        title: Text(
          kategori.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          altYazi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$isaret${formatMoney(kayit.amountKurus)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: renk, fontWeight: FontWeight.w600),
            ),
            PopupMenuButton<_KayitIslem>(
              tooltip: 'İşlemler',
              onSelected: (islem) {
                switch (islem) {
                  case _KayitIslem.duzenle:
                    showTransactionEditor(context, mevcut: kayit);
                  case _KayitIslem.kopyala:
                    showTransactionEditor(context, kopya: kayit);
                  case _KayitIslem.sil:
                    _sil(context);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: _KayitIslem.duzenle,
                  child: Text('Düzenle'),
                ),
                PopupMenuItem(
                  value: _KayitIslem.kopyala,
                  child: Text('Kopyala'),
                ),
                PopupMenuItem(value: _KayitIslem.sil, child: Text('Sil')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sil(BuildContext context) async {
    final onay = await onayIste(
      context,
      baslik: 'Kayıt silinsin mi?',
      mesaj: '${formatMoney(kayit.amountKurus)} tutarındaki kayıt',
    );
    if (!onay || !context.mounted) return;
    final appState = context.read<AppState>();
    await appState.kayitSil(kayit);
    if (!context.mounted) return;
    _geriAlGoster(ScaffoldMessenger.of(context), appState, 'Kayıt silindi');
  }

  void _geriAlGoster(
    ScaffoldMessengerState messenger,
    AppState appState,
    String metin,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(metin),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => appState.sonSilineniGeriAl(),
          ),
        ),
      );
  }
}

enum _KayitIslem { duzenle, kopyala, sil }

Future<void> _farkliAySec(BuildContext context, AppState state) async {
  final secim = await aySeciciGoster(
    context,
    year: state.gorunenAy.year,
    month: state.gorunenAy.month,
  );
  if (secim == null) return;
  state.ayaGit(secim.year, secim.month);
}
