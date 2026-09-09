import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/recurring_expense.dart';
import '../state/app_state.dart';
import '../utils/money.dart';
import '../widgets/category_visual.dart';
import '../widgets/common.dart';
import '../widgets/recurring_editor.dart';
import '../widgets/recurring_months_sheet.dart';
import '../widgets/transaction_editor.dart';

/// Sabit kayıtlar: tekrarlayan gider ve gelirler, kategoriye göre gruplanır.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final kayitlar = state.tekrarlayanListesi;

    return Scaffold(
      appBar: AppBar(title: const Text('Sabit Kayıtlar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRecurringEditor(context),
        tooltip: 'Sabit kayıt ekle',
        child: const Icon(Icons.add),
      ),
      body: kayitlar.isEmpty
          ? EmptyState(
              icon: Icons.event_repeat,
              mesaj:
                  'Henüz sabit kayıt yok.\nKira, abonelik gibi sabit giderlerini '
                  'veya kira/temettü getirisi gibi sabit gelirlerini ekle; '
                  'istersen her ay hatırlatalım.',
              alt: FilledButton.tonalIcon(
                onPressed: () => showRecurringEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Sabit kayıt ekle'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                if (state.aktifTekrarlayanlar.isNotEmpty) ...[
                  _OzetKarti(state: state),
                  const SizedBox(height: 12),
                ],
                ..._gruplanmisSatirlar(context, state, kayitlar),
              ],
            ),
    );
  }

  List<Widget> _gruplanmisSatirlar(
    BuildContext context,
    AppState state,
    List<RecurringExpense> kayitlar,
  ) {
    final gruplar = <int, List<RecurringExpense>>{};
    for (final kayit in kayitlar) {
      final kok = state.kategoriKokGetir(state.kategoriGetir(kayit.categoryId));
      gruplar.putIfAbsent(kok.id, () => []).add(kayit);
    }

    final giderKokler = <Category>[];
    final gelirKokler = <Category>[];
    for (final kategori in state.kategoriListesi) {
      if (!gruplar.containsKey(kategori.id)) continue;
      (kategori.isGider ? giderKokler : gelirKokler).add(kategori);
    }

    return [
      _TipBolumu(
        baslik: 'Giderler',
        ikon: Icons.south_west,
        ikonRenk: giderRengi(context),
        kokKategoriler: giderKokler,
        gruplar: gruplar,
        state: state,
        bosMesaj: 'Gider kaydı yok.\nKira, abonelik, taksit gibi sabit '
            'giderlerini + ile ekleyebilirsin.',
      ),
      const SizedBox(height: 16),
      _TipBolumu(
        baslik: 'Gelirler',
        ikon: Icons.north_east,
        ikonRenk: gelirRengi(context),
        kokKategoriler: gelirKokler,
        gruplar: gruplar,
        state: state,
        bosMesaj: 'Gelir kaydı yok.\nMaaş, kira geliri gibi sabit gelirlerini '
            '+ ile ekleyebilirsin.',
      ),
    ];
  }
}

/// "Giderler"/"Gelirler" üst bölümü: başlık + içindeki kategori grupları.
class _TipBolumu extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Color ikonRenk;
  final List<Category> kokKategoriler;
  final Map<int, List<RecurringExpense>> gruplar;
  final AppState state;
  final String bosMesaj;

  const _TipBolumu({
    required this.baslik,
    required this.ikon,
    required this.ikonRenk,
    required this.kokKategoriler,
    required this.gruplar,
    required this.state,
    required this.bosMesaj,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(ikon, color: ikonRenk, size: 20),
              const SizedBox(width: 8),
              Text(
                baslik,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (kokKategoriler.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text(
              bosMesaj,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < kokKategoriler.length; i++)
            _KategoriGrubu(
              kategori: kokKategoriler[i],
              kayitlar: gruplar[kokKategoriler[i].id]!,
              state: state,
              acikBaslangic: i == 0,
            ),
      ],
    );
  }
}

/// Tek bir kategoriye ait sabit kayıtların açılır/kapanır grubu.
class _KategoriGrubu extends StatelessWidget {
  final Category kategori;
  final List<RecurringExpense> kayitlar;
  final AppState state;

  /// Bölümün ilk grubuysa sayfa ilk açıldığında açık başlar.
  final bool acikBaslangic;

  const _KategoriGrubu({
    required this.kategori,
    required this.kayitlar,
    required this.state,
    this.acikBaslangic = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final aktifToplam = kayitlar.fold<int>(
      0,
      (toplam, k) => k.active ? toplam + k.amountKurus : toplam,
    );
    final altYazi = aktifToplam > 0
        ? '${kayitlar.length} kayıt • ${formatMoney(aktifToplam)}'
        : '${kayitlar.length} kayıt';

    return ExpansionTile(
      key: PageStorageKey('grup-${kategori.id}'),
      initiallyExpanded: acikBaslangic,
      leading: CategoryAvatar(category: kategori, boyut: 34),
      title: Text(
        kategori.name,
        style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(altYazi),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final kayit in kayitlar) _SabitKayitSatiri(kayit: kayit),
      ],
    );
  }
}

class _OzetKarti extends StatelessWidget {
  final AppState state;

  const _OzetKarti({required this.state});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _OzetSatir(
              ikon: Icons.trending_up,
              ikonRenk: gelirRengi(context),
              etiket: 'Aylık sabit gelir',
              deger: formatMoney(state.aktifSabitGelirToplam),
              degerRenk: gelirRengi(context),
            ),
            const Divider(height: 16),
            _OzetSatir(
              ikon: Icons.trending_down,
              ikonRenk: giderRengi(context),
              etiket: 'Aylık sabit gider',
              deger: formatMoney(state.aktifSabitGiderToplam),
              degerRenk: giderRengi(context),
            ),
            const SizedBox(height: 4),
            Text(
              'Tahmini aylık denge: '
              '${formatMoney(state.aktifSabitGelirToplam - state.aktifSabitGiderToplam)}',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _OzetSatir extends StatelessWidget {
  final IconData ikon;
  final Color ikonRenk;
  final String etiket;
  final String deger;
  final Color degerRenk;

  const _OzetSatir({
    required this.ikon,
    required this.ikonRenk,
    required this.etiket,
    required this.deger,
    required this.degerRenk,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(ikon, color: ikonRenk, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(etiket, style: tema.textTheme.bodyMedium),
        ),
        Text(
          deger,
          style: tema.textTheme.titleSmall?.copyWith(
            color: degerRenk,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

enum _Islem { kayitEkle, duzenle, aktiflik, sil }

class _SabitKayitSatiri extends StatelessWidget {
  final RecurringExpense kayit;

  const _SabitKayitSatiri({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final kategori = state.kategoriGetir(kayit.categoryId);
    final tema = Theme.of(context);
    final tutarRenk = kategori.isGider
        ? giderRengi(context)
        : gelirRengi(context);
    final messenger = ScaffoldMessenger.of(context);

    final bildirimMetni = kayit.notify ? 'hatırlatma açık' : 'hatırlatma kapalı';
    final altYazi =
        '${kategori.name} • Her ayın ${kayit.dayOfMonth}. günü • $bildirimMetni';

    return Dismissible(
      key: ValueKey('tekrarlayan-${kayit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: giderRengi(context),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => onayIste(
        context,
        baslik: 'Sabit kayıt silinsin mi?',
        mesaj: '${kayit.name}: ${formatMoney(kayit.amountKurus)}',
      ),
      onDismissed: (_) {
        state.tekrarlayanSil(kayit);
        _geriAlGoster(messenger, state, 'Sabit kayıt silindi');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          onTap: () => showRecurringMonthsSheet(context, kayit),
          leading: Stack(
            children: [
              CategoryAvatar(category: kategori),
              if (!kayit.active)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            kayit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(altYazi, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kayit.notify)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.notifications_active,
                      size: 18, color: Colors.amber),
                ),
              Text(
                formatMoney(kayit.amountKurus),
                style: tema.textTheme.titleSmall
                    ?.copyWith(color: tutarRenk, fontWeight: FontWeight.w600),
              ),
              PopupMenuButton<_Islem>(
                tooltip: 'İşlemler',
                onSelected: (islem) => _islemYap(context, islem),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: _Islem.kayitEkle,
                    child: Text('Bu ay için kayıt ekle'),
                  ),
                  const PopupMenuItem(
                    value: _Islem.duzenle,
                    child: Text('Düzenle'),
                  ),
                  PopupMenuItem(
                    value: _Islem.aktiflik,
                    child: Text(kayit.active ? 'Pasif yap' : 'Aktif yap'),
                  ),
                  const PopupMenuItem(value: _Islem.sil, child: Text('Sil')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _islemYap(BuildContext context, _Islem islem) {
    final state = context.read<AppState>();
    switch (islem) {
      case _Islem.kayitEkle:
        showTransactionEditor(context, kaynak: kayit);
      case _Islem.duzenle:
        showRecurringEditor(context, mevcut: kayit);
      case _Islem.aktiflik:
        state.tekrarlayanAktiflikDegistir(kayit, !kayit.active);
      case _Islem.sil:
        _sil(context);
    }
  }

  Future<void> _sil(BuildContext context) async {
    final onay = await onayIste(
      context,
      baslik: 'Sabit kayıt silinsin mi?',
      mesaj: '${kayit.name}: ${formatMoney(kayit.amountKurus)}',
    );
    if (!onay || !context.mounted) return;
    final state = context.read<AppState>();
    await state.tekrarlayanSil(kayit);
    if (!context.mounted) return;
    _geriAlGoster(
      ScaffoldMessenger.of(context),
      state,
      'Sabit kayıt silindi',
    );
  }

  void _geriAlGoster(
    ScaffoldMessengerState messenger,
    AppState appState,
    String metin,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(metin),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => appState.sonSilineniGeriAl(),
          ),
        ),
      );
  }
}
