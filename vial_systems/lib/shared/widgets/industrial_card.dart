import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';

enum IndustrialCardStatus {
  completo,
  pendiente,
  error,
  progreso,
  offline,
  ninguno
}

class IndustrialCard extends StatelessWidget {
  final Widget child;
  final IndustrialCardStatus status;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const IndustrialCard({
    super.key,
    required this.child,
    this.status = IndustrialCardStatus.ninguno,
    this.onTap,
    this.padding,
    this.width,
  });

  Color _getStatusColor() {
    switch (status) {
      case IndustrialCardStatus.completo:
        return AppColors.operationalGreen;
      case IndustrialCardStatus.pendiente:
        return AppColors.orangeAlert;
      case IndustrialCardStatus.error:
        return AppColors.controlledRed;
      case IndustrialCardStatus.progreso:
        return AppColors.yellowIndustrial;
      case IndustrialCardStatus.offline:
        return AppColors.connectionGray;
      case IndustrialCardStatus.ninguno:
        return Colors.transparent;
    }
  }

  IconData? _getStatusIcon() {
    switch (status) {
      case IndustrialCardStatus.completo:
        return Icons.check_circle_outline;
      case IndustrialCardStatus.pendiente:
        return Icons.access_time;
      case IndustrialCardStatus.error:
        return Icons.warning_amber_rounded;
      case IndustrialCardStatus.progreso:
        return Icons.sync_rounded;
      case IndustrialCardStatus.offline:
        return Icons.cloud_off_rounded;
      case IndustrialCardStatus.ninguno:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final hasStatus = status != IndustrialCardStatus.ninguno;

    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde lateral indicador de color de estado (Caterpillar/industrial style)
            if (hasStatus)
              Container(
                width: 5.0,
                color: statusColor,
              ),
            
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: child),
                    if (hasStatus && statusIcon != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        statusIcon,
                        size: AppIconSize.md,
                        color: statusColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget cardContainer = Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // Sombra extremadamente suave
            offset: Offset(0, 2),
            blurRadius: AppSpacing.sm,
            spreadRadius: 0,
          ),
        ],
      ),
      child: cardBody,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: cardContainer,
      );
    }

    return cardContainer;
  }
}
