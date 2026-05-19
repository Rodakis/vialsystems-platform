import 'package:flutter/material.dart';
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

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    _obras = await _repository.getObras();
    _materiales = await _repository.getMateriales();
    _transportistas = await _repository.getTransportistas();
    _choferes = await _repository.getChoferes();
    _camiones = await _repository.getCamiones();
    _recibidores = await _repository.getRecibidores();

    _isLoading = false;
    notifyListeners();
  }

  // Obras
  Future<void> addObra(String nombre) async {
    final obra = ObraModel(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre);
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
    final material = MaterialModel(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre);
    await _repository.addMaterial(material);
    _materiales.add(material);
    notifyListeners();
  }

  // Transportistas
  Future<void> addTransportista(String nombre) async {
    final transportista = TransportistaModel(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre);
    await _repository.addTransportista(transportista);
    _transportistas.add(transportista);
    notifyListeners();
  }

  // Choferes
  Future<void> addChofer(String nombre) async {
    final chofer = ChoferModel(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre);
    await _repository.addChofer(chofer);
    _choferes.add(chofer);
    notifyListeners();
  }

  // Camiones
  Future<void> addCamion(String patente) async {
    final camion = CamionModel(id: DateTime.now().millisecondsSinceEpoch.toString(), patente: patente);
    await _repository.addCamion(camion);
    _camiones.add(camion);
    notifyListeners();
  }

  // Recibidores
  Future<void> addRecibidor(String nombre) async {
    final recibidor = RecibidorModel(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre);
    await _repository.addRecibidor(recibidor);
    _recibidores.add(recibidor);
    notifyListeners();
  }
}
