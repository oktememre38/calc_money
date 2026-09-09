import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/record_type.dart';
import '../models/transaction_record.dart';
import '../state/app_state.dart';
import 'category_analysis.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/summary_bar.dart';
import '../widgets/transaction_editor.dart';

/// Kayıtlar: seçili ayın gelir/gider listesi ve özeti.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AylikOzetBar(ozet: state.ayOzet),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.ayKayitlari.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long,
                    mesaj:
                        'Bu ay için henüz kayıt yok.\nSağ alttaki + butonu ile gelir veya gider ekleyebilirsin.',
                  )
                : _KayitListesi(state: state),
          ),
        ],
      ),
    );
  }
}

class _KayitListesi extends StatelessWidget {
  final AppState state;

  const _KayitListesi({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final kayit in state.ayKayitlari)
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
        mesaj: '${kategori.name}: ${formatMoney(kayit.amountKurus)}',
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
