import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../features/catalogs/domain/models/catalog_models.dart';
import '../../features/catalogs/domain/repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogRepository _repository;

  List<ObraModel> _obras = [];
  List<MaterialModel> _materiales = [];
  List<TransportistaModel> _transportistas = [];
  List<ChoferModel> _choferes = [];
  List<CamionModel> _camiones = [];
  List<RecibidorModel> _recibidores = [];

  // 6 nuevos catálogos operativos
  List<OperativeCatalogItem> _proveedores = [];
  List<OperativeCatalogItem> _maquinarias = [];
  List<OperativeCatalogItem> _materialesControl = [];
  List<OperativeCatalogItem> _otrosEquipos = [];
  List<OperativeCatalogItem> _camionesInternos = [];
  List<OperativeCatalogItem> _funcionesPersonal = [];
  List<OperativeCatalogItem> _empleados = [];

  bool _isLoading = false;

  CatalogProvider(this._repository) {
    loadAll();
  }

  bool get isLoading => _isLoading;

  List<ObraModel> get obras => _obras;
  List<MaterialModel> get materiales => _materiales;
  List<TransportistaModel> get transportistas => _transportistas;
  List<ChoferModel> get choferes => _choferes;
  List<CamionModel> get camiones => _camiones;
  List<RecibidorModel> get recibidores => _recibidores;

  // Getters para los 6 nuevos catálogos operativos
  List<OperativeCatalogItem> get proveedores => _proveedores;
  List<OperativeCatalogItem> get maquinarias => _maquinarias;
  List<OperativeCatalogItem> get materialesControl => _materialesControl;
  List<OperativeCatalogItem> get otrosEquipos => _otrosEquipos;
  List<OperativeCatalogItem> get camionesInternos => _camionesInternos;
  List<OperativeCatalogItem> get funcionesPersonal => _funcionesPersonal;
  List<OperativeCatalogItem> get empleados => _empleados;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    _obras = await _repository.getObras();
    _materiales = await _repository.getMateriales();
    _transportistas = await _repository.getTransportistas();
    _choferes = await _repository.getChoferes();
    _camiones = await _repository.getCamiones();
    _recibidores = await _repository.getRecibidores();

    // Cargar los 6 nuevos catálogos operativos
    _proveedores = await _repository.getProveedores();
    _maquinarias = await _repository.getMaquinarias();
    _materialesControl = await _repository.getMaterialesControl();
    _otrosEquipos = await _repository.getOtrosEquipos();
    _camionesInternos = await _repository.getCamionesInternos();
    _funcionesPersonal = await _repository.getFuncionesPersonal();
    _empleados = await _repository.getEmpleados();

    _isLoading = false;
    notifyListeners();
  }

  // Obras
  Future<void> addObra(String nombre) async {
    final obra = ObraModel(id: const Uuid().v4(), nombre: nombre);
    await _repository.addObra(obra);
    _obras.add(obra);
    notifyListeners();
  }

  Future<void> toggleObraStatus(ObraModel obra) async {
    final updated = ObraModel(id: obra.id, nombre: obra.nombre, activa: !obra.activa);
    await _repository.updateObra(updated);
    final index = _obras.indexWhere((o) => o.id == obra.id);
    if (index >= 0) {
      _obras[index] = updated;
      notifyListeners();
    }
  }

  // Materiales
  Future<void> addMaterial(String nombre) async {
    final material = MaterialModel(id: const Uuid().v4(), nombre: nombre);
    await _repository.addMaterial(material);
    _materiales.add(material);
    notifyListeners();
  }

  // Transportistas
  Future<void> addTransportista(String nombre) async {
    final transportista = TransportistaModel(id: const Uuid().v4(), nombre: nombre);
    await _repository.addTransportista(transportista);
    _transportistas.add(transportista);
    notifyListeners();
  }

  // Choferes
  Future<void> addChofer(String nombre) async {
    final chofer = ChoferModel(id: const Uuid().v4(), nombre: nombre);
    await _repository.addChofer(chofer);
    _choferes.add(chofer);
    notifyListeners();
  }

  // Camiones
  Future<void> addCamion(String patente) async {
    final camion = CamionModel(id: const Uuid().v4(), patente: patente);
    await _repository.addCamion(camion);
    _camiones.add(camion);
    notifyListeners();
  }

  // Recibidores
  Future<void> addRecibidor(String nombre) async {
    final recibidor = RecibidorModel(id: const Uuid().v4(), nombre: nombre);
    await _repository.addRecibidor(recibidor);
    _recibidores.add(recibidor);
    notifyListeners();
  }

  // --- MÉTODOS CRUD PARA LOS 6 NUEVOS CATÁLOGOS OPERATIVOS ---

  // Proveedores de Servicio
  Future<void> addProveedor(String nombre) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre);
    await _repository.addProveedor(item);
    _proveedores.add(item);
    notifyListeners();
  }

  Future<void> updateProveedor(OperativeCatalogItem updated) async {
    await _repository.updateProveedor(updated);
    final index = _proveedores.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _proveedores[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleProveedorStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(id: item.id, nombre: item.nombre, activa: !item.activa);
    await updateProveedor(updated);
  }

  // Maquinaria de Obra
  Future<void> addMaquinaria(String nombre) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre);
    await _repository.addMaquinaria(item);
    _maquinarias.add(item);
    notifyListeners();
  }

  Future<void> updateMaquinaria(OperativeCatalogItem updated) async {
    await _repository.updateMaquinaria(updated);
    final index = _maquinarias.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _maquinarias[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleMaquinariaStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(id: item.id, nombre: item.nombre, activa: !item.activa);
    await updateMaquinaria(updated);
  }

  // Control de Materiales
  Future<void> addMaterialControl(String nombre, {String? unidadDefault}) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre, unidadDefault: unidadDefault);
    await _repository.addMaterialControl(item);
    _materialesControl.add(item);
    notifyListeners();
  }

  Future<void> updateMaterialControl(OperativeCatalogItem updated) async {
    await _repository.updateMaterialControl(updated);
    final index = _materialesControl.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _materialesControl[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleMaterialControlStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(
      id: item.id,
      nombre: item.nombre,
      activa: !item.activa,
      unidadDefault: item.unidadDefault,
    );
    await updateMaterialControl(updated);
  }

  // Otros Equipos
  Future<void> addOtroEquipo(String nombre) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre);
    await _repository.addOtroEquipo(item);
    _otrosEquipos.add(item);
    notifyListeners();
  }

  Future<void> updateOtroEquipo(OperativeCatalogItem updated) async {
    await _repository.updateOtroEquipo(updated);
    final index = _otrosEquipos.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _otrosEquipos[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleOtroEquipoStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(id: item.id, nombre: item.nombre, activa: !item.activa);
    await updateOtroEquipo(updated);
  }

  // Camiones Internos
  Future<void> addCamionInterno(String nombre) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre);
    await _repository.addCamionInterno(item);
    _camionesInternos.add(item);
    notifyListeners();
  }

  Future<void> updateCamionInterno(OperativeCatalogItem updated) async {
    await _repository.updateCamionInterno(updated);
    final index = _camionesInternos.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _camionesInternos[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleCamionInternoStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(id: item.id, nombre: item.nombre, activa: !item.activa);
    await updateCamionInterno(updated);
  }

  // Funciones de Personal
  Future<void> addFuncionPersonal(String nombre) async {
    final item = OperativeCatalogItem(id: const Uuid().v4(), nombre: nombre);
    await _repository.addFuncionPersonal(item);
    _funcionesPersonal.add(item);
    notifyListeners();
  }

  Future<void> updateFuncionPersonal(OperativeCatalogItem updated) async {
    await _repository.updateFuncionPersonal(updated);
    final index = _funcionesPersonal.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _funcionesPersonal[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleFuncionPersonalStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(id: item.id, nombre: item.nombre, activa: !item.activa);
    await updateFuncionPersonal(updated);
  }

  // Personal / Empleados
  Future<void> addEmpleado(
    String nombre, {
    String? apellido,
    String? identificador,
    String? telefono,
  }) async {
    final item = OperativeCatalogItem(
      id: const Uuid().v4(),
      nombre: nombre,
      apellido: apellido,
      identificador: identificador,
      telefono: telefono,
    );
    await _repository.addEmpleado(item);
    _empleados.add(item);
    notifyListeners();
  }

  Future<void> updateEmpleado(OperativeCatalogItem updated) async {
    await _repository.updateEmpleado(updated);
    final index = _empleados.indexWhere((x) => x.id == updated.id);
    if (index >= 0) {
      _empleados[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleEmpleadoStatus(OperativeCatalogItem item) async {
    final updated = OperativeCatalogItem(
      id: item.id,
      nombre: item.nombre,
      apellido: item.apellido,
      identificador: item.identificador,
      telefono: item.telefono,
      activa: !item.activa,
    );
    await updateEmpleado(updated);
  }
}
