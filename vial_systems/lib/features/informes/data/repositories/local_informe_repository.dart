import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/informe_diario_model.dart';
import '../../domain/models/informe_diario_trabajo_model.dart';
import '../../domain/repositories/informe_repository.dart';

class LocalInformeRepository implements InformeRepository {
  static const String _diariosKey = 'informes_diarios_data';
  static const String _trabajoKey = 'informes_diarios_trabajo_data';

  @override
  Future<List<InformeDiarioModel>> getInformesDiarios() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_diariosKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => InformeDiarioModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveInformeDiario(InformeDiarioModel informe) async {
    final list = await getInformesDiarios();
    final index = list.indexWhere((r) => r.id == informe.id);
    if (index >= 0) {
      list[index] = informe;
    } else {
      list.add(informe);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diariosKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  @override
  Future<void> deleteInformeDiario(String id) async {
    final list = await getInformesDiarios();
    list.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diariosKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  @override
  Future<List<InformeDiarioTrabajoModel>> getInformesDiariosTrabajo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_trabajoKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => InformeDiarioTrabajoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveInformeDiarioTrabajo(InformeDiarioTrabajoModel informe) async {
    final list = await getInformesDiariosTrabajo();
    final index = list.indexWhere((r) => r.id == informe.id);
    if (index >= 0) {
      list[index] = informe;
    } else {
      list.add(informe);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trabajoKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  @override
  Future<void> deleteInformeDiarioTrabajo(String id) async {
    final list = await getInformesDiariosTrabajo();
    list.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trabajoKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }
}
