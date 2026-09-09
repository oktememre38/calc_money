import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/record_type.dart';

/// Kategori adına göre materyal ikonu döner.
IconData kategoriIkonByName(String name) {
  switch (name) {
    case 'payments':
      return Icons.payments;
    case 'add_card':
      return Icons.add_card;
    case 'home_work':
      return Icons.home_work;
    case 'trending_up':
      return Icons.trending_up;
    case 'savings':
      return Icons.savings;
    case 'apartment':
      return Icons.apartment;
    case 'water_drop':
      return Icons.water_drop;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'bolt':
      return Icons.bolt;
    case 'wifi':
      return Icons.wifi;
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'subscriptions':
      return Icons.subscriptions;
    case 'receipt_long':
      return Icons.receipt_long;
    case 'phone_android':
      return Icons.phone_android;
    case 'directions_bus':
      return Icons.directions_bus;
    case 'medical_services':
      return Icons.medical_services;
    case 'movie':
      return Icons.movie;
    case 'school':
      return Icons.school;
    case 'checkroom':
      return Icons.checkroom;
    case 'category':
      return Icons.category;
    default:
      return Icons.category;
  }
}

IconData kategoriIkon(Category c) => kategoriIkonByName(c.icon);

Color kategoriRengi(Category c) => Color(c.color);

/// Gelir/gider renkleri.
Color gelirRengi(BuildContext context) => Colors.green.shade700;

Color giderRengi(BuildContext context) => Theme.of(context).colorScheme.error;

Color tipRengi(BuildContext context, RecordType tip) =>
    tip == RecordType.gelir ? gelirRengi(context) : giderRengi(context);

/// Kategori avatarı (yuvarlak, renkli ikon).
class CategoryAvatar extends StatelessWidget {
  final Category category;
  final double boyut;

  const CategoryAvatar({super.key, required this.category, this.boyut = 40});

  @override
  Widget build(BuildContext context) {
    final renk = kategoriRengi(category);
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(kategoriIkon(category), color: renk, size: boyut * 0.55),
    );
  }
}
