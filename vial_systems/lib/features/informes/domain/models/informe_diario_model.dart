import '../../../../features/remito/domain/models/remito_model.dart';

class InformeMaterialItem {
  final String materialId;
  final double cantidad;
  final String unidad;
  final String? observacion;

  InformeMaterialItem({
    required this.materialId,
    required this.cantidad,
    required this.unidad,
    this.observacion,
  });

  factory InformeMaterialItem.fromJson(Map<String, dynamic> json) {
    return InformeMaterialItem(
      materialId: json['material_id'] as String? ?? json['materialId'] as String? ?? '',
      cantidad: (json['cantidad'] as num? ?? 0.0).toDouble(),
      unidad: json['unidad'] as String? ?? '',
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'cantidad': cantidad,
      'unidad': unidad,
      'observacion': observacion,
    };
  }
}

class InformeDiarioModel {
  final String id;
  final DateTime fecha;
  final String? obraId;
  final String usuarioId;
  final String usuarioName;
  final List<String> proveedoresIds;
  final List<String> maquinariasIds;
  final List<InformeMaterialItem> materiales;
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
    required this.materiales,
    required this.equiposIds,
    required this.camionesIds,
    required this.observaciones,
    required this.estado,
    required this.fotos,
  });

  factory InformeDiarioModel.fromJson(Map<String, dynamic> json) {
    final rawMateriales = json['materiales'] ?? json['materiales_ids'];
    List<InformeMaterialItem> materialesList = [];
    if (rawMateriales is List) {
      materialesList = rawMateriales.map((e) {
        if (e is Map) {
          return InformeMaterialItem.fromJson(e as Map<String, dynamic>);
        } else {
          // Fallback en caso de que viniera solo String ID en versiones anteriores
          return InformeMaterialItem(materialId: e.toString(), cantidad: 0.0, unidad: '');
        }
      }).toList();
    }

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
      materiales: materialesList,
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
      'materiales': materiales.map((m) => m.toJson()).toList(),
      'equiposIds': equiposIds,
      'camionesIds': camionesIds,
      'observaciones': observaciones,
      'estado': estado.name,
      'fotos': fotos.map((f) => f.toString()).toList(),
    };
  }
}
