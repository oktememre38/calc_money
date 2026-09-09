import 'package:flutter/material.dart';

import '../models/aggregate.dart';
import '../utils/money.dart';
import 'category_visual.dart';

/// Bir dönemin gelir / gider / denge özet satırı.
class AylikOzetBar extends StatelessWidget {
  final Aggregate ozet;
  final String baslik;

  const AylikOzetBar({super.key, required this.ozet, this.baslik = ''});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final denge = ozet.balance;
    final dengeRengi = denge == 0
        ? tema.colorScheme.onSurfaceVariant
        : (denge > 0 ? gelirRengi(context) : giderRengi(context));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            if (baslik.isNotEmpty) ...[
              Text(baslik, style: tema.textTheme.labelLarge),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _OzetKolon(
                    label: 'Gelir',
                    deger: formatMoney(ozet.income),
                    renk: gelirRengi(context),
                  ),
                ),
                Expanded(
                  child: _OzetKolon(
                    label: 'Gider',
                    deger: formatMoney(ozet.expense),
                    renk: giderRengi(context),
                  ),
                ),
                Expanded(
                  child: _OzetKolon(
                    label: 'Denge',
                    deger: _isaretli(denge),
                    renk: dengeRengi,
                    vurgulu: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _isaretli(int kurus) {
    if (kurus == 0) return formatMoney(0);
    return kurus > 0 ? '+${formatMoney(kurus)}' : formatMoney(kurus);
  }
}

class _OzetKolon extends StatelessWidget {
  final String label;
  final String deger;
  final Color renk;
  final bool vurgulu;

  const _OzetKolon({
    required this.label,
    required this.deger,
    required this.renk,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: tema.textTheme.bodySmall
              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            deger,
            style: (vurgulu
                    ? tema.textTheme.titleLarge
                    : tema.textTheme.titleMedium)
                ?.copyWith(
              color: renk,
              fontWeight: vurgulu ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
