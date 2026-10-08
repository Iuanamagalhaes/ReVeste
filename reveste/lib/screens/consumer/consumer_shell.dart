import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import 'catalog_view.dart';
import 'favorites_tab.dart';
import 'profile_tab.dart';

class ConsumerShell extends StatefulWidget {
  final AppUser usuario;
  const ConsumerShell({super.key, required this.usuario});

  @override
  State<ConsumerShell> createState() => _ConsumerShellState();
}

class _ConsumerShellState extends State<ConsumerShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      body: IndexedStack(
        index: _i,
        children: [
          CatalogView(usuario: u),
          CatalogView(usuario: u, mostrarBusca: true, mostrarCategorias: false),
          FavoritesTab(usuario: u),
          ProfileTab(usuario: u),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.creme,
        indicatorColor: AppColors.salvia.withValues(alpha: 0.4),
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Pesquisa'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
