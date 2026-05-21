import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repository.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final String _obrasKey = 'obras_data';
  final String _materialesKey = 'materiales_data';
  final String _transportistasKey = 'transportistas_data';
  final String _choferesKey = 'choferes_data';
  final String _camionesKey = 'camiones_data';
  final String _recibidoresKey = 'recibidores_data';
  final String _proveedoresKey = 'proveedores_data';
  final String _maquinariasKey = 'maquinarias_data';
  final String _materialesControlKey = 'materiales_control_data';
  final String _otrosEquiposKey = 'otros_equipos_data';
  final String _camionesInternosKey = 'camiones_internos_data';
  final String _funcionesPersonalKey = 'funciones_personal_data';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Función genérica para obtener datos (Prioriza Supabase, cae en caché local si hay error)
  Future<List<T>> _getSyncList<T>(String table, String cacheKey, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await _supabase.from(table).select().order('created_at');
      final List<T> list = (response as List).map((row) => fromJson(row as Map<String, dynamic>)).toList();
      
      // Guardar en caché
      final prefs = await _prefs;
      await prefs.setString(cacheKey, jsonEncode(list.map((e) => (e as dynamic).toJson()).toList()));
      
      return list;
    } catch (e) {
      // Fallback a caché local si no hay internet
      final prefs = await _prefs;
      final String? data = prefs.getString(cacheKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  // Obras
  @override
  Future<List<ObraModel>> getObras() => _getSyncList('obras', _obrasKey, ObraModel.fromJson);
  
  @override
  Future<void> addObra(ObraModel obra) async {
    await _supabase.from('obras').insert({'id': obra.id, 'nombre': obra.nombre, 'activa': obra.activa});
  }

  @override
  Future<void> updateObra(ObraModel obra) async {
    await _supabase.from('obras').update({'nombre': obra.nombre, 'activa': obra.activa}).eq('id', obra.id);
  }

  // Materiales
  @override
  Future<List<MaterialModel>> getMateriales() => _getSyncList('materiales', _materialesKey, MaterialModel.fromJson);

  @override
  Future<void> addMaterial(MaterialModel material) async {
    await _supabase.from('materiales').insert({'id': material.id, 'nombre': material.nombre});
  }

  // Transportistas
  @override
  Future<List<TransportistaModel>> getTransportistas() => _getSyncList('transportistas', _transportistasKey, TransportistaModel.fromJson);

  @override
  Future<void> addTransportista(TransportistaModel transportista) async {
    await _supabase.from('transportistas').insert({'id': transportista.id, 'nombre': transportista.nombre});
  }

  // Choferes
  @override
  Future<List<ChoferModel>> getChoferes() => _getSyncList('choferes', _choferesKey, ChoferModel.fromJson);

  @override
  Future<void> addChofer(ChoferModel chofer) async {
    await _supabase.from('choferes').insert({'id': chofer.id, 'nombre': chofer.nombre});
  }

  // Camiones
  @override
  Future<List<CamionModel>> getCamiones() => _getSyncList('camiones', _camionesKey, CamionModel.fromJson);

  @override
  Future<void> addCamion(CamionModel camion) async {
    await _supabase.from('camiones').insert({'id': camion.id, 'patente': camion.patente});
  }

  // Recibidores
  @override
  Future<List<RecibidorModel>> getRecibidores() => _getSyncList('recibidores', _recibidoresKey, RecibidorModel.fromJson);

  @override
  Future<void> addRecibidor(RecibidorModel recibidor) async {
    await _supabase.from('recibidores').insert({'id': recibidor.id, 'nombre': recibidor.nombre});
  }

  // Proveedores de Servicio
  @override
  Future<List<OperativeCatalogItem>> getProveedores() =>
      _getSyncList('proveedores_servicio', _proveedoresKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addProveedor(OperativeCatalogItem item) async {
    await _supabase.from('proveedores_servicio').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateProveedor(OperativeCatalogItem item) async {
    await _supabase.from('proveedores_servicio').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }

  // Maquinaria de Obra
  @override
  Future<List<OperativeCatalogItem>> getMaquinarias() =>
      _getSyncList('maquinaria_obra', _maquinariasKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaquinaria(OperativeCatalogItem item) async {
    await _supabase.from('maquinaria_obra').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateMaquinaria(OperativeCatalogItem item) async {
    await _supabase.from('maquinaria_obra').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }

  // Control de Materiales
  @override
  Future<List<OperativeCatalogItem>> getMaterialesControl() =>
      _getSyncList('control_materiales', _materialesControlKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaterialControl(OperativeCatalogItem item) async {
    await _supabase.from('control_materiales').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateMaterialControl(OperativeCatalogItem item) async {
    await _supabase.from('control_materiales').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }

  // Otros Equipos
  @override
  Future<List<OperativeCatalogItem>> getOtrosEquipos() =>
      _getSyncList('otros_equipos', _otrosEquiposKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addOtroEquipo(OperativeCatalogItem item) async {
    await _supabase.from('otros_equipos').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateOtroEquipo(OperativeCatalogItem item) async {
    await _supabase.from('otros_equipos').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }

  // Camiones Internos
  @override
  Future<List<OperativeCatalogItem>> getCamionesInternos() =>
      _getSyncList('camiones_internos', _camionesInternosKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addCamionInterno(OperativeCatalogItem item) async {
    await _supabase.from('camiones_internos').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateCamionInterno(OperativeCatalogItem item) async {
    await _supabase.from('camiones_internos').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }

  // Funciones de Personal
  @override
  Future<List<OperativeCatalogItem>> getFuncionesPersonal() =>
      _getSyncList('funciones_personal', _funcionesPersonalKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addFuncionPersonal(OperativeCatalogItem item) async {
    await _supabase.from('funciones_personal').insert({'id': item.id, 'nombre': item.nombre, 'activa': item.activa});
  }

  @override
  Future<void> updateFuncionPersonal(OperativeCatalogItem item) async {
    await _supabase.from('funciones_personal').update({'nombre': item.nombre, 'activa': item.activa}).eq('id', item.id);
  }
}
