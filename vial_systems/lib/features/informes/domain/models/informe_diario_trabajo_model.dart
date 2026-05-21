import '../../../../features/remito/domain/models/remito_model.dart';

class InformeDiarioTrabajoModel {
  final String id;
  final DateTime fecha;
  final String? obraId;
  final String usuarioId;
  final String usuarioName;
  final String tareasRealizadas;
  final double horasTrabajadas;
  final int personalPresente;
  final String maquinariaUtilizada;
  final String observaciones;
  final RemitoStatus estado;
  final List<RemitoFotoModel> fotos;

  InformeDiarioTrabajoModel({
    required this.id,
    required this.fecha,
    this.obraId,
    required this.usuarioId,
    required this.usuarioName,
    required this.tareasRealizadas,
    required this.horasTrabajadas,
    required this.personalPresente,
    required this.maquinariaUtilizada,
    required this.observaciones,
    required this.estado,
    required this.fotos,
  });

  factory InformeDiarioTrabajoModel.fromJson(Map<String, dynamic> json) {
    return InformeDiarioTrabajoModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      obraId: json['obraId'] as String?,
      usuarioId: json['usuarioId'] as String? ?? '',
      usuarioName: json['usuarioName'] as String? ?? 'Desconocido',
      tareasRealizadas: json['tareasRealizadas'] as String? ?? '',
      horasTrabajadas: (json['horasTrabajadas'] as num? ?? 0.0).toDouble(),
      personalPresente: json['personalPresente'] as int? ?? 0,
      maquinariaUtilizada: json['maquinariaUtilizada'] as String? ?? '',
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
      'tareasRealizadas': tareasRealizadas,
      'horasTrabajadas': horasTrabajadas,
      'personalPresente': personalPresente,
      'maquinariaUtilizada': maquinariaUtilizada,
      'observaciones': observaciones,
      'estado': estado.name,
      'fotos': fotos.map((f) => f.toString()).toList(),
    };
  }
}
