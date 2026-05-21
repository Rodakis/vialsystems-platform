import '../models/catalog_models.dart';

abstract class CatalogRepository {
  Future<List<ObraModel>> getObras();
  Future<void> addObra(ObraModel obra);
  Future<void> updateObra(ObraModel obra);

  Future<List<MaterialModel>> getMateriales();
  Future<void> addMaterial(MaterialModel material);

  Future<List<TransportistaModel>> getTransportistas();
  Future<void> addTransportista(TransportistaModel transportista);

  Future<List<ChoferModel>> getChoferes();
  Future<void> addChofer(ChoferModel chofer);

  Future<List<CamionModel>> getCamiones();
  Future<void> addCamion(CamionModel camion);

  Future<List<RecibidorModel>> getRecibidores();
  Future<void> addRecibidor(RecibidorModel recibidor);

  // Proveedores de Servicio
  Future<List<OperativeCatalogItem>> getProveedores();
  Future<void> addProveedor(OperativeCatalogItem item);
  Future<void> updateProveedor(OperativeCatalogItem item);

  // Maquinaria de Obra
  Future<List<OperativeCatalogItem>> getMaquinarias();
  Future<void> addMaquinaria(OperativeCatalogItem item);
  Future<void> updateMaquinaria(OperativeCatalogItem item);

  // Control de Materiales
  Future<List<OperativeCatalogItem>> getMaterialesControl();
  Future<void> addMaterialControl(OperativeCatalogItem item);
  Future<void> updateMaterialControl(OperativeCatalogItem item);

  // Otros Equipos
  Future<List<OperativeCatalogItem>> getOtrosEquipos();
  Future<void> addOtroEquipo(OperativeCatalogItem item);
  Future<void> updateOtroEquipo(OperativeCatalogItem item);

  // Camiones Internos
  Future<List<OperativeCatalogItem>> getCamionesInternos();
  Future<void> addCamionInterno(OperativeCatalogItem item);
  Future<void> updateCamionInterno(OperativeCatalogItem item);

  // Funciones de Personal
  Future<List<OperativeCatalogItem>> getFuncionesPersonal();
  Future<void> addFuncionPersonal(OperativeCatalogItem item);
  Future<void> updateFuncionPersonal(OperativeCatalogItem item);
}
