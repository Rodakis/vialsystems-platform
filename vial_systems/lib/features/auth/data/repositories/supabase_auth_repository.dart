import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      debugPrint('--- SUPABASE AUTH LOGIN ---');
      debugPrint('Intentando iniciar sesión real con Supabase para: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        debugPrint('Error: Supabase devolvió sesión o usuario nulo.');
        return null;
      }

      debugPrint('Login exitoso con Supabase Auth.');
      debugPrint('Usuario actual: ${user.email} (ID: ${user.id})');
      debugPrint('Access Token: ${session.accessToken}');
      debugPrint('Sesión actual activa: ${_supabase.auth.currentSession != null}');

      // Determinar rol basado en metadatos o prefijo del correo
      UserRole role = UserRole.operador;
      final metaRole = user.userMetadata?['role'] as String?;
      if (metaRole != null) {
        if (metaRole == 'administrador' || metaRole == 'admin') {
          role = UserRole.administrador;
        } else if (metaRole == 'oficina') {
          role = UserRole.oficina;
        }
      } else {
        // Fallback robusto por correo
        if (email.contains('admin')) {
          role = UserRole.administrador;
        } else if (email.contains('oficina')) {
          role = UserRole.oficina;
        }
      }

      final name = user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Usuario';

      return UserModel(
        id: user.id,
        name: name,
        email: user.email ?? email,
        role: role,
      );
    } catch (e) {
      debugPrint('--- ERROR EN LOGIN CON SUPABASE ---');
      debugPrint('Error completo de Supabase Auth: $e');
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('Cerrando sesión en Supabase Auth...');
      await _supabase.auth.signOut();
      debugPrint('Sesión cerrada con éxito.');
    } catch (e) {
      debugPrint('Error al cerrar sesión en Supabase: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session == null || user == null) {
        return null;
      }

      UserRole role = UserRole.operador;
      final metaRole = user.userMetadata?['role'] as String?;
      if (metaRole != null) {
        if (metaRole == 'administrador' || metaRole == 'admin') {
          role = UserRole.administrador;
        } else if (metaRole == 'oficina') {
          role = UserRole.oficina;
        }
      } else {
        if (user.email != null) {
          if (user.email!.contains('admin')) {
            role = UserRole.administrador;
          } else if (user.email!.contains('oficina')) {
            role = UserRole.oficina;
          }
        }
      }

      final name = user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Usuario';

      return UserModel(
        id: user.id,
        name: name,
        email: user.email ?? '',
        role: role,
      );
    } catch (e) {
      debugPrint('Error al obtener usuario actual de Supabase: $e');
      return null;
    }
  }
}
