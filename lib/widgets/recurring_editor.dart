import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/money.dart';
import 'category_visual.dart';

/// Tekrarlayan sabit gider ekleme/düzenleme alt sayfası (bottom sheet).
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
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx)),
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
  late int _gun;
  int? _kategoriId;
  bool _bildirim = true;
  String? _tutarHatasi;

  bool get _duzenleme => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    _ad = TextEditingController(text: m?.name ?? '');
    _tutar = TextEditingController(
      text: m != null ? kurusToGirdi(m.amountKurus) : '',
    );
    _gun = m?.dayOfMonth ?? 1;
    _kategoriId = m?.categoryId;
    _bildirim = m?.notify ?? true;
  }

  @override
  void dispose() {
    _ad.dispose();
    _tutar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final secenekler = state.giderKategorileri;
    final secili = _seciliKategori(secenekler);

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
            _duzenleme ? 'Sabit Gideri Düzenle' : 'Yeni Sabit Gider',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Abonelik, kira, fatura gibi her ay tekrarlayan giderler.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ad,
            decoration: const InputDecoration(
              labelText: 'Ad (örn. Netflix, Kira, Doğalgaz)',
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
          DropdownButtonFormField<int>(
            initialValue: _gun,
            decoration: const InputDecoration(
              labelText: 'Hatırlatma günü',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kategori in secenekler)
                ChoiceChip(
                  avatar: Icon(
                    kategoriIkon(kategori),
                    size: 18,
                    color: kategoriRengi(kategori),
                  ),
                  label: Text(kategori.name),
                  selected: kategori.id == secili?.id,
                  onSelected: (_) => setState(() => _kategoriId = kategori.id),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aylık hatırlatma bildirimi'),
            subtitle: const Text('Seçilen günde saat 09:00\'da bildirim gönderilir.'),
            value: _bildirim,
            onChanged: (v) => setState(() => _bildirim = v),
          ),
          const SizedBox(height: 8),
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
    return secenekler.isNotEmpty ? secenekler.first : null;
  }

  Future<void> _kaydet() async {
    final kurus = parseToKurus(_tutar.text);
    if (kurus == null || kurus <= 0) {
      setState(() => _tutarHatasi = 'Geçerli bir tutar girin.');
      return;
    }
    if (_ad.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir ad girin.')),
      );
      return;
    }
    final state = context.read<AppState>();
    final secili = _seciliKategori(state.giderKategorileri);
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
        amountKurus: kurus,
        dayOfMonth: _gun,
        categoryId: secili.id,
        notify: _bildirim,
      );
    } else {
      await state.tekrarlayanEkle(
        name: _ad.text.trim(),
        amountKurus: kurus,
        dayOfMonth: _gun,
        categoryId: secili.id,
        notify: _bildirim,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
