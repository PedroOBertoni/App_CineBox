import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/catalog')) return 1;
    if (loc.startsWith('/plans')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1C2333), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/catalog');
              case 2: context.go('/plans');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Início'),
            BottomNavigationBarItem(icon: Icon(Icons.movie_filter_rounded), label: 'Catálogo'),
            BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: 'Planos'),
          ],
        ),
      ),
    );
  }
}
