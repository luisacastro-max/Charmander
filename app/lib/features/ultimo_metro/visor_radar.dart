import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/burst.dart';
import '../../domain/rules/procura.dart';

/// Visor fictício da câmera com radar: mostra onde cada objeto reconhecido
/// aparece na imagem. O alvo fica destacado e o visor "esquenta" (do azul
/// da noite ao limão) conforme ele se aproxima do centro — o mesmo sinal
/// da vibração, para quem enxerga pouco.
///
/// Animações (todas decorativas; o estado também está em texto):
/// - varredura de radar girando sem parar;
/// - ondas que nascem no mesmo ritmo dos pulsos de vibração
///   ([Sinal.intervalo]): o "coração" visual bate junto com o tato;
/// - mira que balança procurando, aperta conforme esquenta e "trava" com
///   um estalo e uma explosão de pontos quando o alvo fica bem à frente;
/// - etiquetas dos objetos que surgem com um pulinho e deslizam conforme
///   o celular gira.
///
/// Com movimento reduzido nada se move nem se repete: tudo aparece direto
/// no estado final.
class VisorRadar extends StatefulWidget {
  const VisorRadar({
    super.key,
    required this.alvo,
    required this.vistos,
    required this.sinal,
  });

  final Alvo alvo;
  final List<Deteccao> vistos;
  final Sinal sinal;

  @override
  State<VisorRadar> createState() => _VisorRadarState();
}

/// Quanto o visor está "quente": 0 = alvo fora da imagem, 1 = bem à frente.
double calorDo(Sinal s) {
  if (s.centralizado) return 1;
  final d = s.deteccao;
  if (d == null) return 0;
  final x = ((d.deslocamento.abs() - limiteCentro) / (1 - limiteCentro)).clamp(
    0.0,
    1.0,
  );
  return .35 + .4 * (1 - x);
}

class _VisorRadarState extends State<VisorRadar> with TickerProviderStateMixin {
  /// Relógio contínuo do radar. Um só ticker para varredura e ondas; ele
  /// para sozinho quando a tela fica coberta (TickerMode desligado).
  late final Ticker _relogio = createTicker(_aoTique);

  /// "Estalo" da mira quando trava no alvo.
  late final AnimationController _trava = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  /// Segundos desde que o radar começou (atualizado sem setState).
  final _tempo = ValueNotifier<double>(0);

  /// Instantes (em segundos) em que cada onda nasceu.
  final _ondas = <double>[];
  double _ultimaOnda = -100;
  final _burst = GlobalKey<BurstState>();
  bool _animar = false;

  static const _vidaOnda = 1.4;

  /// Mesmo ritmo da vibração, com um piso para não virar borrão.
  double get _periodo =>
      math.max(widget.sinal.intervalo.inMilliseconds, 180) / 1000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animar = Motion.of(context).enabled;
    if (animar == _animar) return;
    _animar = animar;
    if (animar) {
      _ondas.clear();
      _ultimaOnda = -100;
      _relogio.start();
    } else {
      _relogio.stop();
      _ondas.clear();
      _trava.value = 1;
    }
  }

  @override
  void didUpdateWidget(VisorRadar old) {
    super.didUpdateWidget(old);
    if (!old.sinal.centralizado && widget.sinal.centralizado && _animar) {
      _trava.forward(from: 0);
      _burst.currentState?.play();
    }
  }

  void _aoTique(Duration decorrido) {
    final s = decorrido.inMicroseconds / Duration.microsecondsPerSecond;
    if (s - _ultimaOnda >= _periodo) {
      _ondas.add(s);
      _ultimaOnda = s;
    }
    _ondas.removeWhere((o) => s - o > _vidaOnda);
    _tempo.value = s;
  }

  @override
  void dispose() {
    _relogio.dispose();
    _trava.dispose();
    _tempo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final sinal = widget.sinal;
    final status = sinal.centralizado
        ? 'Bem à frente!'
        : sinal.encontrado
        ? 'Quente: está na imagem'
        : 'Frio: gire devagar';

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: calorDo(sinal)),
        duration: motion.d(Motion.slow),
        curve: Curves.easeOutCubic,
        builder: (context, calor, _) {
          final quente = c.help;
          final borda = Color.lerp(c.border, c.help, calor)!;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF0B0E1A),
                c.help.withValues(alpha: .55),
                calor,
              ),
              borderRadius: BorderRadius.circular(AcessaRadius.card),
              border: Border.all(color: borda, width: 2 + 3 * calor),
              boxShadow: t.highContrast
                  ? null
                  : [
                      BoxShadow(
                        color: quente.withValues(alpha: .45 * calor),
                        blurRadius: 28 * calor,
                        spreadRadius: 2 * calor,
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AcessaRadius.card - 3),
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _RadarPainter(
                              tempo: _tempo,
                              trava: _trava,
                              ondas: _ondas,
                              vidaOnda: _vidaOnda,
                              calor: calor,
                              animar: _animar,
                              frio: c.navigation,
                              quente: quente,
                            ),
                          ),
                        ),
                      ),
                      // Explosão de pontos quando a mira trava no alvo.
                      Center(
                        child: Burst(
                          key: _burst,
                          color: quente,
                          child: const SizedBox.square(dimension: 120),
                        ),
                      ),
                      for (final d in widget.vistos)
                        AnimatedPositioned(
                          key: ValueKey(d.alvo),
                          duration: motion.d(Motion.base),
                          curve: Motion.enter,
                          left: (d.deslocamento + 1) / 2 * (w - 120),
                          top:
                              box.maxHeight *
                              (d.alvo == widget.alvo ? .58 : .12),
                          width: 120,
                          child: _Surgir(
                            child: _Etiqueta(
                              deteccao: d,
                              ehAlvo: d.alvo == widget.alvo,
                              calor: calor,
                            ),
                          ),
                        ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        right: 10,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: _Pilula(
                                child: AnimatedSwitcher(
                                  duration: motion.d(Motion.base),
                                  switchInCurve: Motion.pop,
                                  switchOutCurve: Curves.easeIn,
                                  layoutBuilder: (atual, anteriores) => Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [...anteriores, ?atual],
                                  ),
                                  transitionBuilder: (child, a) =>
                                      FadeTransition(
                                        opacity: a,
                                        child: ScaleTransition(
                                          scale: Tween(
                                            begin: .7,
                                            end: 1.0,
                                          ).animate(a),
                                          alignment: Alignment.centerLeft,
                                          child: child,
                                        ),
                                      ),
                                  child: Text(
                                    status,
                                    key: ValueKey(status),
                                    style: text.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AcessaSpacing.sm),
                            _Pilula(
                              child: _Termometro(calor: calor, cor: quente),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fundo escuro quase opaco: garante contraste do texto branco sobre
/// qualquer cor que o visor tenha no momento.
class _Pilula extends StatelessWidget {
  const _Pilula({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xE6000000),
      borderRadius: BorderRadius.circular(AcessaRadius.pill),
    ),
    child: child,
  );
}

/// Barrinhas de "sinal" que acendem conforme esquenta.
class _Termometro extends StatelessWidget {
  const _Termometro({required this.calor, required this.cor});
  final double calor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    const n = 5;
    final acesas = (calor * n).ceil();
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: 5,
              height: 8 + 4.0 * i,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              decoration: BoxDecoration(
                color: i < acesas ? cor : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Etiqueta de um objeto reconhecido. A do alvo ganha marca-texto e um
/// brilho que acompanha o calor.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.deteccao,
    required this.ehAlvo,
    required this.calor,
  });

  final Deteccao deteccao;
  final bool ehAlvo;
  final double calor;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    return AnimatedContainer(
      duration: motion.d(Motion.quick),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ehAlvo ? c.marker : const Color(0xDD000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ehAlvo ? c.shadow : Colors.white70, width: 2),
        boxShadow: ehAlvo && !t.highContrast
            ? [
                BoxShadow(
                  color: c.marker.withValues(alpha: .25 + .45 * calor),
                  blurRadius: 8 + 16 * calor,
                ),
              ]
            : null,
      ),
      child: Text(
        deteccao.alvo.nome,
        textAlign: TextAlign.center,
        style: text.titleMedium?.copyWith(
          color: ehAlvo ? c.onMarker : Colors.white,
        ),
      ),
    );
  }
}

/// Aparece com um pulinho (escala + opacidade) na primeira vez que é
/// montado. Com movimento reduzido, aparece direto.
class _Surgir extends StatelessWidget {
  const _Surgir({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
      duration: motion.d(Motion.base),
      curve: Motion.pop,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: .6 + .4 * v, child: child),
      ),
      child: child,
    );
  }
}

/// Desenha a grade da câmera, a varredura do radar, as ondas no ritmo da
/// vibração e a mira.
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.tempo,
    required this.trava,
    required this.ondas,
    required this.vidaOnda,
    required this.calor,
    required this.animar,
    required this.frio,
    required this.quente,
  }) : super(repaint: Listenable.merge([tempo, trava]));

  final ValueNotifier<double> tempo;
  final Animation<double> trava;
  final List<double> ondas;
  final double vidaOnda;
  final double calor;
  final bool animar;
  final Color frio;
  final Color quente;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raioMax = size.longestSide * .62;
    final cor = Color.lerp(frio, quente, calor)!;
    final s = animar ? tempo.value : 0.0;

    // Grade "regra dos terços" e anéis de alcance (fixos).
    final grade = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grade);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }
    final aneis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = cor.withValues(alpha: .14);
    for (final f in const [.22, .44, .66]) {
      canvas.drawCircle(centro, raioMax * f, aneis);
    }

    if (animar) {
      // Varredura do radar: um leque com rastro que gira sem parar.
      const abertura = math.pi / 2.4;
      final angulo = s * 2 * math.pi / 3.2;
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(angulo);
      final rect = Rect.fromCircle(center: Offset.zero, radius: raioMax);
      canvas.drawArc(
        rect,
        0,
        abertura,
        true,
        Paint()
          ..shader = SweepGradient(
            endAngle: abertura,
            colors: [
              cor.withValues(alpha: 0),
              cor.withValues(alpha: .32 + .18 * calor),
            ],
          ).createShader(rect),
      );
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(abertura), math.sin(abertura)) * raioMax,
        Paint()
          ..color = cor.withValues(alpha: .8)
          ..strokeWidth = 2,
      );
      canvas.restore();

      // Ondas no ritmo da vibração: quanto mais quente, mais juntas.
      for (final o in ondas) {
        final idade = ((s - o) / vidaOnda).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(idade);
        canvas.drawCircle(
          centro,
          36 + (raioMax - 36) * e,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 + 3 * (1 - idade)
            ..color = cor.withValues(alpha: (1 - idade) * (.3 + .5 * calor)),
        );
      }
    }

    // Mira: cantoneiras que apertam conforme esquenta e dão um estalo ao
    // travar no alvo.
    final estalo = 1 - Curves.easeOutBack.transform(trava.value);
    final meio = (56 - 22 * calor) * (1 + .7 * estalo);
    final braco = meio * .45;
    final giro = animar ? (1 - calor) * .14 * math.sin(s * 1.7) : 0.0;
    final corMira = Color.lerp(
      Colors.white.withValues(alpha: .8),
      quente,
      calor,
    )!;
    if (calor > .9) {
      canvas.drawCircle(
        centro,
        meio * .9,
        Paint()..color = quente.withValues(alpha: .18 * calor),
      );
    }
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(giro);
    final mira = Paint()
      ..color = corMira
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + 2 * calor
      ..strokeCap = StrokeCap.round;
    for (final (sx, sy) in const [
      (-1.0, -1.0),
      (1.0, -1.0),
      (1.0, 1.0),
      (-1.0, 1.0),
    ]) {
      final canto = Offset(sx * meio, sy * meio);
      canvas.drawLine(canto, canto - Offset(sx * braco, 0), mira);
      canvas.drawLine(canto, canto - Offset(0, sy * braco), mira);
    }
    canvas.drawCircle(Offset.zero, 3 + 2 * calor, Paint()..color = corMira);
    canvas.restore();

    // Vinheta de lente nas bordas.
    final tudo = Offset.zero & size;
    canvas.drawRect(
      tudo,
      Paint()
        ..shader = RadialGradient(
          radius: .75,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .4)],
          stops: const [.6, 1],
        ).createShader(tudo),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.calor != calor ||
      old.animar != animar ||
      old.frio != frio ||
      old.quente != quente;
}
