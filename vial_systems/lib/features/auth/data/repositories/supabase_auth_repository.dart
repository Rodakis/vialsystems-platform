import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'supabase_cached_user';

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

      debugPrint('Login exitoso con Supabase Auth. Consultando perfil relacional...');
      
      // Consultar la tabla profiles
      Map<String, dynamic>? profileResponse;
      try {
        profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } catch (dbErr) {
        debugPrint('Error al consultar tabla profiles en base de datos: $dbErr');
        // Si hay un error crítico de base de datos durante el login inicial, cerramos la sesión por seguridad
        await _supabase.auth.signOut();
        throw Exception('Error al conectar con la base de datos de perfiles: $dbErr');
      }

      if (profileResponse == null) {
        debugPrint('Error: No se encontró perfil en la tabla profiles para el usuario ID: ${user.id}');
        await _supabase.auth.signOut();
        throw Exception('No se encontró el perfil de usuario asociado en la base de datos.');
      }

      final isActive = profileResponse['activo'] as bool? ?? true;
      if (!isActive) {
        debugPrint('Error: El usuario ${user.email} se encuentra inactivo.');
        await _supabase.auth.signOut();
        throw Exception('El usuario se encuentra inactivo. Comuníquese con el administrador.');
      }

      final roleStr = profileResponse['role'] as String? ?? 'user';
      final name = profileResponse['nombre'] as String? ?? user.email?.split('@').first ?? 'Usuario';

      UserRole role = UserRole.operador;
      if (roleStr == 'admin' || roleStr == 'administrador') {
        role = UserRole.administrador;
      } else if (roleStr == 'oficina') {
        role = UserRole.oficina;
      }

      final userModel = UserModel(
        id: user.id,
        name: name,
        email: user.email ?? email,
        role: role,
      );

      // Guardar sesión en caché local para soporte offline-first
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(userModel.toJson()));
        debugPrint('Perfil de usuario guardado exitosamente en caché local SharedPreferences.');
      } catch (e) {
        debugPrint('Advertencia: No se pudo escribir en caché SharedPreferences: $e');
      }

      debugPrint('Login completado. Rol detectado: ${role.name}. Redirección aplicada.');
      return userModel;
    } catch (e) {
      debugPrint('--- ERROR EN LOGIN CON SUPABASE ---');
      debugPrint('Error en el flujo de autenticación: $e');
      rethrow; // Re-lanzar para que AuthProvider capture el mensaje detallado
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('Cerrando sesión en Supabase Auth...');
      await _supabase.auth.signOut();
      
      // Limpiar caché local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      
      debugPrint('Sesión cerrada y caché eliminada con éxito.');
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

      // Intentar refrescar perfil de la base de datos si hay conexión
      try {
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileResponse != null) {
          final isActive = profileResponse['activo'] as bool? ?? true;
          if (!isActive) {
            debugPrint('Sesión cancelada: Usuario inactivado externamente.');
            await logout();
            return null;
          }

          final roleStr = profileResponse['role'] as String? ?? 'user';
          final name = profileResponse['nombre'] as String? ?? user.email?.split('@').first ?? 'Usuario';

          UserRole role = UserRole.operador;
          if (roleStr == 'admin' || roleStr == 'administrador') {
            role = UserRole.administrador;
          } else if (roleStr == 'oficina') {
            role = UserRole.oficina;
          }

          final userModel = UserModel(
            id: user.id,
            name: name,
            email: user.email ?? '',
            role: role,
          );

          // Actualizar caché local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(userModel.toJson()));

          return userModel;
        }
      } catch (dbError) {
        debugPrint('Fallo al refrescar perfil online (asumiendo modo offline): $dbError');
      }

      // Fallback a caché local si la consulta online falla o estamos offline
      final prefs = await SharedPreferences.getInstance();
      final cachedUserStr = prefs.getString(_cacheKey);
      if (cachedUserStr != null) {
        try {
          debugPrint('Cargando información del usuario desde la caché local SharedPreferences (Offline-first).');
          return UserModel.fromJson(jsonDecode(cachedUserStr));
        } catch (e) {
          debugPrint('Error al decodificar caché local: $e');
        }
      }

      // Fallback secundario de contingencia por correo
      UserRole role = UserRole.operador;
      if (user.email != null) {
        if (user.email!.contains('admin')) {
          role = UserRole.administrador;
        } else if (user.email!.contains('oficina')) {
          role = UserRole.oficina;
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
