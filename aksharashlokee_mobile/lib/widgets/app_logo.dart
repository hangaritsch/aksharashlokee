import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TraditionalLogoPainter(
          lotusColor: const Color(0xFFD35400), // Saffron
          letterColor: const Color(0xFF800000), // Maroon
        ),
      ),
    );
  }
}

class _TraditionalLogoPainter extends CustomPainter {
  final Color lotusColor;
  final Color letterColor;

  _TraditionalLogoPainter({
    required this.lotusColor,
    required this.letterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Petals (8-petaled lotus)
    final petalPaint = Paint()
      ..color = lotusColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.5) // Gold outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.bottom); // Translate to center
      canvas.translate(0, -radius * 0.1); // Shift up slightly
      
      // We'll draw petals from the center outwards
      _drawPetal(canvas, size.width * 0.45, petalPaint, outlinePaint, angle, center);
      canvas.restore();
    }

    // 2. Draw Central Circle (Bindu)
    final innerCircleRadius = radius * 0.35;
    final innerCirclePaint = Paint()
      ..color = const Color(0xFFFFF9E3) // Parchment background
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, innerCircleRadius, innerCirclePaint);
    canvas.drawCircle(center, innerCircleRadius, outlinePaint..color = lotusColor.withOpacity(0.3));

    // 3. Draw the Letter 'अ'
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'अ',
        style: GoogleFonts.tiroDevanagariSanskrit(
          color: letterColor,
          fontSize: size.width * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawPetal(Canvas canvas, double petalLength, Paint fillPaint, Paint strokePaint, double angle, Offset center) {
    canvas.save();
    canvas.translate(0, -center.dy * 0.1); // Correct offset
    // Resetting for a better petal shape relative to center
    canvas.restore();
    
    // Let's use a path for the petal
    final path = Path();
    final petalWidth = petalLength * 0.4;
    
    // Define petal shape
    path.moveTo(center.dx, center.dy);
    path.quadraticBezierTo(
      center.dx + petalWidth, center.dy - petalLength * 0.5, 
      center.dx, center.dy - petalLength
    );
    path.quadraticBezierTo(
      center.dx - petalWidth, center.dy - petalLength * 0.5, 
      center.dx, center.dy
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
