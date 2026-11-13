import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';

/// "Mapa vivo": ilustração animada que conta o problema e a solução.
///
/// 1. A planta do shopping aparece em linhas finas.
/// 2. Um percurso sai da entrada e encontra uma escada (barreira).
/// 3. A escada é marcada com ✕ e o trecho apaga.
/// 4. O percurso desvia pelo elevador; um balão de conversa surge no caminho.
/// 5. O destino acende.
///
/// Toca uma vez (~4 s) e para. Com movimento reduzido, aparece já no
/// estado final. Leitores de tela recebem a descrição em texto.
class LivingMap extends StatefulWidget {
  const LivingMap({super.key, this.height = 210});

  final double height;

  static const description =
      'Ilustração: no mapa do shopping, o caminho encontra uma escada, '
      'desvia pelo elevador e chega ao destino.';

  @override
  State<LivingMap> createState() => _LivingMapState();
}

class _LivingMapState extends State<LivingMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = Motion.of(context).enabled;
    if (!enabled) {
      _c.value = 1;
    } else if (!_started) {
      _started = true;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    return Semantics(
      image: true,
      label: LivingMap.description,
      excludeSemantics: true,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: t.colors.surface,
          borderRadius: BorderRadius.circular(AcessaRadius.card + 4),
          border: Border.all(
            color: t.colors.border.withValues(alpha: .25),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _MapPainter(_c, t.colors, glow: !t.highContrast),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Fase [a, b] da linha do tempo, normalizada para 0..1.
double _phase(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

class _MapPainter extends CustomPainter {
  _MapPainter(this.a, this.c, {required this.glow}) : super(repaint: a);

  final Animation<double> a;
  final AcessaColors c;
  final bool glow;

  // Pontos-chave em coordenadas normalizadas.
  static const entrance = Offset(.09, .86);
  static const junction = Offset(.09, .52);
  static const fork = Offset(.36, .52);
  static const stairs = Offset(.62, .52);
  static const elevator = Offset(.36, .2);
  static const dest = Offset(.88, .2);

  @override
  void paint(Canvas canvas, Size size) {
    final t = a.value;
    Offset p(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    // 1. Planta do shopping (lojas e corredores).
    final plan = _phase(t, 0, .18);
    final line = Paint()
      ..color = c.mapLine.withValues(alpha: plan)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rooms = <Rect>[
      const Rect.fromLTWH(.18, .62, .2, .26),
      const Rect.fromLTWH(.44, .62, .22, .26),
      const Rect.fromLTWH(.72, .62, .2, .26),
      const Rect.fromLTWH(.5, .3, .16, .14),
      const Rect.fromLTWH(.72, .3, .2, .14),
      const Rect.fromLTWH(.04, .06, .22, .3),
    ];
    for (final r in rooms) {
      final rr = Rect.fromLTWH(
        r.left * size.width,
        r.top * size.height,
        r.width * size.width,
        r.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rr, const Radius.circular(8)),
        line,
      );
    }

    // 2. Primeiro percurso: entrada → bifurcação → escada.
    final first = Path()
      ..moveTo(p(entrance).dx, p(entrance).dy)
      ..lineTo(p(junction).dx, p(junction).dy)
      ..lineTo(p(fork).dx, p(fork).dy)
      ..lineTo(p(stairs).dx - 18, p(stairs).dy);
    final firstProgress = _phase(t, .12, .38);
    final blocked = _phase(t, .4, .5);
    _route(
      canvas,
      first,
      firstProgress,
      c.navigation,
      fade: 1 - blocked * .75,
      head: firstProgress < 1,
    );

    // Escada.
    _stairs(canvas, p(stairs), _phase(t, .1, .2));

    // 3. ✕ na escada.
    if (blocked > 0) {
      final s = Curves.easeOutBack.transform(blocked);
      final xp = Paint()
        ..color = c.marker
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final ctr = p(stairs);
      final r = 13 * s;
      canvas.drawLine(ctr + Offset(-r, -r), ctr + Offset(r, r), xp);
      canvas.drawLine(ctr + Offset(r, -r), ctr + Offset(-r, r), xp);
    }

    // 4. Desvio: bifurcação → elevador → destino.
    final detour = Path()
      ..moveTo(p(fork).dx, p(fork).dy)
      ..lineTo(p(elevator).dx, p(elevator).dy)
      ..lineTo(p(dest).dx, p(dest).dy);
    final detourProgress = _phase(t, .5, .82);
    _route(canvas, detour, detourProgress, c.help, head: detourProgress < 1);

    _elevator(canvas, p(elevator), _phase(t, .1, .2), lit: _phase(t, .58, .66));

    // Balão de conversa no caminho.
    final bubble = _phase(t, .7, .8);
    if (bubble > 0) {
      _bubble(
        canvas,
        Offset(
          p(elevator).dx + (p(dest).dx - p(elevator).dx) * .5,
          p(elevator).dy - 20,
        ),
        Curves.easeOutBack.transform(bubble),
      );
    }

    // Entrada.
    final entryP = Paint()..color = c.navigation.withValues(alpha: plan);
    canvas.drawCircle(p(entrance), 6, entryP);

    // 5. Destino acende.
    final arrive = _phase(t, .82, .92);
    final ring = _phase(t, .86, 1);
    final d = p(dest);
    canvas.drawCircle(
      d,
      7 + 3 * Curves.easeOutBack.transform(arrive),
      Paint()
        ..color = (arrive > 0 ? c.help : c.mapLine).withValues(
          alpha: math.max(plan, arrive),
        ),
    );
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        d,
        10 + 22 * Curves.easeOutCubic.transform(ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = c.help.withValues(alpha: 1 - ring),
      );
    }

    // Rótulos: o desenho não depende só de ícones para ser entendido.
    _label(
      canvas,
      'Entrada',
      p(entrance) + const Offset(14, 0),
      plan,
      align: TextAlign.left,
    );
    _label(
      canvas,
      'Escada',
      p(stairs) + const Offset(0, 26),
      _phase(t, .1, .2),
      color: blocked > 0 ? c.marker : c.inkMuted,
    );
    _label(
      canvas,
      'Elevador',
      p(elevator) + const Offset(-22, 0),
      _phase(t, .1, .2),
      align: TextAlign.right,
      color: Color.lerp(c.inkMuted, c.help, _phase(t, .58, .66)),
    );
    _label(
      canvas,
      'Destino',
      d + const Offset(0, 24),
      math.max(plan, arrive),
      color: arrive > 0 ? c.help : c.inkMuted,
    );
  }

  void _label(
    Canvas canvas,
    String s,
    Offset at,
    double o, {
    TextAlign align = TextAlign.center,
    Color? color,
  }) {
    if (o <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: (color ?? c.inkMuted).withValues(alpha: o),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.left => at.dx,
      TextAlign.right => at.dx - tp.width,
      _ => at.dx - tp.width / 2,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  void _route(
    Canvas canvas,
    Path path,
    double progress,
    Color color, {
    double fade = 1,
    bool head = false,
  }) {
    if (progress <= 0) return;
    final metric = path.computeMetrics().toList();
    final total = metric.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * Curves.easeInOutCubic.transform(progress);
    final drawn = Path();
    Offset? tip;
    for (final m in metric) {
      if (remaining <= 0) break;
      final len = math.min(remaining, m.length);
      drawn.addPath(m.extractPath(0, len), Offset.zero);
      tip = m.getTangentForOffset(len)?.position;
      remaining -= len;
    }
    if (glow) {
      canvas.drawPath(
        drawn,
        Paint()
          ..color = color.withValues(alpha: .35 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (head && tip != null) {
      // A "pessoa" andando na ponta do percurso.
      canvas.drawCircle(tip, 7, Paint()..color = c.ink);
      canvas.drawCircle(tip, 4, Paint()..color = color);
    }
  }

  void _stairs(Canvas canvas, Offset ctr, double o) {
    if (o <= 0) return;
    final paint = Paint()
      ..color = c.inkMuted.withValues(alpha: o)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(ctr.dx - 20, ctr.dy + 16);
    for (var i = 0; i < 4; i++) {
      path
        ..relativeLineTo(0, -8)
        ..relativeLineTo(10, 0);
    }
    canvas.drawPath(path, paint);
  }

  void _elevator(Canvas canvas, Offset ctr, double o, {required double lit}) {
    if (o <= 0) return;
    final color = Color.lerp(c.inkMuted, c.help, lit)!.withValues(alpha: o);
    final rect = Rect.fromCenter(center: ctr, width: 30, height: 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..color = c.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final tri = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(ctr.dx, ctr.dy - 10)
        ..lineTo(ctr.dx - 6, ctr.dy - 2)
        ..lineTo(ctr.dx + 6, ctr.dy - 2)
        ..close(),
      tri,
    );
    canvas.drawPath(
      Path()
        ..moveTo(ctr.dx, ctr.dy + 10)
        ..lineTo(ctr.dx - 6, ctr.dy + 2)
        ..lineTo(ctr.dx + 6, ctr.dy + 2)
        ..close(),
      tri,
    );
  }

  void _bubble(Canvas canvas, Offset at, double s) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(s);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 40, height: 24),
      const Radius.circular(12),
    );
    final fill = Paint()..color = c.communication;
    canvas.drawRRect(body, fill);
    canvas.drawPath(
      Path()
        ..moveTo(-6, 11)
        ..lineTo(-12, 20)
        ..lineTo(2, 12)
        ..close(),
      fill,
    );
    final dot = Paint()..color = c.onAccent;
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(i * 9.0, 0), 2.6, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.c != c || old.glow != glow;
}
