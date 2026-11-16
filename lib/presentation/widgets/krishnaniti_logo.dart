import 'package:flutter/material.dart';

/// Crisp vector emblem of Krishnaniti matching favicon.svg in Nagarsevak-Managment
class KrishnanitiLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const KrishnanitiLogo({
    super.key,
    this.size = 48,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.25),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _KrishnanitiLogoPainter(),
      ),
    );
  }
}

class _KrishnanitiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle gradient (#0ea5e9 to #0369a1)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0EA5E9), // Sky Blue
          Color(0xFF0369A1), // Darker Brand Blue
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // Vector network lines and nodes scaled to size
    final scale = size.width / 512.0;
    canvas.save();
    canvas.translate(size.width * 0.207, size.height * 0.207);
    canvas.scale(scale * 0.6);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const topCenter = Offset(256, 80);
    const leftCenter = Offset(100, 240);
    const rightCenter = Offset(412, 240);
    const bottomCenter = Offset(256, 400);

    // Connecting lines
    canvas.drawLine(bottomCenter, leftCenter, linePaint);
    canvas.drawLine(bottomCenter, rightCenter, linePaint);
    canvas.drawLine(leftCenter, topCenter, linePaint);
    canvas.drawLine(rightCenter, topCenter, linePaint);

    // Ring nodes
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(topCenter, 60, ringPaint);
    canvas.drawCircle(leftCenter, 60, ringPaint);
    canvas.drawCircle(rightCenter, 60, ringPaint);

    // Solid bottom dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(bottomCenter, 40, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
