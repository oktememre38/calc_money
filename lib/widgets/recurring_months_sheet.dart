import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import 'category_visual.dart';

/// Sabit bir kaydın hangi aylara ekleneceği / hangi aylardan kaldırılacağı
/// penceresi.
///
/// Bu aydan başlayarak önümüzdeki 12 ay listelenir. Daha önce aynı sabit
/// kayıtla (tip+kategori+tutar+not) eklenmiş aylar "kayıtlı" görünür; tikini
/// kaldırınca o aya ait kayıt geri alınır (silinir). Boş aylar seçilip eklenir.
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
  final Set<String> _eklenecek = <String>{};
  final Set<String> _silinecek = <String>{};
  Map<String, bool> _varDurum = <String, bool>{};
  bool _hazir = false;

  RecurringExpense get _gider => widget.gider;

  @override
  void initState() {
    super.initState();
    final bugun = DateTime.now();
    _aylar = List.generate(12, (i) => DateTime(bugun.year, bugun.month + i));
    _yukle();
  }

  Future<void> _yukle() async {
    final durum = await context
        .read<AppState>()
        .tekrarlayanAyKayitlari(_gider, _aylar);
    if (!mounted) return;
    setState(() {
      _varDurum = durum;
      _hazir = true;
    });
  }

  String _anahtar(DateTime ay) => '${ay.year}-${ay.month}';

  bool _kayitli(DateTime ay) => _varDurum[_anahtar(ay)] ?? false;

  List<DateTime> get _eklenecekAylar =>
      _aylar.where((ay) => _eklenecek.contains(_anahtar(ay))).toList();

  List<DateTime> get _silinecekAylar => _aylar
      .where((ay) => _kayitli(ay) && _silinecek.contains(_anahtar(ay)))
      .toList();

  void _bosAylariSec() {
    setState(() {
      _silinecek.clear();
      _eklenecek.clear();
      for (final ay in _aylar) {
        if (!_kayitli(ay)) _eklenecek.add(_anahtar(ay));
      }
    });
  }

  void _kayitlilariKaldir() {
    setState(() {
      _eklenecek.clear();
      _silinecek.clear();
      for (final ay in _aylar) {
        if (_kayitli(ay)) _silinecek.add(_anahtar(ay));
      }
    });
  }

  void _temizle() {
    setState(() {
      _eklenecek.clear();
      _silinecek.clear();
    });
  }

  Future<void> _kaydet() async {
    final state = context.read<AppState>();
    final eklenecek = _eklenecekAylar;
    final silinecek = _silinecekAylar;

    var eklendi = 0;
    var atlandi = 0;
    var silindi = 0;

    // Önce kaldırılacaklar silinir, sonra eklenecekler eklenir.
    if (silinecek.isNotEmpty) {
      silindi = await state.tekrarlayanAyKayitlariniKaldir(_gider, silinecek);
    }
    if (eklenecek.isNotEmpty) {
      final sonuc = await state.tekrarlayanTopluEkle(_gider, eklenecek);
      eklendi = sonuc.eklenen;
      atlandi = sonuc.atlanan;
    }

    if (!mounted) return;
    final parcalar = <String>[];
    if (silindi > 0) parcalar.add('$silindi ay kaldırıldı');
    if (eklendi > 0) parcalar.add('$eklendi ay eklendi');
    if (atlandi > 0) parcalar.add('$atlandi ay zaten kayıtlıydı');
    final mesaj = parcalar.isEmpty ? 'Değişiklik yapılmadı.' : parcalar.join(', ');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mesaj)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final kategori = state.kategoriGetir(_gider.categoryId);
    final tema = Theme.of(context);
    final kayitliSayisi = _aylar.where((ay) => _kayitli(ay)).length;
    final degisiklikSayisi = _eklenecek.length + _silinecek.length;

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
              'Kayıtlı ayların tikini kaldırarak o aya ait kaydı silebilir, '
              'boş ayları seçerek ekleyebilirsin.',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            if (_hazir && kayitliSayisi > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$kayitliSayisi ay zaten kayıtlı.',
                  style: tema.textTheme.labelSmall
                      ?.copyWith(color: tema.colorScheme.primary),
                ),
              ),
            if (_hazir)
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: _bosAylariSec,
                    child: const Text('Boş ayları seç'),
                  ),
                  TextButton(
                    onPressed: _kayitlilariKaldir,
                    child: const Text('Kayıtlıları kaldır'),
                  ),
                  TextButton(
                    onPressed: _temizle,
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            if (!_hazir)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (var i = 0; i < _aylar.length; i++)
                _AySatiri(
                  ay: _aylar[i],
                  kayitli: _kayitli(_aylar[i]),
                  eklenecek: _eklenecek.contains(_anahtar(_aylar[i])),
                  silinecek: _silinecek.contains(_anahtar(_aylar[i])),
                  ilk: i == 0,
                  onDegis: (secili) {
                    final key = _anahtar(_aylar[i]);
                    setState(() {
                      if (_kayitli(_aylar[i])) {
                        // Kayıtlı ay: tik kaldırılınca silinecek.
                        if (secili) {
                          _silinecek.remove(key);
                        } else {
                          _silinecek.add(key);
                        }
                      } else if (secili) {
                        _eklenecek.add(key);
                      } else {
                        _eklenecek.remove(key);
                      }
                    });
                  },
                ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (!_hazir || degisiklikSayisi == 0) ? null : _kaydet,
              icon: const Icon(Icons.check),
              label: Text(
                !_hazir
                    ? 'Kontrol ediliyor...'
                    : degisiklikSayisi == 0
                        ? 'Değişiklik yok'
                        : 'Uygula ($degisiklikSayisi)',
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

class _AySatiri extends StatelessWidget {
  final DateTime ay;
  final bool kayitli;
  final bool eklenecek;
  final bool silinecek;
  final bool ilk;
  final ValueChanged<bool> onDegis;

  const _AySatiri({
    required this.ay,
    required this.kayitli,
    required this.eklenecek,
    required this.silinecek,
    required this.ilk,
    required this.onDegis,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Kaydedince bu ay "kayıtlı" mı olacak?
    final value = kayitli ? !silinecek : eklenecek;

    String altYazi;
    if (kayitli && silinecek) {
      altYazi = 'kaydı silinecek';
    } else if (kayitli) {
      altYazi = 'kayıtlı • tik kaldırınca silinir';
    } else if (eklenecek) {
      altYazi = 'eklenecek';
    } else {
      altYazi = ilk ? 'bu ay' : '';
    }

    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        monthYearLabel(ay.year, ay.month),
        style: tema.textTheme.bodyMedium?.copyWith(
          fontWeight: (eklenecek || silinecek)
              ? FontWeight.w600
              : FontWeight.normal,
          color: silinecek ? tema.colorScheme.error : null,
        ),
      ),
      subtitle: Text(altYazi),
      value: value,
      onChanged: (s) => onDegis(s ?? false),
    );
  }
}
