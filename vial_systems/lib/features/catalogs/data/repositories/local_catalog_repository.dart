import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repository.dart';

class LocalCatalogRepository implements CatalogRepository {
  final String _obrasKey = 'obras_data';
  final String _materialesKey = 'materiales_data';
  final String _transportistasKey = 'transportistas_data';
  final String _choferesKey = 'choferes_data';
  final String _camionesKey = 'camiones_data';
  final String _recibidoresKey = 'recibidores_data';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<T>> _getList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await _prefs;
    final String? data = prefs.getString(key);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList<T>(String key, List<T> list, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await _prefs;
    final String data = jsonEncode(list.map(toJson).toList());
    await prefs.setString(key, data);
  }

  // Obras
  @override
  Future<List<ObraModel>> getObras() => _getList(_obrasKey, ObraModel.fromJson);
  
  @override
  Future<void> addObra(ObraModel obra) async {
    final list = await getObras();
    list.add(obra);
    await _saveList(_obrasKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateObra(ObraModel obra) async {
    final list = await getObras();
    final index = list.indexWhere((o) => o.id == obra.id);
    if (index >= 0) {
      list[index] = obra;
      await _saveList(_obrasKey, list, (o) => o.toJson());
    }
  }

  // Materiales
  @override
  Future<List<MaterialModel>> getMateriales() => _getList(_materialesKey, MaterialModel.fromJson);

  @override
  Future<void> addMaterial(MaterialModel material) async {
    final list = await getMateriales();
    list.add(material);
    await _saveList(_materialesKey, list, (m) => m.toJson());
  }

  // Transportistas
  @override
  Future<List<TransportistaModel>> getTransportistas() => _getList(_transportistasKey, TransportistaModel.fromJson);

  @override
  Future<void> addTransportista(TransportistaModel transportista) async {
    final list = await getTransportistas();
    list.add(transportista);
    await _saveList(_transportistasKey, list, (t) => t.toJson());
  }

  // Choferes
  @override
  Future<List<ChoferModel>> getChoferes() => _getList(_choferesKey, ChoferModel.fromJson);

  @override
  Future<void> addChofer(ChoferModel chofer) async {
    final list = await getChoferes();
    list.add(chofer);
    await _saveList(_choferesKey, list, (c) => c.toJson());
  }

  // Camiones
  @override
  Future<List<CamionModel>> getCamiones() => _getList(_camionesKey, CamionModel.fromJson);

  @override
  Future<void> addCamion(CamionModel camion) async {
    final list = await getCamiones();
    list.add(camion);
    await _saveList(_camionesKey, list, (c) => c.toJson());
  }

  // Recibidores
  @override
  Future<List<RecibidorModel>> getRecibidores() => _getList(_recibidoresKey, RecibidorModel.fromJson);

  @override
  Future<void> addRecibidor(RecibidorModel recibidor) async {
    final list = await getRecibidores();
    list.add(recibidor);
    await _saveList(_recibidoresKey, list, (r) => r.toJson());
  }
}
