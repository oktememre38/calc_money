import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/category_repository.dart';
import '../data/recurring_repository.dart';
import '../data/transaction_repository.dart';
import '../models/aggregate.dart';
import '../models/category.dart';
import '../models/monthly_summary.dart';
import '../models/record_type.dart';
import '../models/recurring_expense.dart';
import '../models/transaction_record.dart';
import '../services/notification_service.dart';

/// Uygulamanın tek durum merkezi (ChangeNotifier).
///
/// Veri (kategoriler, ay kayıtları, yıl özeti, tekrarlayan giderler) ve
/// görünüm (hangi ay/yıl gösteriliyor) burada tutulur. Tüm mutasyonlar veritabanına
/// yazıp ilgili bölümü yeniden yükler ve arayüzü bilgilendirir.
class AppState extends ChangeNotifier {
  final AppDatabase db;
  final CategoryRepository kategoriler;
  final TransactionRepository islemler;
  final RecurringRepository tekrarlayanlar;
  final NotificationService bildirimler = NotificationService();

  AppState(this.db)
      : kategoriler = CategoryRepository(db),
        islemler = TransactionRepository(db),
        tekrarlayanlar = RecurringRepository(db);

  // --- Görünüm durumu ---
  DateTime _gorunenAy = DateTime(DateTime.now().year, DateTime.now().month);
  int _gorunenYil = DateTime.now().year;

  DateTime get gorunenAy => _gorunenAy;
  int get gorunenYil => _gorunenYil;

  // --- Veri ---
  List<Category> _kategoriListesi = [];
  List<TransactionRecord> _ayKayitlari = [];
  Aggregate _ayOzet = const Aggregate();
  List<MonthlySummary> _yilOzet = [];
  List<RecurringExpense> _tekrarlayanListesi = [];

  List<Category> get kategoriListesi => _kategoriListesi;
  List<TransactionRecord> get ayKayitlari => _ayKayitlari;
  Aggregate get ayOzet => _ayOzet;
  List<MonthlySummary> get yilOzet => _yilOzet;
  List<RecurringExpense> get tekrarlayanListesi => _tekrarlayanListesi;

  List<Category> get gelirKategorileri =>
      _kategoriListesi.where((c) => !c.isGider).toList();
  List<Category> get giderKategorileri =>
      _kategoriListesi.where((c) => c.isGider).toList();

  Aggregate get yilAggregate {
    var gelir = 0;
    var gider = 0;
    for (final ozet in _yilOzet) {
      gelir += ozet.aggregate.income;
      gider += ozet.aggregate.expense;
    }
    return Aggregate(income: gelir, expense: gider);
  }

  List<RecurringExpense> get aktifTekrarlayanlar =>
      _tekrarlayanListesi.where((k) => k.active).toList();

  /// Aktif tekrarlayan kayıtların gelir toplamı.
  int get aktifSabitGelirToplam {
    var toplam = 0;
    for (final k in aktifTekrarlayanlar) {
      if (k.type == RecordType.gelir) toplam += k.amountKurus;
    }
    return toplam;
  }

  /// Aktif tekrarlayan kayıtların gider toplamı.
  int get aktifSabitGiderToplam {
    var toplam = 0;
    for (final k in aktifTekrarlayanlar) {
      if (k.type == RecordType.gider) toplam += k.amountKurus;
    }
    return toplam;
  }

  Category kategoriGetir(int id) {
    for (final c in _kategoriListesi) {
      if (c.id == id) return c;
    }
    return const Category(id: 0, name: 'Diğer', typeDb: 1, icon: 'category', color: 0xFF757575);
  }

  // --- Başlangıç ---
  Future<void> init() async {
    await db.open();
    await bildirimler.init();
    await yenile();
  }

  /// Tüm veriyi yeniden yükler.
  Future<void> yenile() async {
    _kategoriListesi = await kategoriler.getAll();
    await _ayYukle();
    await _yilYukle();
    await _tekrarlayanYukle();
    notifyListeners();
  }

  // --- Ay / yıl gezinme ---
  void oncekiAy() {
    _gorunenAy = DateTime(_gorunenAy.year, _gorunenAy.month - 1, 1);
    _gorunenYil = _gorunenAy.year;
    _ayYukle();
    _yilYukle();
    notifyListeners();
  }

  void sonrakiAy() {
    _gorunenAy = DateTime(_gorunenAy.year, _gorunenAy.month + 1, 1);
    _gorunenYil = _gorunenAy.year;
    _ayYukle();
    _yilYukle();
    notifyListeners();
  }

  void buAyaDon() {
    _gorunenAy = DateTime(DateTime.now().year, DateTime.now().month);
    _gorunenYil = _gorunenAy.year;
    _ayYukle();
    _yilYukle();
    notifyListeners();
  }

  void oncekiYil() {
    _gorunenYil -= 1;
    _yilYukle();
    notifyListeners();
  }

  void sonrakiYil() {
    _gorunenYil += 1;
    _yilYukle();
    notifyListeners();
  }

  /// Görünümü belirli bir aya getirir (yıl sekmesinden kayıtlara geçerken).
  void ayaGit(int year, int month) {
    _gorunenAy = DateTime(year, month, 1);
    _gorunenYil = year;
    _ayYukle();
    _yilYukle();
    notifyListeners();
  }

  // --- Gelir/gider kayıtları ---
  Future<void> kayitEkle({
    required RecordType type,
    required int amountKurus,
    required int categoryId,
    required DateTime date,
    String note = '',
  }) async {
    final kayit = TransactionRecord(
      type: type,
      amountKurus: amountKurus,
      categoryId: categoryId,
      date: _dateKey(date),
      note: note,
      createdAt: DateTime.now().toIso8601String(),
    );
    await islemler.insert(kayit);
    await _kayitSonrasiYenile();
  }

  Future<void> kayitGuncelle(
    TransactionRecord mevcut, {
    required RecordType type,
    required int amountKurus,
    required int categoryId,
    required DateTime date,
    String note = '',
  }) async {
    await islemler.update(
      mevcut.copyWith(
        type: type,
        amountKurus: amountKurus,
        categoryId: categoryId,
        date: _dateKey(date),
        note: note,
      ),
    );
    await _kayitSonrasiYenile();
  }

  Future<void> kayitSil(TransactionRecord kayit) async {
    final id = kayit.id;
    if (id == null) return;
    await islemler.delete(id);
    await _kayitSonrasiYenile();
  }

  // --- Tekrarlayan sabit giderler ---
  Future<void> tekrarlayanEkle({
    required String name,
    RecordType type = RecordType.gider,
    required int amountKurus,
    required int dayOfMonth,
    required int categoryId,
    bool notify = true,
  }) async {
    await tekrarlayanlar.insert(
      RecurringExpense(
        name: name,
        type: type,
        amountKurus: amountKurus,
        dayOfMonth: dayOfMonth,
        categoryId: categoryId,
        notify: notify,
        active: true,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _tekrarlayanSonrasiYenile();
  }

  Future<void> tekrarlayanGuncelle(
    RecurringExpense mevcut, {
    required String name,
    RecordType? type,
    required int amountKurus,
    required int dayOfMonth,
    required int categoryId,
    bool notify = true,
  }) async {
    await tekrarlayanlar.update(
      mevcut.copyWith(
        name: name,
        type: type ?? mevcut.type,
        amountKurus: amountKurus,
        dayOfMonth: dayOfMonth,
        categoryId: categoryId,
        notify: notify,
      ),
    );
    await _tekrarlayanSonrasiYenile();
  }

  Future<void> tekrarlayanAktiflikDegistir(RecurringExpense kayit, bool aktif) async {
    await tekrarlayanlar.update(kayit.copyWith(active: aktif));
    await _tekrarlayanSonrasiYenile();
  }

  Future<void> tekrarlayanSil(RecurringExpense kayit) async {
    final id = kayit.id;
    if (id == null) return;
    await tekrarlayanlar.delete(id);
    await _tekrarlayanSonrasiYenile();
  }

  /// Bir sabit kaydı (gelir veya gider) seçilen aylara toplu olarak ekler.
  ///
  /// Her ay için sabit kaydın gününde, kendi tipinde (gelir/gider) bir kayıt
  /// oluşturulur. O ay içinde birebir aynı kayıt (tip + kategori + tutar + not)
  /// zaten varsa o ay atlanır (çift kayıt koruması). Dönen değer: (eklenen, atlanan).
  Future<({int eklenen, int atlanan})> tekrarlayanTopluEkle(
    RecurringExpense sabit,
    List<DateTime> aylar,
  ) async {
    var eklenen = 0;
    var atlanan = 0;
    final gorulen = <String>{};

    for (final ay in aylar) {
      final anahtar = '${ay.year}-${ay.month}';
      if (!gorulen.add(anahtar)) continue;

      final mevcutlar = await islemler.listByMonth(ay.year, ay.month);
      final zatenVar = mevcutlar.any((k) =>
          k.type == sabit.type &&
          k.categoryId == sabit.categoryId &&
          k.amountKurus == sabit.amountKurus &&
          k.note == sabit.name);
      if (zatenVar) {
        atlanan++;
        continue;
      }

      await islemler.insert(
        TransactionRecord(
          type: sabit.type,
          amountKurus: sabit.amountKurus,
          categoryId: sabit.categoryId,
          date: _dateKey(DateTime(ay.year, ay.month, sabit.dayOfMonth)),
          note: sabit.name,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      eklenen++;
    }

    await _kayitSonrasiYenile();
    return (eklenen: eklenen, atlanan: atlanan);
  }

  /// Verilen ayların hangilerinde bu sabit kayıtla birebir aynı bir kayıt
  /// zaten var, onu döner (anahtar "yıl-ay"). "Aylara ekle" penceresi,
  /// daha önce eklenmiş ayları işaretli/kilitli göstermek için kullanır.
  Future<Map<String, bool>> tekrarlayanAyKayitlari(
    RecurringExpense sabit,
    List<DateTime> aylar,
  ) async {
    final durum = <String, bool>{};
    final gorulen = <String>{};
    for (final ay in aylar) {
      final anahtar = '${ay.year}-${ay.month}';
      if (!gorulen.add(anahtar)) continue;
      final mevcutlar = await islemler.listByMonth(ay.year, ay.month);
      durum[anahtar] = mevcutlar.any((k) =>
          k.type == sabit.type &&
          k.categoryId == sabit.categoryId &&
          k.amountKurus == sabit.amountKurus &&
          k.note == sabit.name);
    }
    return durum;
  }

  // --- Yardımcı yükleyiciler ---
  Future<void> _ayYukle() async {
    _ayKayitlari = await islemler.listByMonth(_gorunenAy.year, _gorunenAy.month);
    _ayOzet = await islemler.aggregateByMonth(_gorunenAy.year, _gorunenAy.month);
  }

  Future<void> _yilYukle() async {
    _yilOzet = await islemler.aggregateByYear(_gorunenYil);
  }

  Future<void> _tekrarlayanYukle() async {
    _tekrarlayanListesi = await tekrarlayanlar.getAll();
    // Bildirimleri güncel listeye göre yeniden planla.
    await bildirimler.senkronize(_tekrarlayanListesi);
  }

  Future<void> _kayitSonrasiYenile() async {
    await _ayYukle();
    await _yilYukle();
    notifyListeners();
  }

  Future<void> _tekrarlayanSonrasiYenile() async {
    await _tekrarlayanYukle();
    notifyListeners();
  }

  String _dateKey(DateTime d) {
    final ay = d.month.toString().padLeft(2, '0');
    final gun = d.day.toString().padLeft(2, '0');
    return '${d.year}-$ay-$gun';
  }
}
