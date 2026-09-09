import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'category_analysis.dart';
import 'dagilim.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/summary_bar.dart';

/// Genel bakış: seçili ay özeti, ayın gelir/gider dağılımı, sabit kayıtlar.
class OverviewPage extends StatelessWidget {
  final VoidCallback onSabitleriGoster;

  const OverviewPage({
    super.key,
    required this.onSabitleriGoster,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Bakış'),
        actions: [
          IconButton(
            onPressed: () {
              final appState = context.read<AppState>();
              appState.temaDegistir(!appState.karanlikTema);
            },
            icon: Icon(
              state.karanlikTema ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: state.karanlikTema ? 'Gündüz teması' : 'Karanlık tema',
          ),
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AylikOzetBar(
              ozet: state.ayOzet,
              baslik:
                  '${monthName(state.gorunenAy.month)} ${state.gorunenAy.year} özeti',
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DagilimKarti(
              key: ValueKey(
                'dagilim-${state.gorunenAy.year}-${state.gorunenAy.month}',
              ),
              year: state.gorunenAy.year,
              month: state.gorunenAy.month,
            ),
          ),
          const SizedBox(height: 16),
          _SabitlerKarti(state: state, onSabitleriGoster: onSabitleriGoster),
        ],
      ),
    );
  }
}

class _SabitlerKarti extends StatelessWidget {
  final AppState state;
  final VoidCallback onSabitleriGoster;

  const _SabitlerKarti({
    required this.state,
    required this.onSabitleriGoster,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Aylık sabit kayıtlar',
                        style: tema.textTheme.titleSmall),
                  ),
                  IconButton(
                    onPressed: onSabitleriGoster,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Sabit kayıtları yönet',
                  ),
                ],
              ),
              const Divider(height: 8),
              _SabitOzetSatir(
                label: 'Sabit gelir',
                deger: formatMoney(state.aktifSabitGelirToplam),
                renk: gelirRengi(context),
              ),
              const SizedBox(height: 8),
              _SabitOzetSatir(
                label: 'Sabit gider',
                deger: formatMoney(state.aktifSabitGiderToplam),
                renk: giderRengi(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SabitOzetSatir extends StatelessWidget {
  final String label;
  final String deger;
  final Color renk;

  const _SabitOzetSatir({
    required this.label,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: tema.textTheme.bodyMedium)),
        Text(
          deger,
          style: tema.textTheme.titleSmall
              ?.copyWith(color: renk, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

Future<void> _farkliAySec(BuildContext context, AppState state) async {
  final secim = await aySeciciGoster(
    context,
    year: state.gorunenAy.year,
    month: state.gorunenAy.month,
  );
  if (secim == null) return;
  state.ayaGit(secim.year, secim.month);
}
