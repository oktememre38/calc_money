import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/record_type.dart';
import '../models/transaction_record.dart';
import '../state/app_state.dart';
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
      appBar: AppBar(title: const Text('Kayıtlar')),
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
    final children = <Widget>[];
    String? oncekiGun;

    for (final kayit in state.ayKayitlari) {
      if (kayit.date != oncekiGun) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              dayLabelFromKey(kayit.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
        oncekiGun = kayit.date;
      }
      children.add(_KayitSatiri(state: state, kayit: kayit));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: children,
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
      onDismissed: (_) => state.kayitSil(kayit),
      child: ListTile(
        onTap: () => showTransactionEditor(context, mevcut: kayit),
        leading: CategoryAvatar(category: kategori),
        title: Text(
          kayit.note.isNotEmpty ? kayit.note : kategori.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(kategori.name),
        trailing: Text(
          '$isaret${formatMoney(kayit.amountKurus)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: renk, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
