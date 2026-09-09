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

/// Genel bakış: seçili ay özeti, sabit giderler, son kayıtlar.
class OverviewPage extends StatelessWidget {
  final VoidCallback onKayitlariGoster;
  final VoidCallback onSabitleriGoster;

  const OverviewPage({
    super.key,
    required this.onKayitlariGoster,
    required this.onSabitleriGoster,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Genel Bakış')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          MonthSelector(
            year: state.gorunenAy.year,
            month: state.gorunenAy.month,
            onOnceki: state.oncekiAy,
            onSonraki: state.sonrakiAy,
            onBuguneDon: state.buAyaDon,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AylikOzetBar(
              ozet: state.ayOzet,
              baslik:
                  '${monthName(state.gorunenAy.month)} ${state.gorunenAy.year} özeti',
            ),
          ),
          const SizedBox(height: 16),
          _SabitGiderlerKarti(state: state, onSabitleriGoster: onSabitleriGoster),
          const SizedBox(height: 16),
          _SonKayitlarKarti(state: state, onKayitlariGoster: onKayitlariGoster),
        ],
      ),
    );
  }
}

class _SabitGiderlerKarti extends StatelessWidget {
  final AppState state;
  final VoidCallback onSabitleriGoster;

  const _SabitGiderlerKarti({
    required this.state,
    required this.onSabitleriGoster,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final aktifler = state.tekrarlayanListesi.where((k) => k.active).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    tema.colorScheme.primaryContainer.withValues(alpha: 0.6),
                child: Icon(Icons.notifications_active_outlined,
                    color: tema.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aylık sabit giderler',
                        style: tema.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      aktifler.isEmpty
                          ? 'Henüz tanımlanmamış.'
                          : '${aktifler.length} adet • ${formatMoney(state.aktifTekrarlayanToplam)}',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSabitleriGoster,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Sabit giderleri yönet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SonKayitlarKarti extends StatelessWidget {
  final AppState state;
  final VoidCallback onKayitlariGoster;

  const _SonKayitlarKarti({
    required this.state,
    required this.onKayitlariGoster,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sonKayitlar = state.ayKayitlari.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Son kayıtlar', style: tema.textTheme.titleSmall),
                  ),
                  TextButton(
                    onPressed: onKayitlariGoster,
                    child: const Text('Tümünü gör'),
                  ),
                ],
              ),
              if (sonKayitlar.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Bu ay için kayıt yok.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final kayit in sonKayitlar) _KucukKayit(kayit: kayit),
            ],
          ),
        ),
      ),
    );
  }
}

class _KucukKayit extends StatelessWidget {
  final TransactionRecord kayit;

  const _KucukKayit({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final kategori = state.kategoriGetir(kayit.categoryId);
    final renk = tipRengi(context, kayit.type);
    final isaret = kayit.type == RecordType.gelir ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CategoryAvatar(category: kategori, boyut: 36),
      title: Text(
        kayit.note.isNotEmpty ? kayit.note : kategori.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$isaret${formatMoney(kayit.amountKurus)}',
        style: TextStyle(color: renk, fontWeight: FontWeight.w600),
      ),
    );
  }
}
