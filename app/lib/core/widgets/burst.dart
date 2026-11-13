import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';

/// Explosão curta de pontos ao redor do [child] (confirmação divertida).
/// Dura 500 ms, não se repete e não acontece com movimento reduzido.
/// É só reforço visual: o estado também aparece em texto.
class Burst extends StatefulWidget {
  const Burst({super.key, required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  State<Burst> createState() => BurstState();
}

class BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  void play() {
    if (!Motion.of(context).enabled) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _BurstPainter(_c, widget.color),
      child: widget.child,
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.a, this.color) : super(repaint: a);
  final Animation<double> a;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = a.value;
    if (t == 0 || t == 1) return;
    final ease = Curves.easeOutCubic.transform(t);
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: 1 - t);
    const n = 10;
    for (var i = 0; i < n; i++) {
      final ang = i * 2 * math.pi / n + .3;
      final dist = 18 + 22 * ease;
      final r = (i.isEven ? 3.5 : 2.5) * (1 - t * .6);
      canvas.drawCircle(
        center + Offset(math.cos(ang), math.sin(ang)) * dist,
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.color != color;
}
