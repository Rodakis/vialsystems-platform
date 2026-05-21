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
  final String _proveedoresKey = 'proveedores_data';
  final String _maquinariasKey = 'maquinarias_data';
  final String _materialesControlKey = 'materiales_control_data';
  final String _otrosEquiposKey = 'otros_equipos_data';
  final String _camionesInternosKey = 'camiones_internos_data';
  final String _funcionesPersonalKey = 'funciones_personal_data';

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

  // Proveedores de Servicio
  @override
  Future<List<OperativeCatalogItem>> getProveedores() => _getList(_proveedoresKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addProveedor(OperativeCatalogItem item) async {
    final list = await getProveedores();
    list.add(item);
    await _saveList(_proveedoresKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateProveedor(OperativeCatalogItem item) async {
    final list = await getProveedores();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_proveedoresKey, list, (o) => o.toJson());
    }
  }

  // Maquinaria de Obra
  @override
  Future<List<OperativeCatalogItem>> getMaquinarias() => _getList(_maquinariasKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaquinaria(OperativeCatalogItem item) async {
    final list = await getMaquinarias();
    list.add(item);
    await _saveList(_maquinariasKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateMaquinaria(OperativeCatalogItem item) async {
    final list = await getMaquinarias();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_maquinariasKey, list, (o) => o.toJson());
    }
  }

  // Control de Materiales
  @override
  Future<List<OperativeCatalogItem>> getMaterialesControl() => _getList(_materialesControlKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addMaterialControl(OperativeCatalogItem item) async {
    final list = await getMaterialesControl();
    list.add(item);
    await _saveList(_materialesControlKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateMaterialControl(OperativeCatalogItem item) async {
    final list = await getMaterialesControl();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_materialesControlKey, list, (o) => o.toJson());
    }
  }

  // Otros Equipos
  @override
  Future<List<OperativeCatalogItem>> getOtrosEquipos() => _getList(_otrosEquiposKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addOtroEquipo(OperativeCatalogItem item) async {
    final list = await getOtrosEquipos();
    list.add(item);
    await _saveList(_otrosEquiposKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateOtroEquipo(OperativeCatalogItem item) async {
    final list = await getOtrosEquipos();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_otrosEquiposKey, list, (o) => o.toJson());
    }
  }

  // Camiones Internos
  @override
  Future<List<OperativeCatalogItem>> getCamionesInternos() => _getList(_camionesInternosKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addCamionInterno(OperativeCatalogItem item) async {
    final list = await getCamionesInternos();
    list.add(item);
    await _saveList(_camionesInternosKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateCamionInterno(OperativeCatalogItem item) async {
    final list = await getCamionesInternos();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_camionesInternosKey, list, (o) => o.toJson());
    }
  }

  // Funciones de Personal
  @override
  Future<List<OperativeCatalogItem>> getFuncionesPersonal() => _getList(_funcionesPersonalKey, OperativeCatalogItem.fromJson);

  @override
  Future<void> addFuncionPersonal(OperativeCatalogItem item) async {
    final list = await getFuncionesPersonal();
    list.add(item);
    await _saveList(_funcionesPersonalKey, list, (o) => o.toJson());
  }

  @override
  Future<void> updateFuncionPersonal(OperativeCatalogItem item) async {
    final list = await getFuncionesPersonal();
    final index = list.indexWhere((o) => o.id == item.id);
    if (index >= 0) {
      list[index] = item;
      await _saveList(_funcionesPersonalKey, list, (o) => o.toJson());
    }
  }
}
