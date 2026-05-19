import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  static const String _userKey = 'current_user';
  
  // Usuarios simulados para pruebas
  final List<UserModel> _mockUsers = [
    UserModel(id: '1', name: 'Operador Test', email: 'operador@test.com', role: UserRole.operador),
    UserModel(id: '2', name: 'Oficina Test', email: 'oficina@test.com', role: UserRole.oficina),
    UserModel(id: '3', name: 'Admin Test', email: 'admin@test.com', role: UserRole.administrador),
  ];

  @override
  Future<UserModel?> login(String email, String password) async {
    // Simular retardo de red
    await Future.delayed(const Duration(seconds: 1));
    
    // Validacion muy basica para la fase 01
    if (password != '123456') {
      return null;
    }

    try {
      final user = _mockUsers.firstWhere((u) => u.email == email);
      
      // Guardar sesion local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      return user;
    } catch (e) {
      // Usuario no encontrado
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    
    if (userStr != null) {
      try {
        final Map<String, dynamic> userJson = jsonDecode(userStr);
        return UserModel.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
