import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aggregate.dart';
import '../models/monthly_summary.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/summary_bar.dart';

/// Yıllık özet: 12 aylık döküm ve yıl toplamı.
class AnnualPage extends StatelessWidget {
  final void Function(int yil, int ay) onAyaSec;

  const AnnualPage({super.key, required this.onAyaSec});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Yıllık Özet')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          YearSelector(
            year: state.gorunenYil,
            onOnceki: state.oncekiYil,
            onSonraki: state.sonrakiYil,
            onBuguneDon: state.buAyaDon,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AylikOzetBar(
              ozet: state.yilAggregate,
              baslik: '${state.gorunenYil} yılı toplamı',
            ),
          ),
          const SizedBox(height: 16),
          _AylarTablosu(
            yil: state.gorunenYil,
            ozetler: state.yilOzet,
            onAySec: (ay) {
              state.ayaGit(state.gorunenYil, ay);
              onAyaSec(state.gorunenYil, ay);
            },
          ),
        ],
      ),
    );
  }
}

class _AylarTablosu extends StatelessWidget {
  final int yil;
  final List<MonthlySummary> ozetler;
  final void Function(int ay) onAySec;

  const _AylarTablosu({
    required this.yil,
    required this.ozetler,
    required this.onAySec,
  });

  @override
  Widget build(BuildContext context) {
    final buAy = DateTime.now().year == yil ? DateTime.now().month : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              const _BaslikSatir(),
              const Divider(height: 1),
              for (final ozet in ozetler)
                _AySatir(
                  ay: ozet.month,
                  ozet: ozet.aggregate,
                  vurgulu: ozet.month == buAy,
                  onTap: () => onAySec(ozet.month),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BaslikSatir extends StatelessWidget {
  const _BaslikSatir();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Ay')),
          Expanded(
            flex: 3,
            child: Text('Gelir', textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('Gider', textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('Denge', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _AySatir extends StatelessWidget {
  final int ay;
  final Aggregate ozet;
  final bool vurgulu;
  final VoidCallback onTap;

  const _AySatir({
    required this.ay,
    required this.ozet,
    required this.vurgulu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final denge = ozet.balance;
    final dengeRengi = denge == 0
        ? tema.colorScheme.onSurfaceVariant
        : (denge > 0 ? gelirRengi(context) : giderRengi(context));

    return Material(
      color: vurgulu ? tema.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  monthName(ay),
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: vurgulu ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formatMoney(ozet.income),
                  textAlign: TextAlign.right,
                  style: tema.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formatMoney(ozet.expense),
                  textAlign: TextAlign.right,
                  style: tema.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  denge >= 0 ? '+${formatMoney(denge)}' : formatMoney(denge),
                  textAlign: TextAlign.right,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: dengeRengi,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
