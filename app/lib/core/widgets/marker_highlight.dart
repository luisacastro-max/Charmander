import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';

/// Marca-texto inclinado atrás de uma palavra (referência Nexo).
/// Ele "se desenha" da esquerda para a direita uma única vez.
/// É decorativo: o texto continua legível sem ele.
class MarkerHighlight extends StatelessWidget {
  const MarkerHighlight({
    super.key,
    required this.text,
    required this.style,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle? style;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final total = Motion.slow + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
      duration: motion.enabled ? total : Duration.zero,
      curve: Interval(
        motion.enabled ? delay.inMilliseconds / total.inMilliseconds : 0,
        1,
        curve: Motion.enter,
      ),
      builder: (context, t, child) =>
          CustomPaint(painter: _MarkerPainter(t, c.marker), child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(text, style: style?.copyWith(color: c.onMarker)),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    // Faixa levemente inclinada, cobrindo do meio da letra para baixo
    // um pouco além da linha de base.
    final top = size.height * .18;
    final h = size.height * .78;
    final w = size.width * t;
    final skew = h * .18;
    final path = Path()
      ..moveTo(skew, top)
      ..lineTo(w + skew * .2, top - 2)
      ..lineTo(w - skew * .2, top + h)
      ..lineTo(0, top + h + 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 8
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.t != t || old.color != color;
}
