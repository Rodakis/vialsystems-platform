import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  static const String _userKey = 'current_user';
  
  // Usuarios simulados para pruebas
  final List<UserModel> _mockUsers = [
    UserModel(id: '1', name: 'Admin Test', email: 'admin@test.com', role: UserRole.administrador),
    UserModel(id: '2', name: 'Operador 1', email: 'operador1@test.com', role: UserRole.operador),
    UserModel(id: '3', name: 'Operador 2', email: 'operador2@test.com', role: UserRole.operador),
  ];

  @override
  Future<UserModel?> login(String email, String password) async {
    // Simular retardo de red
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Validacion para soportar la pass de la app real ('123') y la de los tests ('123456')
    if (password != '123' && password != '123456') {
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
