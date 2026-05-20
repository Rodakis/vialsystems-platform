import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../features/remito/domain/models/remito_model.dart';
import '../../features/remito/domain/repositories/remito_repository.dart';

class RemitoProvider extends ChangeNotifier {
  final RemitoRepository _repository;

  List<RemitoModel> _remitos = [];
  List<RemitoModel> _adminRemitos = [];
  bool _isLoading = false;

  RemitoProvider(this._repository) {
    loadRemitos();
  }

  List<RemitoModel> get remitos => _remitos;
  List<RemitoModel> get adminRemitos => _adminRemitos;
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

  Future<void> loadAdminRemitos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('remitos')
          .select()
          .order('fecha', ascending: false);

      _adminRemitos = (response as List).map((row) {
        return RemitoModel(
          id: row['id'],
          fecha: DateTime.parse(row['fecha']),
          numeroGuia: row['numero_guia'],
          obraId: row['obra_id'],
          procedencia: row['procedencia'],
          destino: row['destino'],
          materialId: row['material_id'],
          cantidadM3: double.parse(row['cantidad_m3'].toString()),
          transportistaId: row['transportista_id'],
          choferId: row['chofer_id'],
          camionPatente: row['camion_patente'],
          acopladoPatente: row['acoplado_patente'],
          horaDescarga: DateTime.parse(row['hora_descarga']),
          observaciones: row['observaciones'] ?? '',
          estado: RemitoStatus.sincronizado,
          fotos: (row['fotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          numeroRemito: row['numero_remito_seq'] != null 
              ? 'R-${row['numero_remito_seq'].toString().padLeft(5, '0')}' 
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching admin remitos: $e');
    }

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

    final supabase = Supabase.instance.client;

    for (var r in _remitos) {
      if (r.estado == RemitoStatus.listoParaEnviar || r.estado == RemitoStatus.error) {
        try {
          String validId = r.id;
          bool idChanged = false;
          if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(validId)) {
            validId = const Uuid().v4();
            idChanged = true;
          }

          List<String> uploadedFotos = [];
          
          for (String fotoPath in r.fotos) {
            if (fotoPath.startsWith('http') && !fotoPath.startsWith('blob:')) {
              uploadedFotos.add(fotoPath);
              continue;
            }
            
            if (kIsWeb) {
              uploadedFotos.add(fotoPath);
              continue;
            }
            
            final fileName = '${validId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(fotoPath);
            await supabase.storage.from('fotos_remitos').upload(fileName, file);
            final publicUrl = supabase.storage.from('fotos_remitos').getPublicUrl(fileName);
            uploadedFotos.add(publicUrl);
          }
          
          final insertData = {
            'id': validId,
            'fecha': r.fecha.toIso8601String(),
            'numero_guia': r.numeroGuia,
            'obra_id': r.obraId,
            'procedencia': r.procedencia,
            'destino': r.destino,
            'material_id': r.materialId,
            'cantidad_m3': r.cantidadM3,
            'transportista_id': r.transportistaId,
            'chofer_id': r.choferId,
            'camion_patente': r.camionPatente,
            'acoplado_patente': r.acopladoPatente,
            'hora_descarga': r.horaDescarga.toIso8601String(),
            'observaciones': r.observaciones,
            'estado': 'sincronizado',
            'fotos': uploadedFotos,
          };

          // Usar upsert para evitar errores por duplicado si se reintenta y ya existía
          final response = await supabase.from('remitos').upsert(insertData).select('numero_remito_seq').single();
          
          final seqNum = response['numero_remito_seq'] as int;
          final finalNumeroRemito = 'R-${seqNum.toString().padLeft(5, '0')}';
          
          final updated = RemitoModel(
            id: validId,
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
            estado: RemitoStatus.sincronizado,
            fotos: uploadedFotos,
            numeroRemito: finalNumeroRemito,
          );
          
          if (idChanged) {
            await _repository.deleteRemito(r.id);
          }
          await _repository.saveRemito(updated);
          
        } catch (e) {
          debugPrint('Error sincronizando remito ${r.id}: $e');
          final updatedError = RemitoModel(
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
            estado: RemitoStatus.error,
            fotos: r.fotos,
            numeroRemito: r.numeroRemito,
          );
          await _repository.saveRemito(updatedError);
        }
      }
    }
    await loadRemitos();
  }

  Future<void> deleteRemito(String id) async {
    await _repository.deleteRemito(id);
    await loadRemitos();
  }
}
