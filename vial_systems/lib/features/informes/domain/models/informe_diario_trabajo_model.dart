import '../../../../features/remito/domain/models/remito_model.dart';

class InformePersonalItem {
  final String empleadoId;
  final String funcionId;
  final double horasTrabajadas;
  final String? observacion;

  InformePersonalItem({
    required this.empleadoId,
    required this.funcionId,
    required this.horasTrabajadas,
    this.observacion,
  });

  factory InformePersonalItem.fromJson(Map<String, dynamic> json) {
    return InformePersonalItem(
      empleadoId: (json['empleado_id'] ?? json['empleadoId'] ?? '') as String,
      funcionId: (json['funcion_id'] ?? json['funcionId'] ?? json['personal_role_id'] ?? json['personalRoleId'] ?? '') as String,
      horasTrabajadas: (json['horas_trabajadas'] as num? ?? json['horasTrabajadas'] as num? ?? 0.0).toDouble(),
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empleado_id': empleadoId,
      'funcion_id': funcionId,
      'horas_trabajadas': horasTrabajadas,
      'observacion': observacion,
    };
  }
}

class InformeDiarioTrabajoModel {
  final String id;
  final DateTime fecha;
  final String? obraId;
  final String usuarioId;
  final String usuarioName;
  final String tareasRealizadas;
  final double horasTrabajadas;
  final List<InformePersonalItem> personal;
  final List<String> maquinariaIds;
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
    required this.personal,
    required this.maquinariaIds,
    required this.observaciones,
    required this.estado,
    required this.fotos,
  });

  factory InformeDiarioTrabajoModel.fromJson(Map<String, dynamic> json) {
    final rawPersonal = json['personal'] ?? json['personal_por_funcion'];
    List<InformePersonalItem> personalList = [];
    if (rawPersonal is List) {
      personalList = rawPersonal.map((e) {
        if (e is Map) {
          return InformePersonalItem.fromJson(Map<String, dynamic>.from(e));
        } else {
          return InformePersonalItem(empleadoId: '', funcionId: e.toString(), horasTrabajadas: 0.0);
        }
      }).toList();
    } else if (rawPersonal is Map) {
      // Compatibilidad con versiones anteriores que usaban Map<String, int>
      rawPersonal.forEach((key, value) {
        personalList.add(InformePersonalItem(
          empleadoId: '',
          funcionId: key.toString(),
          horasTrabajadas: (double.tryParse(value.toString()) ?? 0.0),
        ));
      });
    }

    return InformeDiarioTrabajoModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      obraId: json['obraId'] as String?,
      usuarioId: json['usuarioId'] as String? ?? '',
      usuarioName: json['usuarioName'] as String? ?? 'Desconocido',
      tareasRealizadas: json['tareasRealizadas'] as String? ?? '',
      horasTrabajadas: (json['horasTrabajadas'] as num? ?? 0.0).toDouble(),
      personal: personalList,
      maquinariaIds: (json['maquinariaIds'] as List? ?? json['maquinaria_ids'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      observaciones: json['observaciones'] as String? ?? '',
      estado: RemitoStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => RemitoStatus.borrador,
      ),
      fotos: (json['fotos'] as List?)
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
      'personal': personal.map((p) => p.toJson()).toList(),
      'maquinariaIds': maquinariaIds,
      'observaciones': observaciones,
      'estado': estado.name,
      'fotos': fotos.map((f) => f.toString()).toList(),
    };
  }
}
