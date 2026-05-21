import '../models/informe_diario_model.dart';
import '../models/informe_diario_trabajo_model.dart';

abstract class InformeRepository {
  Future<List<InformeDiarioModel>> getInformesDiarios();
  Future<void> saveInformeDiario(InformeDiarioModel informe);
  Future<void> deleteInformeDiario(String id);

  Future<List<InformeDiarioTrabajoModel>> getInformesDiariosTrabajo();
  Future<void> saveInformeDiarioTrabajo(InformeDiarioTrabajoModel informe);
  Future<void> deleteInformeDiarioTrabajo(String id);
}
