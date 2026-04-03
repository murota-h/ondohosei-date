import 'package:flutter/material.dart';
import 'calculation_screen.dart';
import 'quick_reference_table.dart';
import 'help_screen.dart';
import '../services/app_localizations.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final titles = [tr('navCalcTitle'), tr('navTableTitle'), tr('navHelpTitle')];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.calculate), onPressed: () => _onItemTapped(0), color: _selectedIndex == 0 ? Colors.black : Colors.black45),
          IconButton(icon: const Icon(Icons.table_chart), onPressed: () => _onItemTapped(1), color: _selectedIndex == 1 ? Colors.black : Colors.black45),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => _onItemTapped(2), color: _selectedIndex == 2 ? Colors.black : Colors.black45),
          const SizedBox(width: 8),
        ],
      ),
      body: PageView(
        controller: _pageController, physics: const NeverScrollableScrollPhysics(),
        children: const [CalculationScreen(), QuickReferenceTable(), HelpScreen()],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }
}
