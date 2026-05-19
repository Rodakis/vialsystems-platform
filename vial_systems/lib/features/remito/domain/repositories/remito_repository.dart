import '../models/remito_model.dart';

abstract class RemitoRepository {
  Future<List<RemitoModel>> getRemitos();
  Future<void> saveRemito(RemitoModel remito);
  Future<void> deleteRemito(String id);
}
