import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/remito_model.dart';
import '../../domain/repositories/remito_repository.dart';

class LocalRemitoRepository implements RemitoRepository {
  static const String _remitosKey = 'remitos_data';

  @override
  Future<List<RemitoModel>> getRemitos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_remitosKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => RemitoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveRemito(RemitoModel remito) async {
    final list = await getRemitos();
    final index = list.indexWhere((r) => r.id == remito.id);
    if (index >= 0) {
      list[index] = remito;
    } else {
      list.add(remito);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remitosKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  @override
  Future<void> deleteRemito(String id) async {
    final list = await getRemitos();
    list.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remitosKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }
}
