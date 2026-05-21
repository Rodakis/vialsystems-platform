import '../../../../features/remito/domain/models/remito_model.dart';

class InformeDiarioModel {
  final String id;
  final DateTime fecha;
  final String? obraId;
  final String usuarioId;
  final String usuarioName;
  final String clima;
  final String estadoCamino;
  final String observaciones;
  final RemitoStatus estado;

  InformeDiarioModel({
    required this.id,
    required this.fecha,
    this.obraId,
    required this.usuarioId,
    required this.usuarioName,
    required this.clima,
    required this.estadoCamino,
    required this.observaciones,
    required this.estado,
  });

  factory InformeDiarioModel.fromJson(Map<String, dynamic> json) {
    return InformeDiarioModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      obraId: json['obraId'] as String?,
      usuarioId: json['usuarioId'] as String? ?? '',
      usuarioName: json['usuarioName'] as String? ?? 'Desconocido',
      clima: json['clima'] as String? ?? 'Soleado',
      estadoCamino: json['estadoCamino'] as String? ?? 'Transitable',
      observaciones: json['observaciones'] as String? ?? '',
      estado: RemitoStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => RemitoStatus.borrador,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'obraId': obraId,
      'usuarioId': usuarioId,
      'usuarioName': usuarioName,
      'clima': clima,
      'estadoCamino': estadoCamino,
      'observaciones': observaciones,
      'estado': estado.name,
    };
  }
}
