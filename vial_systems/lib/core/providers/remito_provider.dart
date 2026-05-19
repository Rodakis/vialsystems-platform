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
    await _repository.saveRemito(remito);
    await loadRemitos();
  }

  Future<void> deleteRemito(String id) async {
    await _repository.deleteRemito(id);
    await loadRemitos();
  }
}
