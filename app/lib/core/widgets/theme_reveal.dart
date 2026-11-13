import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/motion.dart';

/// Troca de tema em círculo: tira uma "foto" da tela atual, aplica o tema
/// novo por baixo e abre um círculo crescente a partir de [origin],
/// revelando o novo tema. Com movimento reduzido, a troca é instantânea.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  /// Executa [change] com a animação de revelação, quando possível.
  static Future<void> run(
    BuildContext context,
    Offset? origin,
    VoidCallback change,
  ) async {
    final state = context.findAncestorStateOfType<_ThemeRevealState>();
    if (state == null || origin == null || !Motion.of(context).enabled) {
      change();
      return;
    }
    await state._reveal(origin, change);
  }

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  ui.Image? _old;
  Offset _origin = Offset.zero;

  Future<void> _reveal(Offset origin, VoidCallback change) async {
    final ro = _boundary.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary || _c.isAnimating) {
      change();
      return;
    }
    ui.Image image;
    try {
      image = await ro.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      change(); // Sem captura disponível: troca direta.
      return;
    }
    if (!mounted) return;
    final local = (context.findRenderObject() as RenderBox).globalToLocal(
      origin,
    );
    setState(() {
      _old = image;
      _origin = local;
    });
    change();
    await _c.forward(from: 0);
    if (!mounted) return;
    setState(() => _old = null);
    image.dispose();
  }

  @override
  void dispose() {
    _c.dispose();
    _old?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (_old != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _RevealPainter(
                    _old!,
                    _origin,
                    CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter(this.image, this.origin, this.a) : super(repaint: a);
  final ui.Image image;
  final Offset origin;
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxR = corners.map((p) => (p - origin).distance).reduce(math.max);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: origin, radius: maxR * a.value));
    final clip = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      hole,
    );
    canvas.save();
    canvas.clipPath(clip);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RevealPainter old) => old.image != image;
}
