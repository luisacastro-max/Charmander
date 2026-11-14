import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/viagem.dart';

/// Bússola guiada pelo mapa (decisão MUD-01): a seta aponta para o
/// próximo ponto do percurso no desenho do shopping (para cima = norte do
/// mapa). Não usa o sensor magnético do celular. Em troca de piso, mostra
/// o meio (elevador, escada rolante, escada) no lugar da seta.
class BussolaGuiada extends StatefulWidget {
  const BussolaGuiada({super.key, required this.estado, this.tamanho = 230});

  final EstadoNavegacao estado;
  final double tamanho;

  @override
  State<BussolaGuiada> createState() => _BussolaGuiadaState();
}

class _BussolaGuiadaState extends State<BussolaGuiada> {
  /// Voltas acumuladas, para a seta girar sempre pelo caminho mais curto.
  double _voltas = 0;

  @override
  void initState() {
    super.initState();
    _voltas = (widget.estado.direcao ?? 0) / 360;
  }

  @override
  void didUpdateWidget(BussolaGuiada old) {
    super.didUpdateWidget(old);
    final d = widget.estado.direcao;
    if (d == null) return;
    final atual = (_voltas % 1 + 1) % 1;
    var delta = d / 360 - atual;
    if (delta > .5) delta -= 1;
    if (delta < -.5) delta += 1;
    _voltas += delta;
  }

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final e = widget.estado;
    final etapa = e.etapaAtual;
    final s = widget.tamanho;

    final Widget centro;
    if (e.naParada) {
      centro = Icon(
        e.concluida ? Icons.flag : Icons.check_circle_outline,
        size: s * .42,
        color: c.help,
      );
    } else if (etapa!.trecho.trocaPiso != null) {
      centro = Icon(
        switch (etapa.trecho.trocaPiso!) {
          TrocaPiso.elevador => Icons.elevator_outlined,
          TrocaPiso.escadaRolante => Icons.escalator_outlined,
          TrocaPiso.escada => Icons.stairs_outlined,
          TrocaPiso.rampa => Icons.accessible_forward,
        },
        size: s * .42,
        color: c.navigation,
      );
    } else {
      centro = AnimatedRotation(
        turns: _voltas,
        duration: motion.d(const Duration(milliseconds: 450)),
        curve: Curves.easeOutCubic,
        child: CustomPaint(
          size: Size.square(s * .7),
          painter: _SetaPainter(c, glow: !t.highContrast),
        ),
      );
    }

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: s,
        child: CustomPaint(
          painter: _MostradorPainter(c),
          child: Center(child: centro),
        ),
      ),
    );
  }
}

/// Texto para leitores de tela com a direção da seta ("à direita no mapa").
String direcaoEmTexto(double graus) {
  const nomes = [
    'para cima',
    'para cima e à direita',
    'à direita',
    'para baixo e à direita',
    'para baixo',
    'para baixo e à esquerda',
    'à esquerda',
    'para cima e à esquerda',
  ];
  return '${nomes[((graus + 22.5) % 360 ~/ 45)]} no mapa';
}

class _MostradorPainter extends CustomPainter {
  _MostradorPainter(this.c);
  final AcessaColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(o, r, Paint()..color = c.surface);
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = c.navigation,
    );
    final marca = Paint()
      ..color = c.mapLine
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final dentro = i % 6 == 0 ? r - 16 : r - 9;
      canvas.drawLine(
        o + Offset(math.sin(a) * dentro, -math.cos(a) * dentro),
        o + Offset(math.sin(a) * (r - 4), -math.cos(a) * (r - 4)),
        marca,
      );
    }
    // "Mapa ↑": lembra que a referência é o desenho, não o norte real.
    final tp = TextPainter(
      text: TextSpan(
        text: 'MAPA',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: c.inkMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(o.dx - tp.width / 2, o.dy - r + 20));
  }

  @override
  bool shouldRepaint(_MostradorPainter old) => old.c != c;
}

class _SetaPainter extends CustomPainter {
  _SetaPainter(this.c, {required this.glow});
  final AcessaColors c;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final seta = Path()
      ..moveTo(w / 2, h * .05)
      ..lineTo(w * .82, h * .55)
      ..lineTo(w * .6, h * .5)
      ..lineTo(w * .6, h * .92)
      ..lineTo(w * .4, h * .92)
      ..lineTo(w * .4, h * .5)
      ..lineTo(w * .18, h * .55)
      ..close();
    if (glow) {
      canvas.drawPath(
        seta,
        Paint()
          ..color = c.navigation.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawPath(seta, Paint()..color = c.navigation);
    canvas.drawPath(
      seta,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = c.ink,
    );
  }

  @override
  bool shouldRepaint(_SetaPainter old) => old.c != c || old.glow != glow;
}
