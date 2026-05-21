import '../../../../features/remito/domain/models/remito_model.dart';

class InformeDiarioModel {
  final String id;
  final DateTime fecha;
  final String? obraId;
  final String usuarioId;
  final String usuarioName;
  final List<String> proveedoresIds;
  final List<String> maquinariasIds;
  final List<String> materialesIds;
  final List<String> equiposIds;
  final List<String> camionesIds;
  final String observaciones;
  final RemitoStatus estado;
  final List<RemitoFotoModel> fotos;

  InformeDiarioModel({
    required this.id,
    required this.fecha,
    this.obraId,
    required this.usuarioId,
    required this.usuarioName,
    required this.proveedoresIds,
    required this.maquinariasIds,
    required this.materialesIds,
    required this.equiposIds,
    required this.camionesIds,
    required this.observaciones,
    required this.estado,
    required this.fotos,
  });

  factory InformeDiarioModel.fromJson(Map<String, dynamic> json) {
    return InformeDiarioModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      obraId: json['obraId'] as String?,
      usuarioId: json['usuarioId'] as String? ?? '',
      usuarioName: json['usuarioName'] as String? ?? 'Desconocido',
      proveedoresIds: (json['proveedoresIds'] ?? json['proveedores_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maquinariasIds: (json['maquinariasIds'] ?? json['maquinarias_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      materialesIds: (json['materialesIds'] ?? json['materiales_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      equiposIds: (json['equiposIds'] ?? json['equipos_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      camionesIds: (json['camionesIds'] ?? json['camiones_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      observaciones: json['observaciones'] as String? ?? '',
      estado: RemitoStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => RemitoStatus.borrador,
      ),
      fotos: (json['fotos'] as List<dynamic>?)
              ?.map((e) => RemitoFotoModel.fromString(e.toString()))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'obraId': obraId,
      'usuarioId': usuarioId,
      'usuarioName': usuarioName,
      'proveedoresIds': proveedoresIds,
      'maquinariasIds': maquinariasIds,
      'materialesIds': materialesIds,
      'equiposIds': equiposIds,
      'camionesIds': camionesIds,
      'observaciones': observaciones,
      'estado': estado.name,
      'fotos': fotos.map((f) => f.toString()).toList(),
    };
  }
}
