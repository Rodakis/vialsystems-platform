enum UserRole {
  operador,
  oficina,
  administrador,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String?;
    UserRole mappedRole = UserRole.operador;
    
    if (roleStr == 'admin' || roleStr == 'administrador') {
      mappedRole = UserRole.administrador;
    } else if (roleStr == 'oficina') {
      mappedRole = UserRole.oficina;
    } else if (roleStr == 'user' || roleStr == 'operador') {
      mappedRole = UserRole.operador;
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: mappedRole,
    );
  }

  Map<String, dynamic> toJson() {
    String roleStr = 'user';
    if (role == UserRole.administrador) {
      roleStr = 'admin';
    } else if (role == UserRole.oficina) {
      roleStr = 'oficina';
    }

    return {
      'id': id,
      'name': name,
      'email': email,
      'role': roleStr,
    };
  }
}
