import 'dart:async';

import 'package:flutter/material.dart';

import 'home_shell.dart';

/// Uygulama açılış ekranı: kısa bir logo gösterir, sonra ana ekrana geçer.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _zamanlayici;

  @override
  void initState() {
    super.initState();
    _zamanlayici = Timer(const Duration(milliseconds: 1700), _anaEkranaGec);
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  void _anaEkranaGec() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, animasyon, __, cocuk) {
          final egri = CurvedAnimation(parent: animasyon, curve: Curves.easeIn);
          return FadeTransition(opacity: egri, child: cocuk);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme.primary;

    return Scaffold(
      backgroundColor: tema.colorScheme.surface,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, deger, cocuk) => Opacity(
            opacity: deger,
            child: Transform.scale(scale: 0.9 + (deger * 0.1), child: cocuk),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.savings_outlined, size: 52, color: renk),
              ),
              const SizedBox(height: 20),
              Text(
                'CalcMoney',
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gelir · Gider · Takip',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
