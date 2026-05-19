import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../catalogs/presentation/screens/catalogs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VialSystems'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'VialSystems - Fase 02',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Text('Bienvenido, ${user.name}', style: const TextStyle(fontSize: 18)),
              Text('Rol: ${user.role.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Email: ${user.email}', style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogsScreen()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Gestionar Catálogos y Obras'),
            ),
          ],
        ),
      ),
    );
  }
}
