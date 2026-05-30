import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class IndustrialLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const IndustrialLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.yellowIndustrial;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IndustrialLogoPainter(activeColor),
      ),
    );
  }
}

class _IndustrialLogoPainter extends CustomPainter {
  final Color activeColor;

  _IndustrialLogoPainter(this.activeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Dibujar el fondo circular de contraste grafito oscuro
    paint.color = AppColors.darkGraphite;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width * 0.25),
      ),
      paint,
    );

    // 2. Dibujar franjas industriales de advertencia en diagonal (estilo Caterpillar)
    final stripePaint = Paint()
      ..color = AppColors.yellowIndustrial.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double stripeWidth = size.width * 0.12;
    for (double i = -size.width; i < size.width * 2; i += stripeWidth * 2) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth - size.height, size.height)
        ..lineTo(i - size.height, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }

    // 3. Dibujar la "V" estilizada como carretera/ruta logística
    final roadPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      // Rama izquierda del la V
      ..moveTo(size.width * 0.18, size.height * 0.22)
      ..lineTo(size.width * 0.35, size.height * 0.22)
      ..lineTo(size.width * 0.50, size.height * 0.70)
      ..lineTo(size.width * 0.65, size.height * 0.22)
      ..lineTo(size.width * 0.82, size.height * 0.22)
      ..lineTo(size.width * 0.58, size.height * 0.84)
      ..arcToPoint(
        Offset(size.width * 0.42, size.height * 0.84),
        radius: Radius.circular(size.width * 0.1),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(path, roadPaint);

    // 4. Dibujar líneas punteadas blancas en el centro de la V como marca de carril vial
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = size.width * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dibujar trazos discontinuos usando espaciados proporcionales
    _drawDashedLine(canvas, size.width * 0.26, size.height * 0.26, size.width * 0.46, size.height * 0.75, dashPaint, size.width * 0.1);
    _drawDashedLine(canvas, size.width * 0.74, size.height * 0.26, size.width * 0.54, size.height * 0.75, dashPaint, size.width * 0.1);
  }

  void _drawDashedLine(Canvas canvas, double x1, double y1, double x2, double y2, Paint paint, double dashLength) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double distance = MathHelpers.sqrt(dx * dx + dy * dy);
    
    final int count = (distance / (dashLength * 1.8)).floor();
    for (int i = 0; i < count; i++) {
      final double startPercent = (i * dashLength * 1.8) / distance;
      final double endPercent = ((i * dashLength * 1.8) + dashLength) / distance;
      
      canvas.drawLine(
        Offset(x1 + dx * startPercent, y1 + dy * startPercent),
        Offset(x1 + dx * endPercent, y1 + dy * endPercent),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Auxiliar matemático simple para evitar dependencias matemáticas externas
class MathHelpers {
  static double sqrt(double x) {
    if (x < 0) return 0.0;
    double res = x;
    double prev;
    do {
      prev = res;
      res = 0.5 * (res + x / res);
    } while ((res - prev).abs() > 0.0000000000001);
    return res;
  }
}
