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
}
