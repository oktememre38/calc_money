import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import 'category_visual.dart';

/// Sabit bir giderin hangi aylara kayıt olarak ekleneceğini seçme penceresi.
///
/// Bu aydan başlayarak önümüzdeki 12 ay listelenir; işaretlenen her ay için
/// sabit giderin gününde otomatik bir gider kaydı oluşturulur.
Future<void> showRecurringMonthsSheet(
  BuildContext context,
  RecurringExpense gider,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => RecurringMonthsSheet(gider: gider),
  );
}

class RecurringMonthsSheet extends StatefulWidget {
  final RecurringExpense gider;

  const RecurringMonthsSheet({super.key, required this.gider});

  @override
  State<RecurringMonthsSheet> createState() => _RecurringMonthsSheetState();
}

class _RecurringMonthsSheetState extends State<RecurringMonthsSheet> {
  late final List<DateTime> _aylar;
  final Set<String> _secili = <String>{};

  RecurringExpense get _gider => widget.gider;

  @override
  void initState() {
    super.initState();
    final bugun = DateTime.now();
    _aylar =
        List.generate(12, (i) => DateTime(bugun.year, bugun.month + i));
  }

  String _anahtar(DateTime ay) => '${ay.year}-${ay.month}';

  List<DateTime> get _seciliAylar =>
      _aylar.where((ay) => _secili.contains(_anahtar(ay))).toList();

  void _hepsiniSec() {
    setState(() {
      _secili.clear();
      for (final ay in _aylar) {
        _secili.add(_anahtar(ay));
      }
    });
  }

  void _temizle() {
    setState(_secili.clear);
  }

  Future<void> _kaydet() async {
    final state = context.read<AppState>();
    final secili = _seciliAylar;
    if (secili.isEmpty) return;

    final sonuc = await state.tekrarlayanTopluEkle(_gider, secili);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(
        sonuc.atlanan > 0
            ? '${sonuc.eklenen} aya eklendi, ${sonuc.atlanan} ay zaten kayıtlıydı.'
            : '${sonuc.eklenen} aya eklendi.',
      ),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final kategori = state.kategoriGetir(_gider.categoryId);
    final tema = Theme.of(context);
    final secimSayisi = _secili.length;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tema.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CategoryAvatar(category: kategori),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gider.name,
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Her ayın ${_gider.dayOfMonth}. günü • ${kategori.name} • ${formatMoney(_gider.amountKurus)}',
                        style: tema.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Eklemek istediğin ayları işaretle. Her ay için bu giderin gününde '
              'bir gider kaydı oluşturulur; o ay aynı kayıt zaten varsa atlanır.',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _hepsiniSec,
                  child: const Text('Tümünü seç'),
                ),
                TextButton(
                  onPressed: _temizle,
                  child: const Text('Temizle'),
                ),
              ],
            ),
            for (var i = 0; i < _aylar.length; i++)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  monthYearLabel(_aylar[i].year, _aylar[i].month),
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: _secili.contains(_anahtar(_aylar[i]))
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: i == 0 ? const Text('bu ay') : null,
                value: _secili.contains(_anahtar(_aylar[i])),
                onChanged: (deger) {
                  setState(() {
                    final key = _anahtar(_aylar[i]);
                    if (deger == true) {
                      _secili.add(key);
                    } else {
                      _secili.remove(key);
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: secimSayisi == 0 ? null : _kaydet,
              icon: const Icon(Icons.check),
              label: Text(
                secimSayisi == 0
                    ? 'Ayları seç'
                    : 'Seçilen aylara ekle ($secimSayisi)',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
