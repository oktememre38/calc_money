import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/record_type.dart';
import '../models/recurring_expense.dart';
import '../models/transaction_record.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import 'category_visual.dart';

/// Gelir/gider kaydı ekleme veya düzenleme alt sayfası (bottom sheet).
///
/// [mevcut] verilirse düzenleme, verilmezse yeni kayıt açılır.
/// [kaynak] (tekrarlayan gider) verilirse alanlar buna göre ön doldurulur.
Future<void> showTransactionEditor(
  BuildContext context, {
  TransactionRecord? mevcut,
  RecurringExpense? kaynak,
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
      child: TransactionEditor(mevcut: mevcut, kaynak: kaynak),
    ),
  );
}

class TransactionEditor extends StatefulWidget {
  final TransactionRecord? mevcut;
  final RecurringExpense? kaynak;

  const TransactionEditor({super.key, this.mevcut, this.kaynak});

  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  late RecordType _tip;
  late final TextEditingController _tutar;
  late final TextEditingController _not;
  late DateTime _tarih;
  int? _kategoriId;
  String? _tutarHatasi;

  bool get _duzenleme => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    final k = widget.kaynak;
    _tip = m?.type ?? RecordType.gider;
    final ilkTutar = m?.amountKurus ?? k?.amountKurus ?? 0;
    _tutar = TextEditingController(
      text: ilkTutar > 0 ? kurusToGirdi(iltutar) : '',
    );
    _not = TextEditingController(text: m?.note ?? k?.name ?? '');
    _tarih = m != null ? DateTime.parse(m.date) : DateTime.now();
    _kategoriId = m?.categoryId ?? k?.categoryId;
  }

  @override
  void dispose() {
    _tutar.dispose();
    _not.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final secenekler = _tip == RecordType.gelir
        ? state.gelirKategorileri
        : state.giderKategorileri;
    final seciliKategori = _seciliKategori(secenekler);

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
            _duzenleme ? 'Kaydı Düzenle' : 'Yeni Kayıt',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
            controller: _tutar,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              _sayiFiltresi,
            ],
            decoration: InputDecoration(
              labelText: 'Tutar (₺)',
              prefixText: '₺ ',
              errorText: _tutarHatasi,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_tutarHatasi != null) setState(() => _tutarHatasi = null);
            },
          ),
          const SizedBox(height: 16),
          Text('Kategori', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _KategoriSecici(
            kategoriler: secenekler,
            seciliId: seciliKategori?.id,
            onSec: (c) => setState(() => _kategoriId = c.id),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Tarih'),
            trailing: Text(
              '${_tarih.day} ${monthName(_tarih.month)} ${_tarih.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: _tarihSec,
          ),
          TextField(
            controller: _not,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _kaydet(seciliKategori),
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

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (secilen != null) setState(() => _tarih = secilen);
  }

  Future<void> _kaydet(Category? kategori) async {
    final kurus = parseToKurus(_tutar.text);
    if (kurus == null || kurus <= 0) {
      setState(() => _tutarHatasi = 'Geçerli bir tutar girin.');
      return;
    }
    if (kategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin.')),
      );
      return;
    }
    final state = context.read<AppState>();
    final mevcut = widget.mevcut;
    if (mevcut != null) {
      await state.kayitGuncelle(
        mevcut,
        type: _tip,
        amountKurus: kurus,
        categoryId: kategori.id,
        date: _tarih,
        note: _not.text.trim(),
      );
    } else {
      await state.kayitEkle(
        type: _tip,
        amountKurus: kurus,
        categoryId: kategori.id,
        date: _tarih,
        note: _not.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  static final _sayiFiltresi =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
}

class _KategoriSecici extends StatelessWidget {
  final List<Category> kategoriler;
  final int? seciliId;
  final ValueChanged<Category> onSec;

  const _KategoriSecici({
    required this.kategoriler,
    required this.seciliId,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kategori in kategoriler)
          ChoiceChip(
            avatar: Icon(
              kategoriIkon(kategori),
              size: 18,
              color: kategoriRengi(kategori),
            ),
            label: Text(kategori.name),
            selected: kategori.id == seciliId,
            onSelected: (_) => onSec(kategori),
          ),
      ],
    );
  }
}
