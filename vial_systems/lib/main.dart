import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/data/repositories/supabase_auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/auth/domain/models/user_model.dart';
import 'core/theme/app_theme.dart';

import 'features/catalogs/data/repositories/supabase_catalog_repository.dart';
import 'core/providers/catalog_provider.dart';

import 'features/remito/data/repositories/local_remito_repository.dart';
import 'core/providers/remito_provider.dart';
import 'features/informes/data/repositories/local_informe_repository.dart';
import 'core/providers/informe_provider.dart';
import 'core/providers/notification_provider.dart';

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
          create: (_) => AuthProvider(SupabaseAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(SupabaseCatalogRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => RemitoProvider(LocalRemitoRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => InformeProvider(LocalInformeRepository()),
        ),
        ChangeNotifierProxyProvider<CatalogProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            context.read<RemitoProvider>(),
            context.read<InformeProvider>(),
            context.read<CatalogProvider>(),
            context.read<AuthProvider>(),
          ),
          update: (context, catalogProvider, notificationProvider) =>
              notificationProvider!..updateProviders(
                context.read<RemitoProvider>(),
                context.read<InformeProvider>(),
                catalogProvider,
                context.read<AuthProvider>(),
              ),
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
      theme: AppTheme.lightTheme,
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
