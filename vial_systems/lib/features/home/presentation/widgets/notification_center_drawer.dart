import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../remito/presentation/screens/remito_form_screen.dart';
import '../../../informes/presentation/screens/informe_diario_form_screen.dart';
import '../../../informes/presentation/screens/informe_diario_trabajo_form_screen.dart';

class NotificationCenterDrawer extends StatelessWidget {
  const NotificationCenterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width > 500 ? 450 : MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final sortedAlerts = List<NotificationAlert>.from(provider.alerts)
            ..sort((a, b) => a.severity.index.compareTo(b.severity.index)); // Errors first, then warnings

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Gradient Header
              _buildHeader(context, provider),
              
              // Scrollable alerts list
              Expanded(
                child: provider.isSyncing
                    ? const Center(child: CircularProgressIndicator())
                    : sortedAlerts.isEmpty
                        ? _buildEmptyState(context)
                        : _buildAlertsList(context, sortedAlerts, provider),
              ),

              // Bottom Bar
              if (sortedAlerts.isNotEmpty) _buildBottomBar(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Alertas y Pendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Cerrar panel',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadgeChip(
                context,
                '${provider.errorAlertsCount} Errores',
                provider.errorAlertsCount > 0 ? Colors.red.shade100 : Colors.white24,
                provider.errorAlertsCount > 0 ? Colors.red.shade900 : Colors.white70,
              ),
              const SizedBox(width: 8),
              _buildBadgeChip(
                context,
                '${provider.warningAlertsCount} Borradores',
                provider.warningAlertsCount > 0 ? Colors.amber.shade100 : Colors.white24,
                provider.warningAlertsCount > 0 ? Colors.amber.shade900 : Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(BuildContext context, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Todo al día!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No tienes borradores pendientes ni errores de sincronización en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context, List<NotificationAlert> alerts, NotificationProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final isError = alert.severity == NotificationSeverity.error;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isError ? Colors.red.shade100 : Colors.amber.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isError ? Colors.red.shade50 : Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isError ? Icons.error_outline : Icons.edit_document,
                        color: isError ? Colors.red.shade700 : Colors.amber.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isError ? Colors.red.shade900 : Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isError) ...[
                      TextButton.icon(
                        onPressed: () => _showTechnicalErrorDialog(context, alert),
                        icon: const Icon(Icons.code, size: 16),
                        label: const Text('Ver Error'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: provider.isSyncing 
                            ? null 
                            : () => provider.retryDocument(context, alert),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close Drawer
                          _openFormScreen(context, alert);
                        },
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Completar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: provider.isSyncing 
            ? null 
            : () => provider.syncAll(context),
        icon: provider.isSyncing 
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.sync),
        label: Text(provider.isSyncing ? 'Sincronizando...' : 'Sincronizar Todo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _openFormScreen(BuildContext context, NotificationAlert alert) {
    switch (alert.documentType) {
      case DocumentType.remito:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RemitoFormScreen(remito: alert.document)),
        );
        break;
      case DocumentType.informeDiario:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InformeDiarioFormScreen(informe: alert.document)),
        );
        break;
      case DocumentType.diarioTrabajo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InformeDiarioTrabajoFormScreen(informe: alert.document)),
        );
        break;
    }
  }

  void _showTechnicalErrorDialog(BuildContext context, NotificationAlert alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 10),
              const Text('Diagnóstico Técnico'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Detalle del error ocurrido durante el proceso de sincronización con la base de datos central:',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    alert.message,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sugerencia: Verifique su conexión a Internet y que la información del documento sea correcta. Puede reintentar el envío desde la tarjeta de la alerta.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
