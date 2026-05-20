import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/data/repositories/local_auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/auth/domain/models/user_model.dart';

import 'features/catalogs/data/repositories/supabase_catalog_repository.dart';
import 'core/providers/catalog_provider.dart';

import 'features/remito/data/repositories/local_remito_repository.dart';
import 'core/providers/remito_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ddhhengtjymwqwlhwffd.supabase.co',
    anonKey: 'sb_publishable_xqcDjjjo7w8CcOPCxXokAQ_S7raklvx',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(LocalAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(SupabaseCatalogRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => RemitoProvider(LocalRemitoRepository()),
        ),
      ],
      child: const VialSystemsApp(),
    ),
  );
}

class VialSystemsApp extends StatelessWidget {
  const VialSystemsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VialSystems',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (authProvider.isAuthenticated) {
            if (authProvider.currentUser?.role == UserRole.administrador || authProvider.currentUser?.role == UserRole.oficina) {
              return const AdminDashboardScreen();
            }
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
