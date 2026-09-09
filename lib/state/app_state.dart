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

  int get aktifTekrarlayanToplam {
    var toplam = 0;
    for (final k in _tekrarlayanListesi) {
      if (k.active) toplam += k.amountKurus;
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
    required int amountKurus,
    required int dayOfMonth,
    required int categoryId,
    bool notify = true,
  }) async {
    await tekrarlayanlar.insert(
      RecurringExpense(
        name: name,
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
    required int amountKurus,
    required int dayOfMonth,
    required int categoryId,
    bool notify = true,
  }) async {
    await tekrarlayanlar.update(
      mevcut.copyWith(
        name: name,
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
