import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'admin_remitos_screen.dart';
import 'admin_catalogs_screen.dart';
import 'admin_informes_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VialSystems - Panel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.space_dashboard),
                label: Text('Resumen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('Remitos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books),
                selectedIcon: Icon(Icons.library_books),
                label: Text('Catálogos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Partes Diarios'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text('Dashboard Operacional (Próximamente)'));
      case 1:
        return const AdminRemitosScreen();
      case 2:
        return const AdminCatalogsScreen();
      case 3:
        return const AdminInformesScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
