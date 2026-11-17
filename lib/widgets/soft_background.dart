import 'package:flutter/material.dart';


class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _SoftPatternPainter())),
          child,
        ],
      );
}

class _SoftPatternPainter extends CustomPainter {
  const _SoftPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pale = Paint()..color = const Color(0xFFEDEDFB).withValues(alpha: 0.42);
    final line = Paint()
      ..color = const Color(0xFFDADCF0).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.28), size.width * 0.42, pale);
    canvas.drawCircle(Offset(size.width * 0.06, size.height * 0.82), size.width * 0.5, pale);
    final path1 = Path()
      ..moveTo(-size.width * .12, size.height * .34)
      ..cubicTo(size.width * .24, size.height * .06, size.width * .48, size.height * .13, size.width * .78, size.height * .35)
      ..cubicTo(size.width * .91, size.height * .44, size.width * 1.05, size.height * .43, size.width * 1.12, size.height * .32);
    final path2 = Path()
      ..moveTo(-size.width * .10, size.height * .55)
      ..cubicTo(size.width * .23, size.height * .34, size.width * .48, size.height * .35, size.width * .75, size.height * .54)
      ..cubicTo(size.width * .92, size.height * .66, size.width * 1.06, size.height * .66, size.width * 1.10, size.height * .55);
    canvas.drawPath(path1, line);
    canvas.drawPath(path2, line);
    for (final point in <Offset>[
      Offset(size.width * .17, size.height * .18),
      Offset(size.width * .52, size.height * .28),
      Offset(size.width * .82, size.height * .12),
      Offset(size.width * .72, size.height * .72),
      Offset(size.width * .11, size.height * .82),
    ]) {
      canvas.drawCircle(point, 3, Paint()..color = const Color(0xFFDADCF0).withValues(alpha: .55));
      canvas.drawCircle(point, 7, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
