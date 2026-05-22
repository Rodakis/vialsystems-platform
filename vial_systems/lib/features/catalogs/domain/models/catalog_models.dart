class ObraModel {
  final String id;
  final String nombre;
  final bool activa;

  ObraModel({
    required this.id,
    required this.nombre,
    this.activa = true,
  });

  factory ObraModel.fromJson(Map<String, dynamic> json) {
    return ObraModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      activa: json['activa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activa': activa,
    };
  }
}

class MaterialModel {
  final String id;
  final String nombre;

  MaterialModel({required this.id, required this.nombre});

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(id: json['id'] as String, nombre: json['nombre'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}

class TransportistaModel {
  final String id;
  final String nombre;

  TransportistaModel({required this.id, required this.nombre});

  factory TransportistaModel.fromJson(Map<String, dynamic> json) => TransportistaModel(id: json['id'] as String, nombre: json['nombre'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}

class ChoferModel {
  final String id;
  final String nombre;

  ChoferModel({required this.id, required this.nombre});

  factory ChoferModel.fromJson(Map<String, dynamic> json) => ChoferModel(id: json['id'] as String, nombre: json['nombre'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}

class CamionModel {
  final String id;
  final String patente;

  CamionModel({required this.id, required this.patente});

  factory CamionModel.fromJson(Map<String, dynamic> json) => CamionModel(id: json['id'] as String, patente: json['patente'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'patente': patente};
}

class RecibidorModel {
  final String id;
  final String nombre;

  RecibidorModel({required this.id, required this.nombre});

  factory RecibidorModel.fromJson(Map<String, dynamic> json) => RecibidorModel(id: json['id'] as String, nombre: json['nombre'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}

class OperativeCatalogItem {
  final String id;
  final String nombre;
  final bool activa;
  final String? unidadDefault;
  final String? apellido;
  final String? identificador;
  final String? telefono;

  OperativeCatalogItem({
    required this.id,
    required this.nombre,
    this.activa = true,
    this.unidadDefault,
    this.apellido,
    this.identificador,
    this.telefono,
  });

  String get nombreCompleto => (apellido != null && apellido!.isNotEmpty) ? '$nombre $apellido' : nombre;

  factory OperativeCatalogItem.fromJson(Map<String, dynamic> json) {
    return OperativeCatalogItem(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      activa: json['activa'] as bool? ?? json['active'] as bool? ?? json['activo'] as bool? ?? true,
      unidadDefault: json['unidad_default'] as String? ?? json['unidadDefault'] as String?,
      apellido: json['apellido'] as String?,
      identificador: json['identificador'] as String?,
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activa': activa,
      'unidad_default': unidadDefault,
      'apellido': apellido,
      'identificador': identificador,
      'telefono': telefono,
    };
  }
}

