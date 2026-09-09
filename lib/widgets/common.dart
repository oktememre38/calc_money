import 'package:flutter/material.dart';

import '../utils/dates.dart';

/// Boş durum göstergesi (kayıt yokken).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final Widget? alt;

  const EmptyState({super.key, required this.icon, required this.mesaj, this.alt});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            if (alt != null) ...[const SizedBox(height: 16), alt!],
          ],
        ),
      ),
    );
  }
}

/// Silme gibi işlemler için onay penceresi. Onaylanırsa true döner.
Future<bool> onayIste(
  BuildContext context, {
  required String baslik,
  required String mesaj,
  String onayMetni = 'Sil',
}) async {
  final tema = Theme.of(context);
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(baslik),
      content: Text(mesaj),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tema.colorScheme.error,
            foregroundColor: tema.colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(onayMetni),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}

/// Ay seçici: başlık + önceki/sonraki okları.
class MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onOnceki;
  final VoidCallback onSonraki;
  final VoidCallback? onBuguneDon;

  const MonthSelector({
    super.key,
    required this.year,
    required this.month,
    required this.onOnceki,
    required this.onSonraki,
    this.onBuguneDon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onOnceki,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Önceki ay',
        ),
        Expanded(
          child: InkWell(
            onTap: onBuguneDon,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${monthName(month)} $year',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onSonraki,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Sonraki ay',
        ),
      ],
    );
  }
}

/// Yıl seçici: başlık + önceki/sonraki okları.
class YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onOnceki;
  final VoidCallback onSonraki;
  final VoidCallback? onBuguneDon;

  const YearSelector({
    super.key,
    required this.year,
    required this.onOnceki,
    required this.onSonraki,
    this.onBuguneDon,
  });

  @override
  Widget build(BuildContext context) {
    final bugunkuYil = DateTime.now().year;
    return Row(
      children: [
        IconButton(
          onPressed: onOnceki,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Önceki yıl',
        ),
        Expanded(
          child: InkWell(
            onTap: onBuguneDon,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$year',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: bugunkuYil == year ? null : onSonraki,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Sonraki yıl',
        ),
      ],
    );
  }
}
