import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/burst.dart';
import '../../domain/rules/assistencia.dart';

/// Animações do Ajuda+.
///
/// Todas são enfeite: o estado continua em texto e semântica. Com o
/// movimento reduzido (sistema ou "Redução de estímulos"), tudo aparece
/// direto no estado final. Nenhuma animação se repete sem parar.

// ───────────────────────── Entrada em cascata ─────────────────────────

/// Sobe e aparece com atraso proporcional ao [index].
///
/// Diferente do Entrance, usa um único controlador com intervalo (sem
/// timers soltos), então termina junto com o restante da tela.
class Surgir extends StatefulWidget {
  const Surgir({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Surgir> createState() => _SurgirState();
}

class _SurgirState extends State<Surgir> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final atraso = Motion.stagger * widget.index;
    final total = atraso + Motion.base;
    _c = AnimationController(vsync: this, duration: total);
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(
        atraso.inMilliseconds / total.inMilliseconds,
        1,
        curve: Motion.enter,
      ),
    );
  }

  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (Motion.of(context).enabled) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.of(context).enabled && _c.value < 1) _c.value = 1;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ───────────────────────── Tremidinha ─────────────────────────

/// Balança de leve para os lados, uma vez, ao aparecer (se [aoAparecer])
/// e sempre que [gatilho] mudar. Usado para "faltou escolher" e "cancelado".
class Tremor extends StatefulWidget {
  const Tremor({
    super.key,
    required this.child,
    this.gatilho = 0,
    this.aoAparecer = false,
  });

  final Widget child;
  final int gatilho;
  final bool aoAparecer;

  @override
  State<Tremor> createState() => _TremorState();
}

class _TremorState extends State<Tremor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _iniciado = false;

  void _tremer() {
    if (Motion.of(context).enabled) _c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (widget.aoAparecer) _tremer();
  }

  @override
  void didUpdateWidget(Tremor old) {
    super.didUpdateWidget(old);
    if (old.gatilho != widget.gatilho) _tremer();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.of(context).enabled && _c.isAnimating) _c.value = 1;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ───────────────────────── Confete ─────────────────────────

/// Chuva de confete desenhada por cima do [child], uma única vez a cada
/// [ConfeteState.play]. Não acontece com movimento reduzido.
class Confete extends StatefulWidget {
  const Confete({
    super.key,
    required this.child,
    this.quantidade = 28,
    this.forca = 120,
    this.origem = Alignment.center,
    this.duracao = const Duration(milliseconds: 1100),
    this.aoAparecer = false,
  });

  final Widget child;
  final int quantidade;

  /// Distância (px) que os papéis percorrem.
  final double forca;
  final Alignment origem;
  final Duration duracao;

  /// Dispara sozinho ao entrar na tela.
  final bool aoAparecer;

  @override
  State<Confete> createState() => ConfeteState();
}

class ConfeteState extends State<Confete> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duracao,
  );
  bool _iniciado = false;

  void play() {
    if (!mounted || !Motion.of(context).enabled) return;
    _c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (widget.aoAparecer) play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    if (!Motion.of(context).enabled && _c.isAnimating) _c.value = 1;
    return CustomPaint(
      foregroundPainter: _ConfetePainter(
        _c,
        [c.help, c.marker, c.navigation, c.simulation],
        widget.quantidade,
        widget.forca,
        widget.origem,
      ),
      child: widget.child,
    );
  }
}

class _ConfetePainter extends CustomPainter {
  _ConfetePainter(this.a, this.cores, this.n, this.forca, this.origem)
    : super(repaint: a);

  final Animation<double> a;
  final List<Color> cores;
  final int n;
  final double forca;
  final Alignment origem;

  @override
  void paint(Canvas canvas, Size size) {
    final t = a.value;
    if (t == 0 || t == 1) return;
    final centro = origem.alongSize(size);
    final sorte = math.Random(7); // mesma "chuva" sempre
    final voo = Curves.easeOutCubic.transform(t);
    final alfa = t < .7 ? 1.0 : (1 - t) / .3;
    final paint = Paint();
    for (var i = 0; i < n; i++) {
      // Leque para cima, com um pouco para os lados.
      final ang = -math.pi / 2 + (sorte.nextDouble() - .5) * math.pi * 1.5;
      final vel = forca * (.55 + .45 * sorte.nextDouble());
      final giro = (sorte.nextDouble() - .5) * 14;
      final w = 5 + sorte.nextDouble() * 5;
      final h = 3 + sorte.nextDouble() * 3;
      final pos =
          centro +
          Offset(math.cos(ang), math.sin(ang)) * vel * voo +
          Offset(0, 90 * t * t); // gravidade
      paint.color = cores[i % cores.length].withValues(alpha: alfa);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(giro * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfetePainter old) =>
      old.n != n || old.forca != forca || old.origem != origem;
}

// ───────────────────────── Selo "enviado" ─────────────────────────

/// Círculo limão que cresce e um "✓" que se desenha sozinho, com confete.
/// Decorativo: o texto da tela já informa que o pedido foi registrado.
class SeloEnviado extends StatelessWidget {
  const SeloEnviado({super.key, this.tamanho = 52});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    return ExcludeSemantics(
      child: Confete(
        aoAparecer: true,
        quantidade: 22,
        forca: 90,
        duracao: const Duration(milliseconds: 1000),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
          duration: motion.d(const Duration(milliseconds: 900)),
          builder: (context, t, _) {
            final cresce = Curves.elasticOut.transform(
              (t / .45).clamp(0.0, 1.0),
            );
            final traco = Curves.easeOutCubic.transform(
              ((t - .35) / .65).clamp(0.0, 1.0),
            );
            return Transform.scale(
              scale: cresce,
              child: CustomPaint(
                size: Size.square(tamanho),
                painter: _CheckPainter(traco, c.help, c.onAccent, c.shadow),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.fundo, this.traco, this.borda);
  final double t;
  final Color fundo;
  final Color traco;
  final Color borda;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final centro = size.center(Offset.zero);
    canvas.drawCircle(
      centro + const Offset(3, 3),
      r - 1,
      Paint()..color = borda,
    );
    canvas.drawCircle(centro, r - 1, Paint()..color = fundo);
    canvas.drawCircle(
      centro,
      r - 1,
      Paint()
        ..color = borda
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (t <= 0) return;
    final s = size.shortestSide;
    final check = Path()
      ..moveTo(s * .28, s * .52)
      ..lineTo(s * .44, s * .67)
      ..lineTo(s * .73, s * .36);
    final metrica = check.computeMetrics().toList();
    final total = metrica.fold<double>(0, (a, m) => a + m.length);
    var resta = total * t;
    final parcial = Path();
    for (final m in metrica) {
      final pedaco = math.min(resta, m.length);
      parcial.addPath(m.extractPath(0, pedaco), Offset.zero);
      resta -= pedaco;
      if (resta <= 0) break;
    }
    canvas.drawPath(
      parcial,
      Paint()
        ..color = traco
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.t != t ||
      old.fundo != fundo ||
      old.traco != traco ||
      old.borda != borda;
}

// ───────────────────────── Pino do local ─────────────────────────

/// Pino que "cai" e quica no lugar sempre que o [local] muda.
class PinoCaindo extends StatelessWidget {
  const PinoCaindo({super.key, required this.local});

  final String local;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: 32,
        height: 36,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(local),
          tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
          duration: motion.d(const Duration(milliseconds: 750)),
          builder: (context, t, _) {
            final queda = Curves.bounceOut.transform(t);
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Sombrinha no chão: cresce conforme o pino chega.
                Container(
                  width: 18 * (.4 + .6 * queda),
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.inkMuted.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Positioned(
                  bottom: 2 + 34 * (1 - queda),
                  child: Opacity(
                    opacity: (t * 4).clamp(0.0, 1.0),
                    child: Icon(Icons.location_on, color: c.help, size: 30),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Progresso das 3 etapas ─────────────────────────

/// Cabeçalho "Pedir → Revisar → Acompanhar". A barra se preenche e a
/// bolinha da etapa atual cresce. O leitor de tela ouve "Passo 2 de 3".
class ProgressoEtapas extends StatelessWidget {
  const ProgressoEtapas({super.key, required this.atual});

  /// 0, 1 ou 2.
  final int atual;

  static const _nomes = ['Pedir', 'Revisar', 'Acompanhar'];

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    return Semantics(
      label: tr(context, 'Passo ${atual + 1} de 3: ${_nomes[atual]}'),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: atual.toDouble()),
        duration: motion.d(const Duration(milliseconds: 520)),
        curve: Curves.easeInOutCubic,
        builder: (context, p, _) => Column(
          children: [
            SizedBox(
              height: 34,
              child: LayoutBuilder(
                builder: (context, box) {
                  // Centros das bolinhas: no meio de cada terço.
                  final terco = box.maxWidth / 3;
                  final ini = terco / 2;
                  final fim = box.maxWidth - terco / 2;
                  final cheio = (fim - ini) * (p / 2);
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: ini,
                        width: fim - ini,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.inkMuted.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: ini,
                        width: cheio,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.help,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          left: terco * i,
                          width: terco,
                          child: Center(child: _bolinha(c, text, i, p)),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AcessaSpacing.xs),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Text(
                      tr(context, _nomes[i]),
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: i == atual ? c.ink : c.inkMuted,
                        fontWeight: i == atual ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bolinha(AcessaColors c, TextTheme text, int i, double p) {
    // Quanto a etapa "i" está ativa (0..1), para crescer e acender suave.
    final ativa = (1 - (p - i).abs()).clamp(0.0, 1.0);
    final feita = p >= i - .01;
    final tam = 24 + 8 * ativa;
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: feita ? c.help : c.surface,
        border: Border.all(color: feita ? c.shadow : c.border, width: 2),
      ),
      child: i < p - .5
          ? Icon(Icons.check, size: 16, color: c.onAccent)
          : Text(
              '${i + 1}',
              style: text.labelMedium?.copyWith(
                color: feita ? c.onAccent : c.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

// ───────────────────────── Linha do tempo ─────────────────────────

/// Linha do tempo dos estados (RF40), com o atual em destaque.
///
/// A linha "escorre" até o estado novo; cada bolinha alcançada pula com
/// faíscas; em "Apoio a caminho" um bonequinho caminha até você; em
/// "Concluída", confete.
class LinhaDoTempo extends StatefulWidget {
  const LinhaDoTempo({super.key, required this.atual});
  final EstadoPedido atual;

  @override
  State<LinhaDoTempo> createState() => _LinhaDoTempoState();
}

class _LinhaDoTempoState extends State<LinhaDoTempo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
    vsync: this,
    upperBound: (EstadoPedido.values.length - 1).toDouble(),
    value: widget.atual.index.toDouble(),
  );
  final _confete = GlobalKey<ConfeteState>();

  @override
  void didUpdateWidget(LinhaDoTempo old) {
    super.didUpdateWidget(old);
    if (old.atual == widget.atual) return;
    final alvo = widget.atual.index.toDouble();
    if (!Motion.of(context).enabled) {
      _p.value = alvo;
      return;
    }
    final passos = (alvo - _p.value).abs().clamp(1.0, 3.0);
    _p
        .animateTo(
          alvo,
          duration: Motion.slow * passos,
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (mounted && widget.atual == EstadoPedido.concluida) {
            _confete.currentState?.play();
          }
        });
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    if (!Motion.of(context).enabled && _p.isAnimating) {
      _p.value = widget.atual.index.toDouble();
    }
    final ultimo = EstadoPedido.values.length - 1;
    return Confete(
      key: _confete,
      quantidade: 60,
      forca: 220,
      origem: const Alignment(0, .9),
      duracao: const Duration(milliseconds: 1600),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AcessaSpacing.md,
          vertical: AcessaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AcessaRadius.card),
          border: Border.all(color: c.border, width: AcessaSticker.borderWidth),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              offset: AcessaSticker.shadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _p,
          builder: (context, _) {
            final p = _p.value;
            return Column(
              children: [
                for (final e in EstadoPedido.values)
                  _linha(
                    context,
                    c,
                    text,
                    e,
                    p,
                    primeira: e.index == 0,
                    ultima: e.index == ultimo,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _linha(
    BuildContext context,
    AcessaColors c,
    TextTheme text,
    EstadoPedido e,
    double p, {
    required bool primeira,
    required bool ultima,
  }) {
    final atual = widget.atual;
    final i = e.index.toDouble();
    // Metade de cima enche de i-0,5 até i; a de baixo, de i até i+0,5.
    double enche(double de) => ((p - de) / .5).clamp(0.0, 1.0);
    final alcancado = p >= i - 1e-6;

    return MergeSemantics(
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Expanded(
                      child: _Trilho(
                        visivel: !primeira,
                        cheio: enche(i - .5),
                        trilho: c.inkMuted.withValues(alpha: .4),
                        cor: c.help,
                      ),
                    ),
                    _Bolinha(
                      alcancada: alcancado,
                      numero: e.index + 1,
                      atual: e == atual,
                    ),
                    Expanded(
                      child: _Trilho(
                        visivel: !ultima,
                        cheio: enche(i),
                        trilho: c.inkMuted.withValues(alpha: .4),
                        cor: c.help,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AcessaSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AcessaSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, e.texto),
                        style: text.titleMedium?.copyWith(
                          fontWeight: e == atual ? FontWeight.w700 : null,
                          color: e.index <= atual.index ? c.ink : c.inkMuted,
                        ),
                      ),
                      if (e == atual)
                        Surgir(
                          key: ValueKey(e),
                          index: 3,
                          child: Text(
                            tr(context, 'Etapa atual'),
                            style: text.bodyMedium?.copyWith(color: c.inkMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (e == EstadoPedido.aCaminho && atual == EstadoPedido.aCaminho)
                const _Caminhante(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pedaço da linha vertical: trilho apagado + parte já percorrida.
class _Trilho extends StatelessWidget {
  const _Trilho({
    required this.visivel,
    required this.cheio,
    required this.trilho,
    required this.cor,
  });

  final bool visivel;
  final double cheio;
  final Color trilho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    if (!visivel) return const SizedBox.shrink();
    // Pintado (sem FractionallySizedBox), pois a linha usa IntrinsicHeight.
    return CustomPaint(
      size: const Size(40, 0),
      painter: _TrilhoPainter(cheio, trilho, cor),
    );
  }
}

class _TrilhoPainter extends CustomPainter {
  _TrilhoPainter(this.cheio, this.trilho, this.cor);
  final double cheio;
  final Color trilho;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2 - 2;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, 4, size.height),
      Paint()..color = trilho,
    );
    if (cheio <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, 4, size.height * cheio),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_TrilhoPainter old) =>
      old.cheio != cheio || old.trilho != trilho || old.cor != cor;
}

/// Bolinha do estado: quando a linha chega até ela, acende, pula e solta
/// faíscas (uma vez).
class _Bolinha extends StatefulWidget {
  const _Bolinha({
    required this.alcancada,
    required this.numero,
    required this.atual,
  });

  final bool alcancada;
  final int numero;
  final bool atual;

  @override
  State<_Bolinha> createState() => _BolinhaState();
}

class _BolinhaState extends State<_Bolinha>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  final _faisca = GlobalKey<BurstState>();

  @override
  void didUpdateWidget(_Bolinha old) {
    super.didUpdateWidget(old);
    if (!old.alcancada && widget.alcancada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !Motion.of(context).enabled) return;
        _pulo.forward(from: 0);
        _faisca.currentState?.play();
      });
    }
  }

  @override
  void dispose() {
    _pulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final ok = widget.alcancada;
    return Burst(
      key: _faisca,
      color: c.help,
      child: AnimatedBuilder(
        animation: _pulo,
        builder: (context, child) => Transform.scale(
          scale: 1 + .35 * math.sin(math.pi * _pulo.value),
          child: child,
        ),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? c.help : c.surface,
            border: Border.all(
              color: widget.atual && ok ? c.shadow : c.border,
              width: 2,
            ),
          ),
          child: ok
              ? Icon(Icons.check, color: c.onAccent, size: 22)
              : Text('${widget.numero}', style: text.titleMedium),
        ),
      ),
    );
  }
}

/// Bonequinho que caminha (uma vez) pela trilha pontilhada até parar
/// perto do texto "Apoio a caminho".
class _Caminhante extends StatelessWidget {
  const _Caminhante();

  static const _largura = 88.0;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: _largura,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
          duration: motion.d(const Duration(milliseconds: 1800)),
          curve: Curves.easeOutSine,
          builder: (context, t, _) {
            // Passinhos: sobe e desce 5 vezes e para no fim.
            final passo = math.sin(t * math.pi * 10).abs() * 4 * (1 - t);
            // Sem LayoutBuilder: a linha do tempo usa IntrinsicHeight.
            final x = (_largura - 28) * (1 - t);
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Pontilhado(
                      c.inkMuted.withValues(alpha: .6),
                      inicio: x + 14,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: x),
                  child: Transform.translate(
                    offset: Offset(0, -passo),
                    child: Transform.flip(
                      flipX: true,
                      child: Icon(
                        Icons.directions_walk,
                        color: c.help,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Rastro pontilhado deixado pelo bonequinho (do [inicio] até a direita).
class _Pontilhado extends CustomPainter {
  _Pontilhado(this.cor, {required this.inicio});
  final Color cor;
  final double inicio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cor;
    for (var x = inicio; x < size.width; x += 8) {
      canvas.drawCircle(Offset(x, size.height / 2 + 15), 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(_Pontilhado old) => old.inicio != inicio || old.cor != cor;
}
