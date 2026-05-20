import 'dart:convert';

enum RemitoStatus {
  borrador,
  listoParaEnviar,
  sincronizado,
  error,
}

class RemitoFotoModel {
  final String path;
  final DateTime fecha;
  final String usuario;
  final String tipoEvidencia;

  RemitoFotoModel({
    required this.path,
    required this.fecha,
    required this.usuario,
    required this.tipoEvidencia,
  });

  factory RemitoFotoModel.fromJson(Map<String, dynamic> json) {
    return RemitoFotoModel(
      path: json['path'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      usuario: json['usuario'] as String,
      tipoEvidencia: json['tipoEvidencia'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fecha': fecha.toIso8601String(),
      'usuario': usuario,
      'tipoEvidencia': tipoEvidencia,
    };
  }

  factory RemitoFotoModel.fromString(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return RemitoFotoModel.fromJson(decoded);
      }
    } catch (_) {}
    return RemitoFotoModel(
      path: value,
      fecha: DateTime.now(),
      usuario: 'Desconocido',
      tipoEvidencia: 'General',
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class RemitoModel {
  final String id;
  final DateTime fecha;
  final String numeroGuia;
  final String? obraId;
  final String procedencia;
  final String destino;
  final String? materialId;
  final double cantidadM3;
  final String? transportistaId;
  final String? choferId;
  final String? camionPatente;
  final String acopladoPatente;
  final DateTime horaDescarga;
  final String observaciones;
  final RemitoStatus estado;
  final List<RemitoFotoModel> fotos;
  final String? numeroRemito;

  RemitoModel({
    required this.id,
    required this.fecha,
    required this.numeroGuia,
    this.obraId,
    required this.procedencia,
    required this.destino,
    this.materialId,
    required this.cantidadM3,
    this.transportistaId,
    this.choferId,
    this.camionPatente,
    required this.acopladoPatente,
    required this.horaDescarga,
    required this.observaciones,
    required this.estado,
    this.fotos = const [],
    this.numeroRemito,
  });

  factory RemitoModel.fromJson(Map<String, dynamic> json) {
    return RemitoModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      numeroGuia: json['numeroGuia'] as String,
      obraId: json['obraId'] as String?,
      procedencia: json['procedencia'] as String,
      destino: json['destino'] as String,
      materialId: json['materialId'] as String?,
      cantidadM3: (json['cantidadM3'] as num).toDouble(),
      transportistaId: json['transportistaId'] as String?,
      choferId: json['choferId'] as String?,
      camionPatente: json['camionPatente'] as String?,
      acopladoPatente: json['acopladoPatente'] as String,
      horaDescarga: DateTime.parse(json['horaDescarga'] as String),
      observaciones: json['observaciones'] as String,
      estado: json['estado'] == 'enviado' 
          ? RemitoStatus.listoParaEnviar 
          : RemitoStatus.values.firstWhere((e) => e.name == json['estado'], orElse: () => RemitoStatus.borrador),
      fotos: (json['fotos'] as List<dynamic>?)?.map((e) => RemitoFotoModel.fromString(e.toString())).toList() ?? [],
      numeroRemito: json['numeroRemito'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'numeroGuia': numeroGuia,
      'obraId': obraId,
      'procedencia': procedencia,
      'destino': destino,
      'materialId': materialId,
      'cantidadM3': cantidadM3,
      'transportistaId': transportistaId,
      'choferId': choferId,
      'camionPatente': camionPatente,
      'acopladoPatente': acopladoPatente,
      'horaDescarga': horaDescarga.toIso8601String(),
      'observaciones': observaciones,
      'estado': estado.name,
      'fotos': fotos.map((f) => f.toString()).toList(),
      'numeroRemito': numeroRemito,
    };
  }
}
