import 'package:flutter/material.dart';

import 'annual_page.dart';
import 'overview_page.dart';
import 'records_page.dart';
import 'recurring_page.dart';

/// Alt sekmeli ana kabuk.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _sekme = 0;

  void _sekmeyeGit(int sekme) {
    setState(() => _sekme = sekme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _sekme,
        children: [
          OverviewPage(
            onSabitleriGoster: () => _sekmeyeGit(3),
          ),
          const RecordsPage(),
          AnnualPage(
            onAyaSec: (yil, ay) {
              setState(() {
                _sekme = 1;
              });
            },
          ),
          const RecurringPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sekme,
        onDestinationSelected: _sekmeyeGit,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Kayıtlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Yıllık',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Sabitler',
          ),
        ],
      ),
    );
  }
}
