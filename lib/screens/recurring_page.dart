import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/recurring_editor.dart';
import '../widgets/recurring_months_sheet.dart';
import '../widgets/transaction_editor.dart';

/// Sabit giderler: tekrarlayan abonelik/fatura yönetimi + bildirimler.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aktifler = state.tekrarlayanListesi.where((k) => k.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sabit Giderler')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRecurringEditor(context),
        tooltip: 'Sabit gider ekle',
        child: const Icon(Icons.add),
      ),
      body: state.tekrarlayanListesi.isEmpty
          ? EmptyState(
              icon: Icons.event_repeat,
              mesaj:
                  'Henüz sabit gider yok.\nKira, su, doğalgaz veya Netflix gibi her ay tekrarlayan '
                  'giderlerini ekle, her ay hatırlatalım.',
              alt: FilledButton.tonalIcon(
                onPressed: () => showRecurringEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Sabit gider ekle'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                if (aktifler.isNotEmpty) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calculate_outlined),
                      title: const Text('Aylık tahmini sabit gider'),
                      subtitle: Text('${aktifler.length} adet aktif'),
                      trailing: Text(
                        formatMoney(state.aktifTekrarlayanToplam),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final kayit in state.tekrarlayanListesi)
                  _SabitGiderSatiri(kayit: kayit),
              ],
            ),
    );
  }
}

enum _Islem { kayitEkle, duzenle, aktiflik, sil }

class _SabitGiderSatiri extends StatelessWidget {
  final RecurringExpense kayit;

  const _SabitGiderSatiri({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final kategori = state.kategoriGetir(kayit.categoryId);
    final tema = Theme.of(context);

    final bildirimMetni = kayit.notify ? 'hatırlatma açık' : 'hatırlatma kapalı';
    final altYazi =
        'Her ayın ${kayit.dayOfMonth}. günü • ${kategori.name} • $bildirimMetni';

    return Dismissible(
      key: ValueKey('tekrarlayan-${kayit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: giderRengi(context),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => onayIste(
        context,
        baslik: 'Sabit gider silinsin mi?',
        mesaj: '${kayit.name}: ${formatMoney(kayit.amountKurus)}',
      ),
      onDismissed: (_) => state.tekrarlayanSil(kayit),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () => showRecurringMonthsSheet(context, kayit),
          leading: Stack(
            children: [
              CategoryAvatar(category: kategori),
              if (!kayit.active)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            kayit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(altYazi, maxLines: 1, overflow: TextOverflow.ellipsis),
          isThreeLine: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kayit.notify)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.notifications_active,
                      size: 18, color: Colors.amber),
                ),
              Text(
                formatMoney(kayit.amountKurus),
                style: tema.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              PopupMenuButton<_Islem>(
                tooltip: 'İşlemler',
                onSelected: (islem) => _islemYap(context, islem),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: _Islem.kayitEkle,
                    child: Text('Bu ay için kayıt ekle'),
                  ),
                  const PopupMenuItem(
                    value: _Islem.duzenle,
                    child: Text('Düzenle'),
                  ),
                  PopupMenuItem(
                    value: _Islem.aktiflik,
                    child: Text(kayit.active ? 'Pasif yap' : 'Aktif yap'),
                  ),
                  const PopupMenuItem(value: _Islem.sil, child: Text('Sil')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _islemYap(BuildContext context, _Islem islem) {
    final state = context.read<AppState>();
    switch (islem) {
      case _Islem.kayitEkle:
        showTransactionEditor(context, kaynak: kayit);
      case _Islem.duzenle:
        showRecurringEditor(context, mevcut: kayit);
      case _Islem.aktiflik:
        state.tekrarlayanAktiflikDegistir(kayit, !kayit.active);
      case _Islem.sil:
        _sil(context);
    }
  }

  Future<void> _sil(BuildContext context) async {
    final onay = await onayIste(
      context,
      baslik: 'Sabit gider silinsin mi?',
      mesaj: '${kayit.name}: ${formatMoney(kayit.amountKurus)}',
    );
    if (!onay || !context.mounted) return;
    final state = context.read<AppState>();
    await state.tekrarlayanSil(kayit);
  }
}
