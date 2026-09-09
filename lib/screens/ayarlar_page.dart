import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/dates.dart';

/// Ayarlar: hesap kesim günü vb. uygulama geneli tercihler.
class AyarlarPage extends StatelessWidget {
  const AyarlarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tema = Theme.of(context);
    final kesim = state.hesapKesimGunu;
    final bugun = DateTime.now();
    final kayma = (kesim > 0 && bugun.day > kesim) ? 1 : 0;
    final donemAyNo = ((bugun.month - 1 + kayma) % 12) + 1;
    final donemYil = bugun.year + ((bugun.month + kayma) > 12 ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
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
                      const Icon(Icons.event_repeat),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hesap kesim günü',
                          style: tema.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kredi kartı ekstrenizin kesildiği günü seçin. Kesim gününe '
                    'kadar (dahil) eklenen gelir/giderler o ayın dönemine, '
                    'kesimden SONRAKİ günler ise bir sonraki ayın dönemine işlenir.\n\n'
                    'Örnek: kesim günü 10 iken 20\'sinde girdiğiniz bir gider '
                    'gelecek ayın döneminde görünür. "Kapalı" seçiliyken dönem '
                    'takvim ayıyla aynıdır.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Kapalı'),
                        avatar: const Icon(Icons.block, size: 16),
                        selected: kesim == 0,
                        onSelected: (_) => _sec(context, 0),
                      ),
                      for (var gun = 1; gun <= 28; gun++)
                        ChoiceChip(
                          label: Text('$gun'),
                          selected: kesim == gun,
                          onSelected: (_) => _sec(context, gun),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        size: 20,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bugün ${bugun.day} ${monthName(bugun.month)} olduğundan '
                          '${kesim == 0 ? 'takvim ayına' : 'kesim gününe'} göre '
                          '${monthName(donemAyNo)} $donemYil dönemine işlenir.',
                          style: tema.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kesim gününü değiştirirseniz mevcut tüm kayıtlar yeni dönem '
            'kuralına göre yeniden gruplanır.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _sec(BuildContext context, int gun) {
    context.read<AppState>().kesimGunuAyarla(gun);
  }
}
