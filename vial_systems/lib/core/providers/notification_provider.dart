import 'package:flutter/material.dart';
import '../../features/remito/domain/models/remito_model.dart';
import '../../features/informes/domain/models/informe_diario_model.dart';
import '../../features/informes/domain/models/informe_diario_trabajo_model.dart';
import '../../features/auth/domain/models/user_model.dart';
import 'remito_provider.dart';
import 'informe_provider.dart';
import 'catalog_provider.dart';
import 'auth_provider.dart';

enum NotificationSeverity {
  error,   // Red 🛑
  warning, // Yellow ⚠️
  info,    // Blue 📅
}

enum NotificationType {
  draft,
  syncError,
  missingReport,
}

enum DocumentType {
  remito,
  informeDiario,
  diarioTrabajo,
}

class NotificationAlert {
  final String id;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final NotificationType type;
  final DocumentType documentType;
  final dynamic document; // RemitoModel, InformeDiarioModel, InformeDiarioTrabajoModel, or ObraModel

  NotificationAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.type,
    required this.documentType,
    required this.document,
  });
}

class NotificationProvider extends ChangeNotifier {
  RemitoProvider _remitoProvider;
  InformeProvider _informeProvider;
  CatalogProvider _catalogProvider;
  AuthProvider _authProvider;

  List<NotificationAlert> _alerts = [];
  bool _isSyncing = false;

  NotificationProvider(this._remitoProvider, this._informeProvider, this._catalogProvider, this._authProvider) {
    _remitoProvider.addListener(_onProvidersChanged);
    _informeProvider.addListener(_onProvidersChanged);
    _catalogProvider.addListener(_onProvidersChanged);
    _authProvider.addListener(_onProvidersChanged);
    _calculateNotifications();
  }

  List<NotificationAlert> get alerts => _alerts;
  bool get isSyncing => _isSyncing;
  
  int get activeAlertsCount => _alerts.length;
  int get errorAlertsCount => _alerts.where((a) => a.severity == NotificationSeverity.error).length;
  int get warningAlertsCount => _alerts.where((a) => a.severity == NotificationSeverity.warning).length;
  int get infoAlertsCount => _alerts.where((a) => a.severity == NotificationSeverity.info).length;

  void updateProviders(
    RemitoProvider remitoProvider,
    InformeProvider informeProvider,
    CatalogProvider catalogProvider,
    AuthProvider authProvider,
  ) {
    _remitoProvider.removeListener(_onProvidersChanged);
    _informeProvider.removeListener(_onProvidersChanged);
    _catalogProvider.removeListener(_onProvidersChanged);
    _authProvider.removeListener(_onProvidersChanged);

    _remitoProvider = remitoProvider;
    _informeProvider = informeProvider;
    _catalogProvider = catalogProvider;
    _authProvider = authProvider;

    _remitoProvider.addListener(_onProvidersChanged);
    _informeProvider.addListener(_onProvidersChanged);
    _catalogProvider.addListener(_onProvidersChanged);
    _authProvider.addListener(_onProvidersChanged);

    _calculateNotifications();
    notifyListeners();
  }

  void _onProvidersChanged() {
    _calculateNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _remitoProvider.removeListener(_onProvidersChanged);
    _informeProvider.removeListener(_onProvidersChanged);
    _catalogProvider.removeListener(_onProvidersChanged);
    _authProvider.removeListener(_onProvidersChanged);
    super.dispose();
  }

  // Mandatory checks for Remito draft completeness
  bool _isRemitoComplete(RemitoModel r) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isObraUuid = r.obraId != null && uuidRegex.hasMatch(r.obraId!);
    final isMaterialUuid = r.materialId != null && uuidRegex.hasMatch(r.materialId!);
    final isTransportistaUuid = r.transportistaId != null && uuidRegex.hasMatch(r.transportistaId!);
    final isChoferUuid = r.choferId != null && uuidRegex.hasMatch(r.choferId!);

    return r.numeroGuia.trim().isNotEmpty &&
        isObraUuid &&
        r.procedencia.trim().isNotEmpty &&
        r.destino.trim().isNotEmpty &&
        isMaterialUuid &&
        r.cantidadM3 > 0 &&
        isTransportistaUuid &&
        isChoferUuid &&
        r.camionPatente != null && r.camionPatente!.trim().isNotEmpty &&
        r.fotos.isNotEmpty;
  }

  // Mandatory checks for Informe Diario draft completeness
  bool _isInformeDiarioComplete(InformeDiarioModel inf) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isObraUuid = inf.obraId != null && uuidRegex.hasMatch(inf.obraId!);
    return isObraUuid && inf.fotos.isNotEmpty;
  }

  // Mandatory checks for Diario de Trabajo draft completeness
  bool _isDiarioTrabajoComplete(InformeDiarioTrabajoModel trab) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isObraUuid = trab.obraId != null && uuidRegex.hasMatch(trab.obraId!);

    final hasValidPersonal = trab.personal.isNotEmpty && trab.personal.every((p) => 
      p.empleadoId.isNotEmpty && 
      p.funcionId.isNotEmpty && 
      p.horasTrabajadas > 0 && 
      p.horasTrabajadas <= 24
    );

    return isObraUuid && trab.fotos.isNotEmpty && hasValidPersonal;
  }

  void _calculateNotifications() {
    final List<NotificationAlert> tempAlerts = [];

    // 1. Process Remitos
    for (var r in _remitoProvider.remitos) {
      if (r.estado == RemitoStatus.borrador) {
        final completeText = _isRemitoComplete(r) ? ' (Listo para enviar)' : ' (Borrador incompleto)';
        tempAlerts.add(NotificationAlert(
          id: 'remito_draft_${r.id}',
          title: 'Borrador de Remito$completeText',
          message: 'Guía: ${r.numeroGuia} - Destino: ${r.destino.isNotEmpty ? r.destino : "Sin destino"}',
          severity: NotificationSeverity.warning,
          type: NotificationType.draft,
          documentType: DocumentType.remito,
          document: r,
        ));
      } else if (r.estado == RemitoStatus.error) {
        final errorMsg = _remitoProvider.syncErrors[r.id] ?? 
            'Error de red o conexión al intentar subir el remito.';
        tempAlerts.add(NotificationAlert(
          id: 'remito_error_${r.id}',
          title: 'Error de Sincronización (Remito)',
          message: 'Guía: ${r.numeroGuia} - $errorMsg',
          severity: NotificationSeverity.error,
          type: NotificationType.syncError,
          documentType: DocumentType.remito,
          document: r,
        ));
      }
    }

    // 2. Process Informes Diarios
    for (var inf in _informeProvider.informesDiarios) {
      if (inf.estado == RemitoStatus.borrador) {
        final completeText = _isInformeDiarioComplete(inf) ? ' (Listo para enviar)' : ' (Borrador incompleto)';
        tempAlerts.add(NotificationAlert(
          id: 'informe_diario_draft_${inf.id}',
          title: 'Borrador de Informe Diario$completeText',
          message: 'Fecha: ${inf.fecha.day}/${inf.fecha.month}/${inf.fecha.year} - Obra: ${inf.obraId != null ? "Registrada" : "Sin asignar"}',
          severity: NotificationSeverity.warning,
          type: NotificationType.draft,
          documentType: DocumentType.informeDiario,
          document: inf,
        ));
      } else if (inf.estado == RemitoStatus.error) {
        final errorMsg = _informeProvider.syncErrors[inf.id] ?? 
            'Error de red o conexión al intentar subir el informe.';
        tempAlerts.add(NotificationAlert(
          id: 'informe_diario_error_${inf.id}',
          title: 'Error de Sincronización (Informe Diario)',
          message: 'Fecha: ${inf.fecha.day}/${inf.fecha.month}/${inf.fecha.year} - $errorMsg',
          severity: NotificationSeverity.error,
          type: NotificationType.syncError,
          documentType: DocumentType.informeDiario,
          document: inf,
        ));
      }
    }

    // 3. Process Diarios de Trabajo
    for (var trab in _informeProvider.informesDiariosTrabajo) {
      if (trab.estado == RemitoStatus.borrador) {
        final completeText = _isDiarioTrabajoComplete(trab) ? ' (Listo para enviar)' : ' (Borrador incompleto)';
        tempAlerts.add(NotificationAlert(
          id: 'diario_trabajo_draft_${trab.id}',
          title: 'Borrador de Diario de Trabajo$completeText',
          message: 'Tareas: ${trab.tareasRealizadas.isNotEmpty ? trab.tareasRealizadas : "Sin definir"}',
          severity: NotificationSeverity.warning,
          type: NotificationType.draft,
          documentType: DocumentType.diarioTrabajo,
          document: trab,
        ));
      } else if (trab.estado == RemitoStatus.error) {
        final errorMsg = _informeProvider.syncErrors[trab.id] ?? 
            'Error de red o conexión al intentar subir el diario de trabajo.';
        tempAlerts.add(NotificationAlert(
          id: 'diario_trabajo_error_${trab.id}',
          title: 'Error de Sincronización (Diario de Trabajo)',
          message: 'Fecha: ${trab.fecha.day}/${trab.fecha.month}/${trab.fecha.year} - $errorMsg',
          severity: NotificationSeverity.error,
          type: NotificationType.syncError,
          documentType: DocumentType.diarioTrabajo,
          document: trab,
        ));
      }
    }

    // 4. Scan active Obras for today's missing reports (ONLY FOR ADMINISTRATORS!)
    final isAdmin = _authProvider.currentUser?.role == UserRole.administrador || 
                    _authProvider.currentUser?.role == UserRole.oficina;

    if (isAdmin) {
      final today = DateTime.now();
      for (var obra in _catalogProvider.obras) {
        if (obra.activa) {
          // Check if today has a registered InformeDiario for this obra
          final hasDiarioToday = _informeProvider.informesDiarios.any((inf) =>
              inf.obraId == obra.id &&
              inf.fecha.year == today.year &&
              inf.fecha.month == today.month &&
              inf.fecha.day == today.day
          );

          if (!hasDiarioToday) {
            tempAlerts.add(NotificationAlert(
              id: 'missing_diario_${obra.id}_${today.year}_${today.month}_${today.day}',
              title: 'Parte Diario Faltante',
              message: 'Falta registrar el Informe Diario de hoy en la Obra: ${obra.nombre}',
              severity: NotificationSeverity.info,
              type: NotificationType.missingReport,
              documentType: DocumentType.informeDiario,
              document: obra,
            ));
          }

          // Check if today has a registered InformeDiarioTrabajo for this obra
          final hasTrabajoToday = _informeProvider.informesDiariosTrabajo.any((trab) =>
              trab.obraId == obra.id &&
              trab.fecha.year == today.year &&
              trab.fecha.month == today.month &&
              trab.fecha.day == today.day
          );

          if (!hasTrabajoToday) {
            tempAlerts.add(NotificationAlert(
              id: 'missing_trabajo_${obra.id}_${today.year}_${today.month}_${today.day}',
              title: 'Diario de Trabajo Faltante',
              message: 'Falta registrar el Diario de Trabajo de hoy en la Obra: ${obra.nombre}',
              severity: NotificationSeverity.info,
              type: NotificationType.missingReport,
              documentType: DocumentType.diarioTrabajo,
              document: obra,
            ));
          }
        }
      }
    }

    _alerts = tempAlerts;
  }

  Future<void> syncAll(BuildContext context) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final syncableRemitos = <RemitoModel>[];
      final incompleteRemitos = <RemitoModel>[];
      for (var r in _remitoProvider.remitos) {
        if (r.estado == RemitoStatus.listoParaEnviar || r.estado == RemitoStatus.error) {
          syncableRemitos.add(r);
        } else if (r.estado == RemitoStatus.borrador) {
          if (_isRemitoComplete(r)) {
            syncableRemitos.add(r);
          } else {
            incompleteRemitos.add(r);
          }
        }
      }

      final syncableDiarios = <InformeDiarioModel>[];
      final incompleteDiarios = <InformeDiarioModel>[];
      for (var inf in _informeProvider.informesDiarios) {
        if (inf.estado == RemitoStatus.listoParaEnviar || inf.estado == RemitoStatus.error) {
          syncableDiarios.add(inf);
        } else if (inf.estado == RemitoStatus.borrador) {
          if (_isInformeDiarioComplete(inf)) {
            syncableDiarios.add(inf);
          } else {
            incompleteDiarios.add(inf);
          }
        }
      }

      final syncableTrabajos = <InformeDiarioTrabajoModel>[];
      final incompleteTrabajos = <InformeDiarioTrabajoModel>[];
      for (var trab in _informeProvider.informesDiariosTrabajo) {
        if (trab.estado == RemitoStatus.listoParaEnviar || trab.estado == RemitoStatus.error) {
          syncableTrabajos.add(trab);
        } else if (trab.estado == RemitoStatus.borrador) {
          if (_isDiarioTrabajoComplete(trab)) {
            syncableTrabajos.add(trab);
          } else {
            incompleteTrabajos.add(trab);
          }
        }
      }

      final totalSyncable = syncableRemitos.length + syncableDiarios.length + syncableTrabajos.length;
      final totalIncomplete = incompleteRemitos.length + incompleteDiarios.length + incompleteTrabajos.length;

      if (totalSyncable == 0) {
        _isSyncing = false;
        notifyListeners();

        if (totalIncomplete > 0) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              backgroundColor: Colors.orange.shade800,
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hay borradores incompletos que deben completarse antes de sincronizar.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              backgroundColor: Colors.blue.shade800,
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay elementos listos para sincronizar.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }

      for (var r in syncableRemitos) {
        if (r.estado == RemitoStatus.borrador) {
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
            estado: RemitoStatus.listoParaEnviar,
            fotos: r.fotos,
            numeroRemito: r.numeroRemito,
          );
          await _remitoProvider.saveRemito(updated);
        }
      }

      for (var inf in syncableDiarios) {
        if (inf.estado == RemitoStatus.borrador) {
          final updated = InformeDiarioModel(
            id: inf.id,
            fecha: inf.fecha,
            obraId: inf.obraId,
            usuarioId: inf.usuarioId,
            usuarioName: inf.usuarioName,
            proveedoresIds: inf.proveedoresIds,
            maquinariasIds: inf.maquinariasIds,
            materiales: inf.materiales,
            equiposIds: inf.equiposIds,
            camionesIds: inf.camionesIds,
            observaciones: inf.observaciones,
            estado: RemitoStatus.listoParaEnviar,
            fotos: inf.fotos,
          );
          await _informeProvider.saveInformeDiario(updated);
        }
      }

      for (var trab in syncableTrabajos) {
        if (trab.estado == RemitoStatus.borrador) {
          final updated = InformeDiarioTrabajoModel(
            id: trab.id,
            fecha: trab.fecha,
            obraId: trab.obraId,
            usuarioId: trab.usuarioId,
            usuarioName: trab.usuarioName,
            tareasRealizadas: trab.tareasRealizadas,
            horasTrabajadas: trab.horasTrabajadas,
            personal: trab.personal,
            maquinariaIds: trab.maquinariaIds,
            observaciones: trab.observaciones,
            estado: RemitoStatus.listoParaEnviar,
            fotos: trab.fotos,
          );
          await _informeProvider.saveInformeDiarioTrabajo(updated);
        }
      }

      await Future.wait([
        _remitoProvider.syncQueue(),
        _informeProvider.syncQueue(),
      ]);

      int synchronizedCount = 0;
      int failedCount = 0;

      for (var r in syncableRemitos) {
        final current = _remitoProvider.remitos.firstWhere((item) => item.id == r.id, orElse: () => r);
        if (current.estado == RemitoStatus.sincronizado) {
          synchronizedCount++;
        } else if (current.estado == RemitoStatus.error) {
          failedCount++;
        }
      }

      for (var inf in syncableDiarios) {
        final current = _informeProvider.informesDiarios.firstWhere((item) => item.id == inf.id, orElse: () => inf);
        if (current.estado == RemitoStatus.sincronizado) {
          synchronizedCount++;
        } else if (current.estado == RemitoStatus.error) {
          failedCount++;
        }
      }

      for (var trab in syncableTrabajos) {
        final current = _informeProvider.informesDiariosTrabajo.firstWhere((item) => item.id == trab.id, orElse: () => trab);
        if (current.estado == RemitoStatus.sincronizado) {
          synchronizedCount++;
        } else if (current.estado == RemitoStatus.error) {
          failedCount++;
        }
      }

      _calculateNotifications();

      final isSuccess = failedCount == 0 && totalIncomplete == 0;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: isSuccess ? Colors.green.shade800 : Colors.orange.shade800,
          content: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle_outline : Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSuccess 
                      ? '¡Sincronización exitosa de todos los pendientes!'
                      : 'Sincronizados: $synchronizedCount | Fallidos: $failedCount | Borradores incompletos: $totalIncomplete',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.shade800,
          content: Text(
            'Error al sincronizar: $e',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> retryDocument(BuildContext context, NotificationAlert alert) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      if (alert.documentType == DocumentType.remito) {
        final updated = RemitoModel(
          id: alert.document.id,
          fecha: alert.document.fecha,
          numeroGuia: alert.document.numeroGuia,
          obraId: alert.document.obraId,
          procedencia: alert.document.procedencia,
          destino: alert.document.destino,
          materialId: alert.document.materialId,
          cantidadM3: alert.document.cantidadM3,
          transportistaId: alert.document.transportistaId,
          choferId: alert.document.choferId,
          camionPatente: alert.document.camionPatente,
          acopladoPatente: alert.document.acopladoPatente,
          horaDescarga: alert.document.horaDescarga,
          observaciones: alert.document.observaciones,
          estado: RemitoStatus.listoParaEnviar,
          fotos: alert.document.fotos,
          numeroRemito: alert.document.numeroRemito,
        );
        await _remitoProvider.saveRemito(updated);
        await _remitoProvider.syncQueue();
      } else if (alert.documentType == DocumentType.informeDiario) {
        final updated = InformeDiarioModel(
          id: alert.document.id,
          fecha: alert.document.fecha,
          obraId: alert.document.obraId,
          usuarioId: alert.document.usuarioId,
          usuarioName: alert.document.usuarioName,
          proveedoresIds: alert.document.proveedoresIds,
          maquinariasIds: alert.document.maquinariasIds,
          materiales: alert.document.materiales,
          equiposIds: alert.document.equiposIds,
          camionesIds: alert.document.camionesIds,
          observaciones: alert.document.observaciones,
          estado: RemitoStatus.listoParaEnviar,
          fotos: alert.document.fotos,
        );
        await _informeProvider.saveInformeDiario(updated);
        await _informeProvider.syncQueue();
      } else if (alert.documentType == DocumentType.diarioTrabajo) {
        final updated = InformeDiarioTrabajoModel(
          id: alert.document.id,
          fecha: alert.document.fecha,
          obraId: alert.document.obraId,
          usuarioId: alert.document.usuarioId,
          usuarioName: alert.document.usuarioName,
          tareasRealizadas: alert.document.tareasRealizadas,
          horasTrabajadas: alert.document.horasTrabajadas,
          personal: alert.document.personal,
          maquinariaIds: alert.document.maquinariaIds,
          observaciones: alert.document.observaciones,
          estado: RemitoStatus.listoParaEnviar,
          fotos: alert.document.fotos,
        );
        await _informeProvider.saveInformeDiarioTrabajo(updated);
        await _informeProvider.syncQueue();
      }
      
      _calculateNotifications();
      
      final stillHasError = _alerts.any((a) => a.id == alert.id);
      if (stillHasError) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.red.shade800,
            content: const Text(
              'Error al sincronizar el documento. Revise el detalle.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.green.shade800,
            content: const Text(
              '¡Documento sincronizado con éxito!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.shade800,
          content: Text(
            'Error al reintentar: $e',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}
