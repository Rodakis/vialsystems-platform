import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/remito/domain/models/remito_model.dart';
import '../../features/informes/domain/models/informe_diario_model.dart';
import '../../features/informes/domain/models/informe_diario_trabajo_model.dart';
import '../../features/informes/domain/repositories/informe_repository.dart';

class InformeProvider extends ChangeNotifier {
  final InformeRepository _repository;

  List<InformeDiarioModel> _informesDiarios = [];
  List<InformeDiarioTrabajoModel> _informesDiariosTrabajo = [];

  List<InformeDiarioModel> _adminInformesDiarios = [];
  List<InformeDiarioTrabajoModel> _adminInformesDiariosTrabajo = [];

  bool _isLoading = false;

  InformeProvider(this._repository) {
    loadInformes();
  }

  List<InformeDiarioModel> get informesDiarios => _informesDiarios;
  List<InformeDiarioTrabajoModel> get informesDiariosTrabajo => _informesDiariosTrabajo;

  List<InformeDiarioModel> get adminInformesDiarios => _adminInformesDiarios;
  List<InformeDiarioTrabajoModel> get adminInformesDiariosTrabajo => _adminInformesDiariosTrabajo;

  bool get isLoading => _isLoading;

  Future<void> loadInformes() async {
    _isLoading = true;
    notifyListeners();

    _informesDiarios = await _repository.getInformesDiarios();
    _informesDiariosTrabajo = await _repository.getInformesDiariosTrabajo();

    // Sort by date descending
    _informesDiarios.sort((a, b) => b.fecha.compareTo(a.fecha));
    _informesDiariosTrabajo.sort((a, b) => b.fecha.compareTo(a.fecha));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAdminInformes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final responseDiarios = await Supabase.instance.client
          .from('informes_diarios')
          .select()
          .order('fecha', ascending: false);

      _adminInformesDiarios = (responseDiarios as List).map((row) {
        return InformeDiarioModel(
          id: row['id'],
          fecha: DateTime.parse(row['fecha']),
          obraId: row['obra_id'],
          usuarioId: row['usuario_id'] ?? '',
          usuarioName: row['usuario_name'] ?? 'Desconocido',
          clima: row['clima'] ?? 'Soleado',
          estadoCamino: row['estado_camino'] ?? 'Transitable',
          observaciones: row['observaciones'] ?? '',
          estado: RemitoStatus.sincronizado,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching admin informes diarios: $e');
    }

    try {
      final responseTrabajo = await Supabase.instance.client
          .from('informes_diarios_trabajo')
          .select()
          .order('fecha', ascending: false);

      _adminInformesDiariosTrabajo = (responseTrabajo as List).map((row) {
        return InformeDiarioTrabajoModel(
          id: row['id'],
          fecha: DateTime.parse(row['fecha']),
          obraId: row['obra_id'],
          usuarioId: row['usuario_id'] ?? '',
          usuarioName: row['usuario_name'] ?? 'Desconocido',
          tareasRealizadas: row['tareas_realizadas'] ?? '',
          horasTrabajadas: double.parse((row['horas_trabajadas'] ?? 0).toString()),
          personalPresente: int.parse((row['personal_presente'] ?? 0).toString()),
          maquinariaUtilizada: row['maquinaria_utilizada'] ?? '',
          observaciones: row['observaciones'] ?? '',
          estado: RemitoStatus.sincronizado,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching admin informes trabajo: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveInformeDiario(InformeDiarioModel informe) async {
    await _repository.saveInformeDiario(informe);
    await loadInformes();
  }

  Future<void> deleteInformeDiario(String id) async {
    await _repository.deleteInformeDiario(id);
    await loadInformes();
  }

  Future<void> saveInformeDiarioTrabajo(InformeDiarioTrabajoModel informe) async {
    await _repository.saveInformeDiarioTrabajo(informe);
    await loadInformes();
  }

  Future<void> deleteInformeDiarioTrabajo(String id) async {
    await _repository.deleteInformeDiarioTrabajo(id);
    await loadInformes();
  }

  Future<void> syncQueue() async {
    _isLoading = true;
    notifyListeners();

    final supabase = Supabase.instance.client;

    // 1. Sync Daily Reports
    for (var inf in _informesDiarios) {
      if (inf.estado == RemitoStatus.listoParaEnviar || inf.estado == RemitoStatus.error) {
        try {
          String validId = inf.id;
          bool idChanged = false;
          if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(validId)) {
            validId = const Uuid().v4();
            idChanged = true;
          }

          final insertData = {
            'id': validId,
            'fecha': inf.fecha.toIso8601String(),
            'obra_id': inf.obraId,
            'usuario_id': inf.usuarioId,
            'usuario_name': inf.usuarioName,
            'clima': inf.clima,
            'estado_camino': inf.estadoCamino,
            'observaciones': inf.observaciones,
            'estado': 'sincronizado',
          };

          await supabase.from('informes_diarios').upsert(insertData);

          final updated = InformeDiarioModel(
            id: validId,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            clima: inf.clima,
            estadoCamino: inf.estadoCamino,
            observaciones: inf.observaciones,
            estado: RemitoStatus.sincronizado,
          );

          if (idChanged) {
            await _repository.deleteInformeDiario(inf.id);
          }
          await _repository.saveInformeDiario(updated);

        } catch (e) {
          debugPrint('Error sincronizando informe diario ${inf.id}: $e');
          final updatedError = InformeDiarioModel(
            id: inf.id,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            clima: inf.clima,
            estadoCamino: inf.estadoCamino,
            observaciones: inf.observaciones,
            estado: RemitoStatus.error,
          );
          await _repository.saveInformeDiario(updatedError);
        }
      }
    }

    // 2. Sync Daily Work Logs
    for (var inf in _informesDiariosTrabajo) {
      if (inf.estado == RemitoStatus.listoParaEnviar || inf.estado == RemitoStatus.error) {
        try {
          String validId = inf.id;
          bool idChanged = false;
          if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(validId)) {
            validId = const Uuid().v4();
            idChanged = true;
          }

          final insertData = {
            'id': validId,
            'fecha': inf.fecha.toIso8601String(),
            'obra_id': inf.obraId,
            'usuario_id': inf.usuarioId,
            'usuario_name': inf.usuarioName,
            'tareas_realizadas': inf.tareasRealizadas,
            'horas_trabajadas': inf.horasTrabajadas,
            'personal_presente': inf.personalPresente,
            'maquinaria_utilizada': inf.maquinariaUtilizada,
            'observaciones': inf.observaciones,
            'estado': 'sincronizado',
          };

          await supabase.from('informes_diarios_trabajo').upsert(insertData);

          final updated = InformeDiarioTrabajoModel(
            id: validId,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            tareasRealizadas: inf.tareasRealizadas,
            horasTrabajadas: inf.horasTrabajadas,
            personalPresente: inf.personalPresente,
            maquinariaUtilizada: inf.maquinariaUtilizada,
            observaciones: inf.observaciones,
            estado: RemitoStatus.sincronizado,
          );

          if (idChanged) {
            await _repository.deleteInformeDiarioTrabajo(inf.id);
          }
          await _repository.saveInformeDiarioTrabajo(updated);

        } catch (e) {
          debugPrint('Error sincronizando informe trabajo ${inf.id}: $e');
          final updatedError = InformeDiarioTrabajoModel(
            id: inf.id,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            tareasRealizadas: inf.tareasRealizadas,
            horasTrabajadas: inf.horasTrabajadas,
            personalPresente: inf.personalPresente,
            maquinariaUtilizada: inf.maquinariaUtilizada,
            observaciones: inf.observaciones,
            estado: RemitoStatus.error,
          );
          await _repository.saveInformeDiarioTrabajo(updatedError);
        }
      }
    }

    await loadInformes();
  }
}
