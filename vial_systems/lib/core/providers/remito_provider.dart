import 'package:flutter/material.dart';
import '../../features/remito/domain/models/remito_model.dart';
import '../../features/remito/domain/repositories/remito_repository.dart';

class RemitoProvider extends ChangeNotifier {
  final RemitoRepository _repository;

  List<RemitoModel> _remitos = [];
  bool _isLoading = false;

  RemitoProvider(this._repository) {
    loadRemitos();
  }

  List<RemitoModel> get remitos => _remitos;
  bool get isLoading => _isLoading;

  Future<void> loadRemitos() async {
    _isLoading = true;
    notifyListeners();

    _remitos = await _repository.getRemitos();
    
    // Sort by descending date
    _remitos.sort((a, b) => b.fecha.compareTo(a.fecha));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveRemito(RemitoModel remito) async {
    if (remito.estado != RemitoStatus.borrador) {
      final exists = _remitos.any((r) => r.numeroGuia == remito.numeroGuia && r.id != remito.id);
      if (exists) {
        throw Exception('El número de guía ${remito.numeroGuia} ya existe.');
      }
    }
    await _repository.saveRemito(remito);
    await loadRemitos();
  }

  Future<void> syncQueue() async {
    _isLoading = true;
    notifyListeners();

    for (var r in _remitos) {
      if (r.estado == RemitoStatus.listoParaEnviar || r.estado == RemitoStatus.error) {
        // Simular envio por red
        await Future.delayed(const Duration(seconds: 1));
        // Simular exito (80% prob) o fallo (20% prob)
        final isSuccess = DateTime.now().millisecond % 5 != 0;
        
        String? finalNumeroRemito = r.numeroRemito;
        if (isSuccess && finalNumeroRemito == null) {
          int maxNum = 0;
          for (var existing in _remitos) {
            if (existing.numeroRemito != null && existing.numeroRemito!.startsWith('R-')) {
              final numStr = existing.numeroRemito!.substring(2);
              final numVal = int.tryParse(numStr);
              if (numVal != null && numVal > maxNum) {
                maxNum = numVal;
              }
            }
          }
          finalNumeroRemito = 'R-${(maxNum + 1).toString().padLeft(5, '0')}';
        }
        
        final updated = RemitoModel(
          id: r.id,
          fecha: r.fecha,
          numeroGuia: r.numeroGuia,
          obraId: r.obraId,
          procedencia: r.procedencia,
          destino: r.destino,
          materialId: r.materialId,
          cantidadM3: r.cantidadM3,
          transportistaId: r.transportistaId,
          choferId: r.choferId,
          camionPatente: r.camionPatente,
          acopladoPatente: r.acopladoPatente,
          horaDescarga: r.horaDescarga,
          observaciones: r.observaciones,
          estado: isSuccess ? RemitoStatus.sincronizado : RemitoStatus.error,
          fotos: r.fotos,
          numeroRemito: finalNumeroRemito,
        );
        await _repository.saveRemito(updated);
      }
    }
    await loadRemitos();
  }

  Future<void> deleteRemito(String id) async {
    await _repository.deleteRemito(id);
    await loadRemitos();
  }
}
