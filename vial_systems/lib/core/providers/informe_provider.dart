import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
          proveedoresIds: (row['proveedores_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          maquinariasIds: (row['maquinarias_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          materialesIds: (row['materiales_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          equiposIds: (row['equipos_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          camionesIds: (row['camiones_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          observaciones: row['observaciones'] ?? '',
          estado: RemitoStatus.sincronizado,
          fotos: (row['fotos'] as List<dynamic>?)
                  ?.map((e) => RemitoFotoModel.fromString(e.toString()))
                  .toList() ??
              [],
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
        final rawPersonal = row['personal_por_funcion'];
        final Map<String, int> personalMap = {};
        if (rawPersonal is Map) {
          rawPersonal.forEach((key, value) {
            personalMap[key.toString()] = int.tryParse(value.toString()) ?? 0;
          });
        }

        return InformeDiarioTrabajoModel(
          id: row['id'],
          fecha: DateTime.parse(row['fecha']),
          obraId: row['obra_id'],
          usuarioId: row['usuario_id'] ?? '',
          usuarioName: row['usuario_name'] ?? 'Desconocido',
          tareasRealizadas: row['tareas_realizadas'] ?? '',
          horasTrabajadas: double.parse((row['horas_trabajadas'] ?? 0).toString()),
          personalPorFuncion: personalMap,
          maquinariaIds: (row['maquinaria_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          observaciones: row['observaciones'] ?? '',
          estado: RemitoStatus.sincronizado,
          fotos: (row['fotos'] as List<dynamic>?)
                  ?.map((e) => RemitoFotoModel.fromString(e.toString()))
                  .toList() ??
              [],
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

          List<RemitoFotoModel> uploadedFotos = [];
          for (var foto in inf.fotos) {
            if (foto.path.startsWith('http') && !foto.path.startsWith('blob:')) {
              uploadedFotos.add(foto);
              continue;
            }
            if (kIsWeb) {
              uploadedFotos.add(foto);
              continue;
            }
            final fileName = 'inf_diario_${validId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(foto.path);
            await supabase.storage.from('fotos_remitos').upload(fileName, file);
            final publicUrl = supabase.storage.from('fotos_remitos').getPublicUrl(fileName);
            uploadedFotos.add(RemitoFotoModel(
              path: publicUrl,
              fecha: foto.fecha,
              usuario: foto.usuario,
              tipoEvidencia: foto.tipoEvidencia,
            ));
          }

          final insertData = {
            'id': validId,
            'fecha': inf.fecha.toIso8601String(),
            'obra_id': inf.obraId,
            'usuario_id': inf.usuarioId,
            'usuario_name': inf.usuarioName,
            'proveedores_ids': inf.proveedoresIds,
            'maquinarias_ids': inf.maquinariasIds,
            'materiales_ids': inf.materialesIds,
            'equipos_ids': inf.equiposIds,
            'camiones_ids': inf.camionesIds,
            'observaciones': inf.observaciones,
            'estado': 'sincronizado',
            'fotos': uploadedFotos.map((f) => f.toString()).toList(),
          };

          await supabase.from('informes_diarios').upsert(insertData);

          final updated = InformeDiarioModel(
            id: validId,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            proveedoresIds: inf.proveedoresIds,
            maquinariasIds: inf.maquinariasIds,
            materialesIds: inf.materialesIds,
            equiposIds: inf.equiposIds,
            camionesIds: inf.camionesIds,
            observaciones: inf.observaciones,
            estado: RemitoStatus.sincronizado,
            fotos: uploadedFotos,
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
            proveedoresIds: inf.proveedoresIds,
            maquinariasIds: inf.maquinariasIds,
            materialesIds: inf.materialesIds,
            equiposIds: inf.equiposIds,
            camionesIds: inf.camionesIds,
            observaciones: inf.observaciones,
            estado: RemitoStatus.error,
            fotos: inf.fotos,
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

          List<RemitoFotoModel> uploadedFotos = [];
          for (var foto in inf.fotos) {
            if (foto.path.startsWith('http') && !foto.path.startsWith('blob:')) {
              uploadedFotos.add(foto);
              continue;
            }
            if (kIsWeb) {
              uploadedFotos.add(foto);
              continue;
            }
            final fileName = 'inf_trabajo_${validId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(foto.path);
            await supabase.storage.from('fotos_remitos').upload(fileName, file);
            final publicUrl = supabase.storage.from('fotos_remitos').getPublicUrl(fileName);
            uploadedFotos.add(RemitoFotoModel(
              path: publicUrl,
              fecha: foto.fecha,
              usuario: foto.usuario,
              tipoEvidencia: foto.tipoEvidencia,
            ));
          }

          final insertData = {
            'id': validId,
            'fecha': inf.fecha.toIso8601String(),
            'obra_id': inf.obraId,
            'usuario_id': inf.usuarioId,
            'usuario_name': inf.usuarioName,
            'tareas_realizadas': inf.tareasRealizadas,
            'horas_trabajadas': inf.horasTrabajadas,
            'personal_por_funcion': inf.personalPorFuncion,
            'maquinaria_ids': inf.maquinariaIds,
            'observaciones': inf.observaciones,
            'estado': 'sincronizado',
            'fotos': uploadedFotos.map((f) => f.toString()).toList(),
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
            personalPorFuncion: inf.personalPorFuncion,
            maquinariaIds: inf.maquinariaIds,
            observaciones: inf.observaciones,
            estado: RemitoStatus.sincronizado,
            fotos: uploadedFotos,
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
            personalPorFuncion: inf.personalPorFuncion,
            maquinariaIds: inf.maquinariaIds,
            observaciones: inf.observaciones,
            estado: RemitoStatus.error,
            fotos: inf.fotos,
          );
          await _repository.saveInformeDiarioTrabajo(updatedError);
        }
      }
    }

    await loadInformes();
  }
}
