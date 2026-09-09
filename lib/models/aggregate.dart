/// Tek bir dönemin gelir/gider toplamı.
class Aggregate {
  final int income;
  final int expense;

  const Aggregate({this.income = 0, this.expense = 0});

  int get balance => income - expense;

  bool get isEmpty => income == 0 && expense == 0;
}
