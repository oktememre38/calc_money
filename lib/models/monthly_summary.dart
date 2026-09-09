import 'aggregate.dart';

/// Bir yıldaki tek bir ayın özeti (1..12).
class MonthlySummary {
  final int month;
  final Aggregate aggregate;

  const MonthlySummary({required this.month, required this.aggregate});
}
