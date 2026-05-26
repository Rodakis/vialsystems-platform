import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../catalogs/presentation/screens/catalogs_screen.dart';
import '../../../remito/presentation/screens/remito_list_screen.dart';
import '../../../informes/presentation/screens/informe_list_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/notification_center_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VialSystems [MVP v0.1 TEST]'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      endDrawer: const NotificationCenterDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'VialSystems [MVP v0.1 TEST]',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Text('Bienvenido, ${user.name}', style: const TextStyle(fontSize: 18)),
                Text('Rol: ${user.role.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Email: ${user.email}', style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 32),
              
              // Button 1: Remitos
              SizedBox(
                width: 320,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RemitoListScreen()),
                    );
                  },
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Informes de Acarreo (Remitos)'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Button 2: Informes y Partes Diarios
              SizedBox(
                width: 320,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InformeListScreen()),
                    );
                  },
                  icon: const Icon(Icons.assignment),
                  label: const Text('Informes y Partes Diarios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Button 3: Catalogos
              SizedBox(
                width: 320,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CatalogsScreen()),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Gestionar Catálogos y Obras'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
