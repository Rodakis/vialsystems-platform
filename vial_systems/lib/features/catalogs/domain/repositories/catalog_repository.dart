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
}
