import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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
  final String _personalEmpleadosKey = 'personal_empleados_data';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  void _logSupabaseStatus(String table, String operation, [dynamic error]) {
    try {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      debugPrint('================================================================');
      debugPrint('--- MONITOREO SUPABASE PARA OPERACIÓN: $operation ---');
      debugPrint('Tabla Destino: $table');
      if (user != null) {
        debugPrint('Usuario Autenticado: ${user.email} (ID: ${user.id})');
      } else {
        debugPrint('Usuario Autenticado: NINGUNO (Sesión anónima o no iniciada)');
      }
      if (session != null) {
        debugPrint('Sesión Activa: SÍ');
        final token = session.accessToken;
        final len = token.length;
        debugPrint('Access Token (primeros 20 caracteres): ${token.substring(0, math.min(20, len))}...');
        debugPrint('Token expiración: ${session.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).toLocal() : 'No expira/Nulo'}');
      } else {
        debugPrint('Sesión Activa: NO (Sin credenciales en el cliente Supabase)');
      }
      if (error != null) {
        debugPrint('ERROR COMPLETO DE SUPABASE:');
        debugPrint(error.toString());
      }
      debugPrint('================================================================');
    } catch (e) {
      debugPrint('Error interno al imprimir log Supabase: $e');
    }
  }

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
    try {
      _logSupabaseStatus('obras', 'INSERT');
      await _supabase.from('obras').insert({'id': obra.id, 'nombre': obra.nombre, 'activa': obra.activa});
      debugPrint('Inserción en obras exitosa.');
    } catch (e) {
      _logSupabaseStatus('obras', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateObra(ObraModel obra) async {
    try {
      _logSupabaseStatus('obras', 'UPDATE');
      await _supabase.from('obras').update({'nombre': obra.nombre, 'activa': obra.activa}).eq('id', obra.id);
      debugPrint('Actualización en obras exitosa.');
    } catch (e) {
      _logSupabaseStatus('obras', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Materiales
  @override
  Future<List<MaterialModel>> getMateriales() => _getSyncList('materiales', _materialesKey, MaterialModel.fromJson);

  @override
  Future<void> addMaterial(MaterialModel material) async {
    try {
      _logSupabaseStatus('materiales', 'INSERT');
      await _supabase.from('materiales').insert({'id': material.id, 'nombre': material.nombre});
      debugPrint('Inserción en materiales exitosa.');
    } catch (e) {
      _logSupabaseStatus('materiales', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  // Transportistas
  @override
  Future<List<TransportistaModel>> getTransportistas() => _getSyncList('transportistas', _transportistasKey, TransportistaModel.fromJson);

  @override
  Future<void> addTransportista(TransportistaModel transportista) async {
    try {
      _logSupabaseStatus('transportistas', 'INSERT');
      await _supabase.from('transportistas').insert({'id': transportista.id, 'nombre': transportista.nombre});
      debugPrint('Inserción en transportistas exitosa.');
    } catch (e) {
      _logSupabaseStatus('transportistas', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  // Choferes
  @override
  Future<List<ChoferModel>> getChoferes() => _getSyncList('choferes', _choferesKey, ChoferModel.fromJson);

  @override
  Future<void> addChofer(ChoferModel chofer) async {
    try {
      _logSupabaseStatus('choferes', 'INSERT');
      await _supabase.from('choferes').insert({'id': chofer.id, 'nombre': chofer.nombre});
      debugPrint('Inserción en choferes exitosa.');
    } catch (e) {
      _logSupabaseStatus('choferes', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  // Camiones
  @override
  Future<List<CamionModel>> getCamiones() => _getSyncList('camiones', _camionesKey, CamionModel.fromJson);

  @override
  Future<void> addCamion(CamionModel camion) async {
    try {
      _logSupabaseStatus('camiones', 'INSERT');
      await _supabase.from('camiones').insert({'id': camion.id, 'patente': camion.patente});
      debugPrint('Inserción en camiones exitosa.');
    } catch (e) {
      _logSupabaseStatus('camiones', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  // Recibidores
  @override
  Future<List<RecibidorModel>> getRecibidores() => _getSyncList('recibidores', _recibidoresKey, RecibidorModel.fromJson);

  @override
  Future<void> addRecibidor(RecibidorModel recibidor) async {
    try {
      _logSupabaseStatus('recibidores', 'INSERT');
      await _supabase.from('recibidores').insert({'id': recibidor.id, 'nombre': recibidor.nombre});
      debugPrint('Inserción en recibidores exitosa.');
    } catch (e) {
      _logSupabaseStatus('recibidores', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  // Proveedores de Servicio
  @override
  Future<List<OperativeCatalogItem>> getProveedores() =>
      _getSyncList('proveedores_servicio', _proveedoresKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addProveedor(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('proveedores_servicio', 'INSERT');
      await _supabase.from('proveedores_servicio').insert({'id': item.id, 'nombre': item.nombre, 'activo': item.activa});
      debugPrint('Inserción en proveedores_servicio exitosa.');
    } catch (e) {
      _logSupabaseStatus('proveedores_servicio', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProveedor(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('proveedores_servicio', 'UPDATE');
      await _supabase.from('proveedores_servicio').update({'nombre': item.nombre, 'activo': item.activa}).eq('id', item.id);
      debugPrint('Actualización en proveedores_servicio exitosa.');
    } catch (e) {
      _logSupabaseStatus('proveedores_servicio', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Maquinaria de Obra
  @override
  Future<List<OperativeCatalogItem>> getMaquinarias() =>
      _getSyncList('maquinaria_obra', _maquinariasKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaquinaria(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('maquinaria_obra', 'INSERT');
      await _supabase.from('maquinaria_obra').insert({'id': item.id, 'nombre': item.nombre, 'activo': item.activa});
      debugPrint('Inserción en maquinaria_obra exitosa.');
    } catch (e) {
      _logSupabaseStatus('maquinaria_obra', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMaquinaria(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('maquinaria_obra', 'UPDATE');
      await _supabase.from('maquinaria_obra').update({'nombre': item.nombre, 'activo': item.activa}).eq('id', item.id);
      debugPrint('Actualización en maquinaria_obra exitosa.');
    } catch (e) {
      _logSupabaseStatus('maquinaria_obra', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Control de Materiales
  @override
  Future<List<OperativeCatalogItem>> getMaterialesControl() =>
      _getSyncList('control_materiales', _materialesControlKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaterialControl(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('control_materiales', 'INSERT');
      await _supabase.from('control_materiales').insert({
        'id': item.id,
        'nombre': item.nombre,
        'activo': item.activa,
        'unidad_default': item.unidadDefault,
      });
      debugPrint('Inserción en control_materiales exitosa.');
    } catch (e) {
      _logSupabaseStatus('control_materiales', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMaterialControl(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('control_materiales', 'UPDATE');
      await _supabase.from('control_materiales').update({
        'nombre': item.nombre,
        'activo': item.activa,
        'unidad_default': item.unidadDefault,
      }).eq('id', item.id);
      debugPrint('Actualización en control_materiales exitosa.');
    } catch (e) {
      _logSupabaseStatus('control_materiales', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Otros Equipos
  @override
  Future<List<OperativeCatalogItem>> getOtrosEquipos() =>
      _getSyncList('otros_equipos', _otrosEquiposKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addOtroEquipo(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('otros_equipos', 'INSERT');
      await _supabase.from('otros_equipos').insert({'id': item.id, 'nombre': item.nombre, 'activo': item.activa});
      debugPrint('Inserción en otros_equipos exitosa.');
    } catch (e) {
      _logSupabaseStatus('otros_equipos', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateOtroEquipo(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('otros_equipos', 'UPDATE');
      await _supabase.from('otros_equipos').update({'nombre': item.nombre, 'activo': item.activa}).eq('id', item.id);
      debugPrint('Actualización en otros_equipos exitosa.');
    } catch (e) {
      _logSupabaseStatus('otros_equipos', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Camiones Internos
  @override
  Future<List<OperativeCatalogItem>> getCamionesInternos() =>
      _getSyncList('camiones_internos', _camionesInternosKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addCamionInterno(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('camiones_internos', 'INSERT');
      await _supabase.from('camiones_internos').insert({'id': item.id, 'nombre': item.nombre, 'activo': item.activa});
      debugPrint('Inserción en camiones_internos exitosa.');
    } catch (e) {
      _logSupabaseStatus('camiones_internos', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateCamionInterno(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('camiones_internos', 'UPDATE');
      await _supabase.from('camiones_internos').update({'nombre': item.nombre, 'activo': item.activa}).eq('id', item.id);
      debugPrint('Actualización en camiones_internos exitosa.');
    } catch (e) {
      _logSupabaseStatus('camiones_internos', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Funciones de Personal
  @override
  Future<List<OperativeCatalogItem>> getFuncionesPersonal() =>
      _getSyncList('funciones_personal', _funcionesPersonalKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addFuncionPersonal(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('funciones_personal', 'INSERT');
      await _supabase.from('funciones_personal').insert({'id': item.id, 'nombre': item.nombre, 'activo': item.activa});
      debugPrint('Inserción en funciones_personal exitosa.');
    } catch (e) {
      _logSupabaseStatus('funciones_personal', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateFuncionPersonal(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('funciones_personal', 'UPDATE');
      await _supabase.from('funciones_personal').update({'nombre': item.nombre, 'activo': item.activa}).eq('id', item.id);
      debugPrint('Actualización en funciones_personal exitosa.');
    } catch (e) {
      _logSupabaseStatus('funciones_personal', 'UPDATE_FAILED', e);
      rethrow;
    }
  }

  // Personal / Empleados
  @override
  Future<List<OperativeCatalogItem>> getEmpleados() =>
      _getSyncList('personal_empleados', _personalEmpleadosKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addEmpleado(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('personal_empleados', 'INSERT');
      await _supabase.from('personal_empleados').insert({
        'id': item.id,
        'nombre': item.nombre,
        'apellido': item.apellido,
        'identificador': item.identificador,
        'telefono': item.telefono,
        'activo': item.activa,
      });
      debugPrint('Inserción en personal_empleados exitosa.');
    } catch (e) {
      _logSupabaseStatus('personal_empleados', 'INSERT_FAILED', e);
      rethrow;
    }
  }

  @override
  Future<void> updateEmpleado(OperativeCatalogItem item) async {
    try {
      _logSupabaseStatus('personal_empleados', 'UPDATE');
      await _supabase.from('personal_empleados').update({
        'nombre': item.nombre,
        'apellido': item.apellido,
        'identificador': item.identificador,
        'telefono': item.telefono,
        'activo': item.activa,
      }).eq('id', item.id);
      debugPrint('Actualización en personal_empleados exitosa.');
    } catch (e) {
      _logSupabaseStatus('personal_empleados', 'UPDATE_FAILED', e);
      rethrow;
    }
  }
}
