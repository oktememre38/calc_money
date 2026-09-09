import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/record_type.dart';
import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/money.dart';
import 'category_picker.dart';

/// Tekrarlayan sabit kayıt (gider veya gelir) ekleme/düzenleme alt sayfası.
Future<void> showRecurringEditor(
  BuildContext context, {
  RecurringExpense? mevcut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: MediaQuery.viewInsetsOf(ctx),
      child: RecurringEditor(mevcut: mevcut),
    ),
  );
}

class RecurringEditor extends StatefulWidget {
  final RecurringExpense? mevcut;

  const RecurringEditor({super.key, this.mevcut});

  @override
  State<RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<RecurringEditor> {
  late final TextEditingController _ad;
  late final TextEditingController _tutar;
  late final TextEditingController _toplamAy;
  late RecordType _tip;
  late int _gun;
  int? _kategoriId;
  String? _tutarHatasi;
  String? _toplamAyHatasi;

  bool get _duzenleme => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    _ad = TextEditingController(text: m?.name ?? '');
    _tip = m?.type ?? RecordType.gider;
    _tutar = TextEditingController(
      text: m != null ? kurusToGirdi(m.amountKurus) : '',
    );
    _toplamAy = TextEditingController(
      text: (m != null && m.toplamAy > 0) ? '${m.toplamAy}' : '',
    );
    _gun = m?.dayOfMonth ?? 1;
    _kategoriId = m?.categoryId;
  }

  @override
  void dispose() {
    _ad.dispose();
    _tutar.dispose();
    _toplamAy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final secenekler = _tip == RecordType.gelir
        ? state.gelirKategorileri
        : state.giderKategorileri;
    final secili = _seciliKategori(secenekler);
    final toplamAy = int.tryParse(_toplamAy.text) ?? 0;

    return SingleChildScrollView(
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
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _duzenleme ? 'Sabit Kaydı Düzenle' : 'Yeni Sabit Kayıt',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Her ay tekrarlayan gider (kira, abonelik, taksit) veya gelir '
            '(kira getirisi, maaş) ekleyebilirsin. Taksit gibi sonlu bir kayıt '
            'için "Toplam ay" girebilirsin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<RecordType>(
            segments: const [
              ButtonSegment(
                value: RecordType.gelir,
                label: Text('Gelir'),
                icon: Icon(Icons.north_east),
              ),
              ButtonSegment(
                value: RecordType.gider,
                label: Text('Gider'),
                icon: Icon(Icons.south_west),
              ),
            ],
            selected: {_tip},
            onSelectionChanged: (secim) {
              setState(() {
                _tip = secim.first;
                _kategoriId = null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ad,
            decoration: const InputDecoration(
              labelText: 'Ad (örn. Netflix, Kira, Telefon taksiti)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tutar,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Aylık tutar (₺)',
              prefixText: '₺ ',
              errorText: _tutarHatasi,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_tutarHatasi != null) setState(() => _tutarHatasi = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _toplamAy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Toplam ay (boş = sürekli)',
              hintText: 'Taksit için 5 gibi bir sayı',
              errorText: _toplamAyHatasi,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_toplamAyHatasi != null) {
                setState(() => _toplamAyHatasi = null);
              }
            },
          ),
          if (toplamAy > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$toplamAy aylık kayıt oluşturulunca bu sabit kayıt otomatik silinir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _gun,
            decoration: const InputDecoration(
              labelText: 'Kayıt günü',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var gun = 1; gun <= 28; gun++)
                DropdownMenuItem(value: gun, child: Text('Her ayın $gun. günü')),
            ],
            onChanged: (deger) => setState(() => _gun = deger ?? 1),
          ),
          const SizedBox(height: 16),
          Text('Kategori', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          CategoryPicker(
            key: ValueKey('kategori-${_tip.toDb}'),
            kategoriler: secenekler,
            seciliId: secili?.id,
            onSec: (c) => setState(() => _kategoriId = c.id),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _kaydet,
            icon: const Icon(Icons.check),
            label: const Text('Kaydet'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Category? _seciliKategori(List<Category> secenekler) {
    for (final c in secenekler) {
      if (c.id == _kategoriId) return c;
    }
    return ilkSecilebilirKategori(secenekler);
  }

  Future<void> _kaydet() async {
    final kurus = parseToKurus(_tutar.text);
    if (kurus == null || kurus <= 0) {
      setState(() => _tutarHatasi = 'Geçerli bir tutar girin.');
      return;
    }
    final hamToplamAy = _toplamAy.text.trim();
    final toplamAy = hamToplamAy.isEmpty
        ? 0
        : (int.tryParse(hamToplamAy) ?? -1);
    if (toplamAy < 0) {
      setState(() => _toplamAyHatasi = 'Geçerli bir sayı girin (boş bırakabilirsin).');
      return;
    }
    if (_ad.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir ad girin.')),
      );
      return;
    }
    final state = context.read<AppState>();
    final secenekler = _tip == RecordType.gelir
        ? state.gelirKategorileri
        : state.giderKategorileri;
    final secili = _seciliKategori(secenekler);
    if (secili == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin.')),
      );
      return;
    }
    final mevcut = widget.mevcut;
    if (mevcut != null) {
      await state.tekrarlayanGuncelle(
        mevcut,
        name: _ad.text.trim(),
        type: _tip,
        amountKurus: kurus,
        dayOfMonth: _gun,
        categoryId: secili.id,
        toplamAy: toplamAy,
      );
    } else {
      await state.tekrarlayanEkle(
        name: _ad.text.trim(),
        type: _tip,
        amountKurus: kurus,
        dayOfMonth: _gun,
        categoryId: secili.id,
        toplamAy: toplamAy,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
