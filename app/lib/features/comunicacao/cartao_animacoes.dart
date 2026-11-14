import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';

/// Animações do Cartão de ajuda.
///
/// Todas são enfeite: terminam sozinhas (nada se repete) e, com movimento
/// reduzido (sistema ou "Redução de estímulos"), o conteúdo aparece na
/// hora, já no estado final. Nenhuma informação depende delas.

/// Amarelo-marca-texto do cartão (preto sobre ele passa de 15:1).
const amareloCartao = Color(0xFFFFE14D);

/// Rosa da Comunicação Universal, usado só em enfeites (pontinhos).
const rosaComunicacao = Color(0xFFFF5C9D);

/// Chave do giro da metade de cima ("Frente a frente").
const chaveGiroLeitor = ValueKey('giro-leitor');

/// Como o item entra na tela.
enum EstiloEntrada {
  /// Carta de baralho: girada, menor, e encaixa com leve pulo.
  leque,

  /// Sobe alguns pixels e aparece.
  subir,

  /// Cresce com um pulinho (botões de resposta).
  saltar,
}

/// Entrada em cascata guiada só por quadros (sem Timer): cada item espera
/// [Motion.stagger] × [index] + [atraso] dentro do próprio controlador.
/// Assim os testes com `pumpAndSettle` nunca ficam com relógio pendente.
class DistribuirCarta extends StatefulWidget {
  const DistribuirCarta({
    super.key,
    required this.index,
    required this.child,
    this.estilo = EstiloEntrada.subir,
    this.atraso = Duration.zero,
  });

  final int index;
  final Widget child;
  final EstiloEntrada estilo;
  final Duration atraso;

  @override
  State<DistribuirCarta> createState() => _DistribuirCartaState();
}

class _DistribuirCartaState extends State<DistribuirCarta>
    with SingleTickerProviderStateMixin {
  late final Duration _espera = widget.atraso + Motion.stagger * widget.index;
  late final Duration _anim = switch (widget.estilo) {
    EstiloEntrada.subir => Motion.base,
    EstiloEntrada.leque => const Duration(milliseconds: 650),
    EstiloEntrada.saltar => const Duration(milliseconds: 520),
  };
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _espera + _anim,
  );
  late final Animation<double> _v = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _espera.inMicroseconds / (_espera + _anim).inMicroseconds,
      1,
    ),
  );
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.of(context).enabled) {
      // Sem movimento (ou desligado no meio): estado final na hora.
      _c.value = 1;
    } else if (!_iniciado) {
      _c.forward();
    }
    _iniciado = true;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _v,
      child: widget.child,
      builder: (context, child) {
        // Estrutura estável: no fim, os mesmos widgets com valores neutros,
        // para não recriar (e perder o estado de) quem está dentro.
        final v = _v.value;
        switch (widget.estilo) {
          case EstiloEntrada.subir:
            final e = Motion.enter.transform(v);
            return Opacity(
              opacity: e,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - e)),
                child: child,
              ),
            );
          case EstiloEntrada.leque:
            final e = Curves.easeOutBack.transform(v);
            final lado = widget.index.isEven ? -1.0 : 1.0;
            return Opacity(
              opacity: Curves.easeOut.transform(v),
              child: Transform.translate(
                offset: Offset(lado * 48 * (1 - e), 70 * (1 - e)),
                child: Transform.rotate(
                  angle: lado * .2 * (1 - e),
                  child: Transform.scale(scale: .85 + .15 * e, child: child),
                ),
              ),
            );
          case EstiloEntrada.saltar:
            return Opacity(
              opacity: Curves.easeOut.transform(math.min(1, v * 2)),
              child: Transform.scale(
                scale: .5 + .5 * Curves.elasticOut.transform(v),
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// Afunda um pouquinho enquanto o dedo está em cima, como um adesivo
/// sendo pressionado. Não intercepta o toque (só observa o ponteiro).
class Pressionavel extends StatefulWidget {
  const Pressionavel({super.key, required this.child});

  final Widget child;

  @override
  State<Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<Pressionavel> {
  bool _baixo = false;

  void _marcar(bool v) {
    if (_baixo != v) setState(() => _baixo = v);
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final baixo = _baixo && motion.enabled;
    return Listener(
      onPointerDown: (_) => _marcar(true),
      onPointerUp: (_) => _marcar(false),
      onPointerCancel: (_) => _marcar(false),
      child: AnimatedSlide(
        offset: baixo ? const Offset(.006, .03) : Offset.zero,
        duration: motion.d(Motion.quick),
        curve: Motion.enter,
        child: AnimatedScale(
          scale: baixo ? .965 : 1,
          duration: motion.d(Motion.quick),
          curve: Motion.enter,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Abre o cartão "crescendo" a partir do item tocado (container transform):
/// um retângulo branco sai do tamanho do item e ocupa a tela, os cantos
/// arredondados se endireitam e o conteúdo aparece. Ao fechar, ele encolhe
/// de volta para o item. Com movimento reduzido, a troca é instantânea.
Route<T> rotaExpandir<T>(BuildContext context, Widget pagina, {Rect? origem}) {
  final ligado = Motion.of(context).enabled && origem != null;
  return PageRouteBuilder<T>(
    pageBuilder: (context, _, _) => pagina,
    transitionDuration: ligado
        ? const Duration(milliseconds: 560)
        : Duration.zero,
    reverseTransitionDuration: ligado
        ? const Duration(milliseconds: 380)
        : Duration.zero,
    transitionsBuilder: (context, animation, _, child) {
      if (!ligado || !Motion.of(context).enabled) return child;
      final curva = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubicEmphasized,
        reverseCurve: Curves.easeInCubic,
      );
      final conteudo = CurvedAnimation(
        parent: animation,
        curve: const Interval(.3, 1, curve: Curves.easeOut),
        reverseCurve: const Interval(.5, 1, curve: Curves.easeIn),
      );
      return AnimatedBuilder(
        animation: curva,
        child: child,
        builder: (context, child) {
          final t = curva.value;
          final tela = Offset.zero & MediaQuery.sizeOf(context);
          final r = Rect.lerp(origem, tela, t)!;
          final forma = RRect.fromRectAndRadius(
            r,
            Radius.circular(AcessaRadius.card * (1 - t)),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  clipper: _Recorte(forma),
                  child: ColoredBox(
                    color: Colors.white,
                    child: FadeTransition(opacity: conteudo, child: child),
                  ),
                ),
              ),
              // Contorno de adesivo que some quando o cartão toma a tela.
              Positioned.fromRect(
                rect: r,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AcessaRadius.card * (1 - t),
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 1 - t),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Recorte extends CustomClipper<RRect> {
  const _Recorte(this.forma);
  final RRect forma;

  @override
  RRect getClip(Size size) => forma;

  @override
  bool shouldReclip(_Recorte old) => old.forma != forma;
}

/// Gira o [child] meia volta (180°) quando [virado]: a metade de cima fica
/// de cabeça para baixo para quem está do outro lado da mesa. No meio do
/// giro o cartão "respira" (encolhe um pouco), como se fosse virado à mão.
/// Continua tocável: o Transform também transforma os toques.
class MeiaVolta extends StatelessWidget {
  const MeiaVolta({super.key, required this.virado, required this.child});

  final bool virado;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: virado ? 1 : 0),
      duration: motion.d(const Duration(milliseconds: 750)),
      curve: Curves.easeInOutCubic,
      child: child,
      builder: (context, t, child) => Transform.rotate(
        key: chaveGiroLeitor,
        angle: t * math.pi,
        child: Transform.scale(
          scale: 1 - .12 * math.sin(t * math.pi),
          child: child,
        ),
      ),
    );
  }
}

/// Passa um destaque uma única vez quando aparece:
/// - padrão: marca-texto amarelo que se desenha atrás do texto e depois se
///   recolhe, com uma leve "onda" (balanço) que chama a atenção;
/// - [brilho]: uma faixa de luz que atravessa a caixa, por trás do texto.
/// O texto continua preto: o contraste só aumenta durante o efeito.
class Varredura extends StatelessWidget {
  const Varredura({
    super.key,
    required this.child,
    this.atraso = Duration.zero,
    this.brilho = false,
    this.ativo = true,
  });

  final Widget child;
  final Duration atraso;
  final bool brilho;
  final bool ativo;

  static const _duracao = Duration(milliseconds: 1100);

  @override
  Widget build(BuildContext context) {
    if (!ativo || !Motion.of(context).enabled) return child;
    final total = atraso + _duracao;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(atraso.inMicroseconds / total.inMicroseconds, 1),
      child: child,
      builder: (context, u, child) {
        // Estrutura estável (mesmos widgets do início ao fim) para não
        // recriar o conteúdo quando o efeito termina.
        final animando = u > 0 && u < 1;
        if (brilho) {
          return CustomPaint(
            painter: animando ? _BrilhoPainter(u) : null,
            child: child,
          );
        }
        // Onda: um balanço que diminui até parar no lugar certo.
        final onda = animando ? math.sin(u * 3 * math.pi) * (1 - u) : 0.0;
        final cresce = animando ? math.sin(u * math.pi) * (1 - u) : 0.0;
        return CustomPaint(
          painter: animando ? _MarcaTextoPainter(u) : null,
          child: Transform.rotate(
            angle: .025 * onda,
            child: Transform.scale(
              scale: 1 + .05 * cresce,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _MarcaTextoPainter extends CustomPainter {
  _MarcaTextoPainter(this.u);
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    // Primeira metade desenha da esquerda para a direita; a segunda recolhe.
    final fim = size.width * Motion.enter.transform(math.min(1, u * 2));
    final inicio =
        size.width * Curves.easeInCubic.transform(math.max(0, u * 2 - 1));
    if (fim - inicio <= 0) return;
    final skew = 10.0;
    final path = Path()
      ..moveTo(inicio + skew, 0)
      ..lineTo(fim + skew, -2)
      ..lineTo(fim - skew, size.height)
      ..lineTo(inicio - skew, size.height + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = amareloCartao);
  }

  @override
  bool shouldRepaint(_MarcaTextoPainter old) => old.u != u;
}

class _BrilhoPainter extends CustomPainter {
  _BrilhoPainter(this.u);
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final largura = size.width * .28;
    final x = -largura + (size.width + largura * 2) * Motion.enter.transform(u);
    final path = Path()
      ..moveTo(x, 0)
      ..lineTo(x + largura * .6, 0)
      ..lineTo(x + largura * .6 - 24, size.height)
      ..lineTo(x - 24, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: .55 * (1 - u)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrilhoPainter old) => old.u != u;
}

/// Pulinho de comemoração (cresce e volta) — usado no botão de resposta,
/// junto com os pontinhos do Burst. Dispare com `chave.currentState?.play()`.
class Pulinho extends StatefulWidget {
  const Pulinho({super.key, required this.child});

  final Widget child;

  @override
  State<Pulinho> createState() => PulinhoState();
}

class PulinhoState extends State<Pulinho> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        // Sobe rápido, desce com um quique amortecido.
        final s = 1 + .16 * math.sin(v * math.pi) * (1 - v * .5);
        return Transform.scale(scale: s, child: child);
      },
    );
  }
}
