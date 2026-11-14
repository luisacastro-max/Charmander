import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/icones.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/rules/alertas_apresentacao.dart';
import '../../domain/rules/ocorrencias.dart' show agrupar;
import '../../domain/rules/viagem.dart';
import '../alertas/alertas_controller.dart';
import '../alertas/alertas_visual.dart';
import '../alertas/detalhes_alerta.dart';
import '../welcome_preferences/preferences.dart';

/// Tamanho do desenho do shopping, em unidades do cadastro
/// (catalogo.json → "mapa").
const _larguraMapa = 400.0;
const _alturaMapa = 260.0;

/// Zoom do modo GPS em relação à visão do piso inteiro.
const _zoomGps = 2.6;

/// Mapa interativo no estilo GPS (RF17, RF19, RF48).
///
/// - **Segue você**: zoom no ponto atual e o mapa gira para que a direção
///   da caminhada fique para cima (como num GPS de carro).
/// - **Norte do mapa para cima**: alternativa sem giro, para quem se
///   desorienta com o mapa girando.
/// - Ao chegar a cada beacon (simulado), a seta desliza até o novo ponto.
///   Com movimento reduzido, pula direto.
/// - Arrastar ou pinçar solta o mapa; "Recentralizar" volta a seguir.
///
/// O mapa é complemento: tudo o que ele mostra também está em texto na
/// tela de navegação e na descrição para leitores de tela.
class MapaInterativo extends StatefulWidget {
  const MapaInterativo({
    super.key,
    required this.dados,
    required this.estado,
    this.altura = 420,
    this.rotaMaisUsada,
    this.exploracao = false,
  });

  final ShoppingData dados;
  final EstadoNavegacao estado;
  final double altura;

  /// Rota mais usada (sem preferências), desenhada tracejada e esmaecida
  /// atrás da rota adaptada. Nula quando as duas são iguais.
  final Viagem? rotaMaisUsada;

  /// Modo exploração (mapa de alertas, fora de uma rota): mostra o piso
  /// inteiro, sem linha de rota nem paradas, e ajusta legenda e descrição.
  /// Use com um [EstadoNavegacao] de rota de um ponto só (origem = destino).
  final bool exploracao;

  @override
  State<MapaInterativo> createState() => _MapaInterativoState();
}

/// Câmera: ponto do mapa [centro] desenhado em [ancora] da tela, com
/// [k] pixels por unidade do mapa e giro [rot] (radianos).
@immutable
class _Camera {
  const _Camera(this.centro, this.k, this.rot, this.ancora);
  final Offset centro;
  final double k;
  final double rot;
  final Offset ancora;

  Offset tela(Offset m) {
    final d = (m - centro) * k;
    final c = math.cos(rot), s = math.sin(rot);
    return ancora + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }

  Offset mapa(Offset t) {
    final d = t - ancora;
    final c = math.cos(-rot), s = math.sin(-rot);
    return centro + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c) / k;
  }

  _Camera copia({Offset? centro, double? k, Offset? ancora}) =>
      _Camera(centro ?? this.centro, k ?? this.k, rot, ancora ?? this.ancora);
}

class _MapaInterativoState extends State<MapaInterativo>
    with TickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Deslocamento da seta entre dois beacons.
  late final AnimationController _mov = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  late String _piso = _pisoAtual;
  late bool _seguir = !widget.exploracao;
  late bool _norteParaCima = widget.exploracao;
  double _zoom = 1;

  /// Câmera livre (depois de arrastar, pinçar ou ver a rota inteira).
  _Camera? _livre;
  double _kInicioGesto = 1;
  Size _tam = Size.zero;

  late Offset _posDe = _pos(widget.estado.pontoAtual);
  late Offset _posAte = _posDe;
  late double _rumoDe = widget.estado.direcao ?? 0;
  late double _rumoAte = _rumoDe;

  String get _pisoAtual => widget.estado.pontoAtual.piso ?? '';

  static Offset _pos(PontoReferencia p) => Offset(p.x, p.y);

  double get _t => Curves.easeInOutCubic.transform(_mov.value);
  Offset get _posAgora => Offset.lerp(_posDe, _posAte, _t)!;
  double get _rumoAgora {
    final d = ((_rumoAte - _rumoDe + 540) % 360) - 180;
    return _rumoDe + d * _t;
  }

  /// O pulso de chegada só toca na abertura (e a cada novo beacon), não a
  /// cada mudança de dependência (ex.: alertas novos).
  bool _abriu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_abriu) return;
    _abriu = true;
    _pulsar();
  }

  @override
  void didUpdateWidget(MapaInterativo old) {
    super.didUpdateWidget(old);
    final novo = widget.estado.pontoAtual;
    if (old.estado.pontoAtual.id == novo.id &&
        old.estado.direcao == widget.estado.direcao) {
      return;
    }
    // Ao chegar a um novo beacon: a seta desliza do ponto anterior até o
    // novo e o mapa gira para a próxima direção. O GPS volta a seguir.
    final anterior = old.estado.pontoAtual;
    final andou = direcaoNoMapa(anterior, novo);
    _posDe = _posAgora;
    _rumoDe = _rumoAgora;
    _posAte = _pos(novo);
    _rumoAte =
        widget.estado.direcao ??
        (anterior.x == novo.x && anterior.y == novo.y ? _rumoDe : andou);
    _piso = _pisoAtual;
    _seguir = true;
    _livre = null;
    if (Motion.of(context).enabled) {
      _mov.forward(from: 0);
    } else {
      _mov.value = 1;
    }
    _pulsar();
  }

  void _pulsar() {
    if (Motion.of(context).enabled) {
      _pulso.repeat(count: 3);
    } else {
      _pulso.value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    _mov.dispose();
    super.dispose();
  }

  double get _kPiso =>
      math.min(_tam.width / _larguraMapa, _tam.height / _alturaMapa) * .92;

  _Camera get _cameraPiso => _Camera(
    const Offset(_larguraMapa / 2, _alturaMapa / 2),
    _kPiso,
    0,
    _tam.center(Offset.zero),
  );

  /// Câmera do modo GPS: segue a seta; com "direção para cima", a seta
  /// fica no terço de baixo para mostrar mais caminho à frente.
  _Camera get _cameraGps => _Camera(
    _posAgora,
    _kPiso * _zoomGps * _zoom,
    _norteParaCima ? 0 : -_rumoAgora * math.pi / 180,
    Offset(_tam.width / 2, _tam.height * (_norteParaCima ? .5 : .66)),
  );

  _Camera get _camera => (!_seguir ? _livre : null) ?? _cameraGps;

  void _soltar() {
    if (!_seguir) return;
    final cam = _cameraGps;
    _livre = cam.copia(
      centro: cam.mapa(_tam.center(Offset.zero)),
      ancora: _tam.center(Offset.zero),
    );
    _seguir = false;
  }

  void _recentralizar() => setState(() {
    _seguir = true;
    _livre = null;
    _piso = _pisoAtual;
  });

  void _verRotaInteira() => setState(() {
    _seguir = false;
    _livre = _cameraPiso;
  });

  void _zoomBotao(double f) => setState(() {
    if (_seguir) {
      _zoom = (_zoom * f).clamp(.5, 3.0);
    } else {
      final cam = _livre!;
      _livre = cam.copia(k: (cam.k * f).clamp(_kPiso * .8, _kPiso * 8));
    }
  });

  void _escolherPiso(String p) => setState(() {
    _piso = p;
    if (p == _pisoAtual && !widget.exploracao) {
      _seguir = true;
      _livre = null;
    } else {
      _seguir = false;
      _livre = _cameraPiso;
    }
  });

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final dados = widget.dados;
    final estado = widget.estado;
    final noMeuPiso = _piso == _pisoAtual;
    final alertas = AlertasScope.maybeOf(context);
    final doPiso = alertas?.visiveis(piso: _piso) ?? const <Ocorrencia>[];
    final pendentes = [
      for (final p in alertas?.pendentes ?? const <EnvioPendente>[])
        if (p.nova.piso == _piso) p,
    ];
    final pontos = {for (final p in dados.pontos) p.id: p};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(tr(context, 'Piso:'), style: text.titleMedium),
            for (final p in dados.pisos)
              Semantics(
                selected: _piso == p,
                inMutuallyExclusiveGroup: true,
                child: ChoiceChip(
                  label: Text(tr(context, p == _pisoAtual ? '$p (você)' : p)),
                  selected: _piso == p,
                  onSelected: (_) => _escolherPiso(p),
                  showCheckmark: true,
                  checkmarkColor: c.onPrimary,
                  selectedColor: c.primary,
                  backgroundColor: c.surface,
                  labelStyle: text.labelLarge?.copyWith(
                    color: _piso == p ? c.onPrimary : c.ink,
                  ),
                  side: BorderSide(
                    color: c.border.withValues(alpha: .6),
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
        if (!noMeuPiso) ...[
          const SizedBox(height: AcessaSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: c.simulation),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Text(
                    tr(context, 'Vendo o $_piso. Você está no $_pisoAtual.'),
                    style: text.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _recentralizar,
                  style: TextButton.styleFrom(
                    foregroundColor: c.focus,
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                  ),
                  child: Text(tr(context, 'Ver meu piso')),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AcessaSpacing.sm),
        Container(
          height: widget.altura,
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(AcessaRadius.card),
            border: Border.all(
              color: t.highContrast ? c.border : c.navigation,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, box) {
              _tam = box.biggest;
              if (!_seguir) _livre ??= _cameraPiso;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      container: true,
                      image: true,
                      label: _descricao(context, estado, doPiso, pontos),
                      excludeSemantics: true,
                      child: RawGestureDetector(
                        // O mapa fica com o gesto (a página rola fora dele).
                        gestures: {
                          _EscalaImediata:
                              GestureRecognizerFactoryWithHandlers<
                                _EscalaImediata
                              >(_EscalaImediata.new, (r) {
                                r
                                  ..onStart = (_) {
                                    _soltar();
                                    _kInicioGesto = _livre!.k;
                                  }
                                  ..onUpdate = (d) => setState(() {
                                    final cam = _livre!;
                                    final k = (_kInicioGesto * d.scale).clamp(
                                      _kPiso * .8,
                                      _kPiso * 8,
                                    );
                                    // O ponto que estava sob o dedo continua
                                    // sob o dedo (arrastar e pinçar).
                                    final alvo = cam.mapa(
                                      d.localFocalPoint - d.focalPointDelta,
                                    );
                                    final novo = cam.copia(k: k);
                                    _livre = novo.copia(
                                      centro:
                                          novo.centro +
                                          alvo -
                                          novo.mapa(d.localFocalPoint),
                                    );
                                  });
                              }),
                        },
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_mov, _pulso]),
                          builder: (context, _) => CustomPaint(
                            size: _tam,
                            painter: _PlantaPainter(
                              dados: dados,
                              estado: estado,
                              fantasma: widget.rotaMaisUsada,
                              exploracao: widget.exploracao,
                              piso: _piso,
                              c: c,
                              glow: !t.highContrast,
                              cam: _camera,
                              kPiso: _kPiso,
                              voce: _posAgora,
                              rumo: _rumoAgora,
                              pulso: _pulso.isAnimating ? _pulso.value : 0,
                              idioma: idiomaDe(context),
                              textScale: MediaQuery.textScalerOf(context)
                                  .scale(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Alertas da comunidade: widgets sobre o desenho, na posição
                  // dada pela câmera (acompanham giro e zoom).
                  if (alertas != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _mov,
                        builder: (context, _) => _CamadaAlertas(
                          cam: _camera,
                          tam: _tam,
                          alertas: doPiso,
                          pendentes: pendentes,
                          dados: dados,
                          pontos: pontos,
                        ),
                      ),
                    ),
                  // Bússola: mostra para onde fica o topo do mapa e alterna
                  // entre "direção para cima" e "norte do mapa para cima".
                  Positioned(
                    right: 8,
                    top: 8,
                    child: AnimatedBuilder(
                      animation: _mov,
                      builder: (context, _) => _BotaoMapa(
                        dica: _norteParaCima
                            ? tr(
                                context,
                                'Girar o mapa na direção da caminhada',
                              )
                            : tr(context, 'Deixar o norte do mapa para cima'),
                        onTap: () =>
                            setState(() => _norteParaCima = !_norteParaCima),
                        child: Transform.rotate(
                          angle: _camera.rot,
                          child: Icon(Icons.navigation, color: c.marker),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Column(
                      children: [
                        _BotaoMapa(
                          dica: tr(context, 'Aproximar o mapa'),
                          onTap: () => _zoomBotao(1.4),
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 6),
                        _BotaoMapa(
                          dica: tr(context, 'Afastar o mapa'),
                          onTap: () => _zoomBotao(1 / 1.4),
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 6),
                        _BotaoMapa(
                          dica: tr(
                            context,
                            widget.exploracao
                                ? 'Ver o piso inteiro'
                                : 'Ver a rota inteira',
                          ),
                          onTap: _verRotaInteira,
                          child: const Icon(Icons.zoom_out_map),
                        ),
                      ],
                    ),
                  ),
                  if (!_seguir)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: FilledButton.icon(
                        onPressed: _recentralizar,
                        icon: const Icon(Icons.navigation),
                        label: Text(tr(context, 'Recentralizar')),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          minimumSize: const Size(48, AcessaSpacing.minTouch),
                          textStyle: text.titleMedium,
                          side: BorderSide(color: c.shadow, width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        _Legenda(
          comFantasma: widget.rotaMaisUsada != null,
          exploracao: widget.exploracao,
        ),
        if (alertas != null) ...[
          const SizedBox(height: AcessaSpacing.xs),
          const LegendaAlertas(),
        ],
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          tr(
            context,
            _norteParaCima
                ? 'Norte do mapa para cima. Toque na bússola para o mapa '
                      'girar na direção da caminhada.'
                : 'O mapa gira para a sua direção ficar para cima. Toque na '
                      'bússola para fixar o norte do mapa. Mapa ilustrativo, '
                      'com dados fictícios.',
          ),
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
        if (alertas != null) ...[
          const SizedBox(height: AcessaSpacing.md),
          _ListaAlertasDoPiso(
            alertas: doPiso,
            pendentes: pendentes,
            dados: dados,
            pontos: pontos,
            agora: alertas.relogio(),
          ),
        ],
      ],
    );
  }

  /// O que o mapa mostra, em texto (RNF04: imagem nunca é a única fonte).
  /// Cada frase é traduzida separadamente para o idioma do visitante.
  String _descricao(
    BuildContext context,
    EstadoNavegacao estado,
    List<Ocorrencia> alertas,
    Map<String, PontoReferencia> pontos,
  ) {
    final nesse = <String>[];
    for (final perna in estado.viagem.pernas) {
      for (final p in perna.pontos) {
        if (p.piso == _piso && (nesse.isEmpty || nesse.last != p.nome)) {
          nesse.add(p.nome);
        }
      }
    }
    final frases = <String>[
      'Mapa do $_piso.',
      if (estado.pontoAtual.piso == _piso)
        'Você está em ${estado.pontoAtual.nome}.'
      else
        'Você está no ${estado.pontoAtual.piso}.',
      if (!widget.exploracao) ...[
        if (nesse.isEmpty)
          'A rota não passa por este piso.'
        else
          'Neste piso a rota passa por ${nesse.join(', ')}.',
        if (estado.proximoPonto case final prox?)
          'Próximo ponto: ${prox.nome}.',
      ],
      if (AlertasScope.maybeOf(context) != null) ...[
        resumoAlertasNoPiso(alertas.length),
        for (final o in alertas) fraseDoAlerta(o, pontos),
      ],
      if (widget.rotaMaisUsada != null)
        'A linha tracejada mostra a rota mais usada, que a sua rota evita.',
      _seguir
          ? (_norteParaCima
                ? 'O mapa acompanha você, com o norte do mapa para cima.'
                : 'O mapa acompanha você e gira na direção da caminhada.')
          : 'O mapa está solto; use Recentralizar para voltar a seguir.',
    ];
    return frases.map((f) => tr(context, f)).join(' ');
  }
}

/// Reconhecedor de arrastar/pinçar que fica com o gesto logo no toque,
/// para o mapa não disputar o arrasto com a rolagem da página.
class _EscalaImediata extends ScaleGestureRecognizer {
  _EscalaImediata();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _BotaoMapa extends StatelessWidget {
  const _BotaoMapa({
    required this.child,
    required this.dica,
    required this.onTap,
  });
  final Widget child;
  final String dica;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Material(
      color: c.surface,
      elevation: 2,
      shape: CircleBorder(side: BorderSide(color: c.border, width: 1.5)),
      child: IconButton(
        tooltip: dica,
        onPressed: onTap,
        icon: child,
        color: c.ink,
        constraints: const BoxConstraints(
          minWidth: AcessaSpacing.minTouch,
          minHeight: AcessaSpacing.minTouch,
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({this.comFantasma = false, this.exploracao = false});

  /// Sem rota: só "Você".
  final bool exploracao;

  /// Mostra o item da rota mais usada (tracejada).
  final bool comFantasma;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    Widget item(Widget simbolo, String rotulo) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        simbolo,
        const SizedBox(width: 6),
        Flexible(child: Text(rotulo, style: text.bodyMedium)),
      ],
    );
    Widget linha(Color cor) => Container(
      width: 22,
      height: 6,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: c.shadow),
      ),
    );
    return Wrap(
      spacing: AcessaSpacing.md,
      runSpacing: AcessaSpacing.xs,
      children: [
        item(
          Icon(Icons.navigation, size: 18, color: c.marker),
          tr(context, 'Você'),
        ),
        if (!exploracao) ...[
          item(linha(c.navigation), tr(context, 'A percorrer')),
          item(
            linha(c.inkMuted.withValues(alpha: .5)),
            tr(context, 'Já percorrido'),
          ),
          if (comFantasma)
            item(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var k = 0; k < 3; k++)
                    Container(
                      width: 6,
                      height: 4,
                      margin: const EdgeInsets.only(right: 2),
                      color: c.inkMuted,
                    ),
                ],
              ),
              tr(context, 'Rota mais usada (tracejada)'),
            ),
          item(
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.help,
                shape: BoxShape.circle,
                border: Border.all(color: c.ink, width: 2),
              ),
              child: Text(
                '1',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.onAccent,
                ),
              ),
            ),
            tr(context, 'Parada'),
          ),
        ],
      ],
    );
  }
}

/// Desenha o piso pela câmera. Linhas giram com o mapa; ícones e nomes
/// ficam sempre de pé e com tamanho fixo na tela, como num GPS.
class _PlantaPainter extends CustomPainter {
  _PlantaPainter({
    required this.dados,
    required this.estado,
    required this.fantasma,
    required this.exploracao,
    required this.piso,
    required this.c,
    required this.glow,
    required this.cam,
    required this.kPiso,
    required this.voce,
    required this.rumo,
    required this.pulso,
    required this.textScale,
    required this.idioma,
  });

  final ShoppingData dados;
  final EstadoNavegacao estado;

  /// Rota mais usada, tracejada atrás da rota do visitante.
  final Viagem? fantasma;

  /// Sem rota (mapa de alertas): não desenha paradas.
  final bool exploracao;
  final String piso;
  final AcessaColors c;
  final bool glow;
  final _Camera cam;
  final double kPiso;
  final Offset voce;
  final double rumo;
  final double pulso;
  final double textScale;

  /// Idioma do visitante (nome do piso nas trocas de piso).
  final AppLanguage idioma;

  final _ocupado = <Rect>[];

  Offset _p(PontoReferencia p) => cam.tela(Offset(p.x, p.y));

  @override
  void paint(Canvas canvas, Size size) {
    _ocupado.clear();
    final noPiso = {
      for (final p in dados.pontos)
        if (p.piso == piso) p.id: p,
    };

    // 1. Contorno do prédio.
    final predio = Path()
      ..addPolygon([
        cam.tela(const Offset(-10, -10)),
        cam.tela(const Offset(_larguraMapa + 10, -10)),
        cam.tela(const Offset(_larguraMapa + 10, _alturaMapa + 10)),
        cam.tela(const Offset(-10, _alturaMapa + 10)),
      ], true);
    canvas.drawPath(predio, Paint()..color = c.surface);
    canvas.drawPath(
      predio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c.mapLine,
    );

    // 2. Corredores como ruas.
    final larguraRua = (16 * cam.k).clamp(10.0, 70.0);
    final rua = Paint()
      ..color = c.mapLine
      ..strokeWidth = larguraRua
      ..strokeCap = StrokeCap.round;
    final borda = Paint()
      ..color = c.shadow.withValues(alpha: .6)
      ..strokeWidth = larguraRua + 3
      ..strokeCap = StrokeCap.round;
    final trechosPiso = [
      for (final t in dados.trechos)
        if (noPiso[t.de] != null && noPiso[t.para] != null) t,
    ];
    for (final t in trechosPiso) {
      canvas.drawLine(_p(noPiso[t.de]!), _p(noPiso[t.para]!), borda);
    }
    for (final t in trechosPiso) {
      canvas.drawLine(_p(noPiso[t.de]!), _p(noPiso[t.para]!), rua);
    }

    // 2b. Rota mais usada (quando a rota adaptada é outra): tracejada e
    // esmaecida, só nos trechos que a rota do visitante não usa.
    if (fantasma case final f?) {
      final usados = {
        for (final perna in estado.viagem.pernas)
          for (final e in perna.etapas) e.trecho.id,
      };
      final linha = Path();
      for (final perna in f.pernas) {
        for (final e in perna.etapas) {
          if (e.trecho.trocaPiso != null || usados.contains(e.trecho.id)) {
            continue;
          }
          if (e.de.piso != piso || e.para.piso != piso) continue;
          linha
            ..moveTo(_p(e.de).dx, _p(e.de).dy)
            ..lineTo(_p(e.para).dx, _p(e.para).dy);
        }
      }
      final wf = (larguraRua * .3).clamp(4.0, 10.0);
      canvas.drawPath(
        _tracejar(linha, wf * 1.6, wf * 1.2),
        Paint()
          ..color = c.inkMuted.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = wf
          ..strokeCap = StrokeCap.butt,
      );
    }

    // 3. Rota com contorno (como no GPS): feito apagado, resto em destaque.
    final feitas = estado.etapasFeitas;
    var g = 0;
    final aFazer = Path(), feito = Path();
    final trocas = <(PontoReferencia, String)>[];
    for (final perna in estado.viagem.pernas) {
      for (final e in perna.etapas) {
        final idx = g++;
        if (e.trecho.trocaPiso != null) {
          if (e.de.piso == piso && idx >= feitas) {
            trocas.add((
              e.de,
              '${_seta(e)} ${traduzir(e.para.piso ?? '', idioma)}',
            ));
          }
          continue;
        }
        if (e.de.piso != piso || e.para.piso != piso) continue;
        final alvo = idx < feitas ? feito : aFazer;
        // A etapa em andamento começa onde a seta está.
        final ini = idx == feitas ? cam.tela(voce) : _p(e.de);
        alvo
          ..moveTo(ini.dx, ini.dy)
          ..lineTo(_p(e.para).dx, _p(e.para).dy);
      }
    }
    final w = (larguraRua * .45).clamp(6.0, 16.0);
    Paint traco(Color cor, double l) => Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = l
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(feito, traco(c.inkMuted.withValues(alpha: .45), w * .7));
    if (glow) {
      canvas.drawPath(
        aFazer,
        traco(c.navigation.withValues(alpha: .35), w + 10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(aFazer, traco(c.shadow, w + 4));
    canvas.drawPath(aFazer, traco(c.navigation, w));

    // 4. Pontos (de pé, tamanho fixo). Nomes: paradas e rota primeiro;
    // os demais só com zoom e sem sobrepor.
    final icones = {for (final l in dados.locais) l.pontoId: l.icone};
    final naRota = {
      for (final perna in estado.viagem.pernas)
        for (final p in perna.pontos) p.id,
    };
    final paradas = {for (final p in estado.viagem.paradas) p.id};
    final pontos =
        noPiso.values.where((p) => p.tipo != TipoPonto.corredor).toList()..sort(
          (a, b) =>
              _prioridade(a, naRota, paradas) - _prioridade(b, naRota, paradas),
        );
    final aqui = estado.pontoAtual;
    final vocePiso = aqui.piso == piso;
    if (vocePiso) {
      // Reserva o espaço da seta para nenhum nome cobri-la.
      _ocupado.add(Rect.fromCircle(center: cam.tela(voce), radius: 26));
    }
    final todosOsNomes = cam.k >= kPiso * 1.8;
    for (final p in pontos) {
      final o = _p(p);
      if (!Rect.fromLTWH(
        -40,
        -40,
        size.width + 80,
        size.height + 80,
      ).contains(o)) {
        continue;
      }
      final destaque = naRota.contains(p.id);
      canvas.drawCircle(o, 12, Paint()..color = destaque ? c.ink : c.surface);
      canvas.drawCircle(
        o,
        12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = destaque ? c.ink : c.border.withValues(alpha: .5),
      );
      final icone = p.tipo == TipoPonto.escada
          ? Icons.stairs_outlined
          : iconeDoLocal(icones[p.id] ?? '');
      _icone(canvas, icone, o, 14, destaque ? c.background : c.inkMuted);
      if (vocePiso && p.id == aqui.id) continue;
      if (!destaque && !todosOsNomes) continue;
      _nome(canvas, p.nome, o + const Offset(0, 16), destaque);
    }

    // 5. Trocas de piso à frente ("↑ 2º piso").
    for (final (p, rotulo) in trocas) {
      _etiqueta(canvas, rotulo, _p(p) + const Offset(-40, -16), c.navigation);
    }

    // 6. Paradas numeradas e destino final (alfinete).
    for (final (i, p) in estado.viagem.paradas.indexed) {
      if (exploracao || p.piso != piso) continue;
      final o = _p(p) + const Offset(13, -15);
      final ok = i < estado.perna || (i == estado.perna && estado.naParada);
      canvas.drawCircle(o, 11, Paint()..color = c.help);
      canvas.drawCircle(
        o,
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c.ink,
      );
      final ultima = i == estado.viagem.paradas.length - 1;
      if (ultima) {
        _icone(canvas, Icons.flag, o, 14, c.onAccent);
      } else if (ok) {
        _icone(canvas, Icons.check, o, 14, c.onAccent);
      } else {
        _icone(canvas, null, o, 12, c.onAccent, texto: '${i + 1}');
      }
    }

    // 7. Você: halo, pulso curto ao chegar e seta de navegação.
    if (vocePiso) {
      final o = cam.tela(voce);
      canvas.drawCircle(o, 24, Paint()..color = c.marker.withValues(alpha: .2));
      if (pulso > 0) {
        canvas.drawCircle(
          o,
          16 + 22 * pulso,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = c.marker.withValues(alpha: 1 - pulso),
        );
      }
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(rumo * math.pi / 180 + cam.rot);
      final seta = Path()
        ..moveTo(0, -17)
        ..lineTo(12, 13)
        ..lineTo(0, 6)
        ..lineTo(-12, 13)
        ..close();
      canvas.drawPath(seta, Paint()..color = c.marker);
      canvas.drawPath(
        seta,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = c.ink,
      );
      canvas.restore();
    }
  }

  static int _prioridade(
    PontoReferencia p,
    Set<String> naRota,
    Set<String> paradas,
  ) => paradas.contains(p.id)
      ? 0
      : naRota.contains(p.id)
      ? 1
      : 2;

  String _seta(EtapaRota e) {
    final pisos = dados.pisos;
    return pisos.indexOf(e.para.piso ?? '') > pisos.indexOf(e.de.piso ?? '')
        ? '↑'
        : '↓';
  }

  void _icone(
    Canvas canvas,
    IconData? i,
    Offset o,
    double tam,
    Color cor, {
    String? texto,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto ?? String.fromCharCode(i!.codePoint),
        style: TextStyle(
          fontFamily: texto == null ? i!.fontFamily : null,
          package: texto == null ? i!.fontPackage : null,
          fontSize: tam,
          fontWeight: texto == null ? null : FontWeight.w700,
          color: cor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
  }

  /// Nome com fundo escuro, pulado se cobrir outro nome ou a seta.
  void _nome(Canvas canvas, String s, Offset topo, bool destaque) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: (destaque ? 12 : 11) * textScale.clamp(1.0, 1.4),
          height: 1.1,
          fontWeight: destaque ? FontWeight.w700 : FontWeight.w400,
          color: destaque ? c.ink : c.inkMuted,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 96);
    final r = Rect.fromLTWH(
      topo.dx - tp.width / 2 - 4,
      topo.dy - 1,
      tp.width + 8,
      tp.height + 2,
    );
    if (_ocupado.any((o) => o.overlaps(r))) return;
    _ocupado.add(r);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()..color = c.background.withValues(alpha: .82),
    );
    tp.paint(canvas, Offset(topo.dx - tp.width / 2, topo.dy));
  }

  void _etiqueta(Canvas canvas, String s, Offset o, Color fundo) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: 11 * textScale.clamp(1.0, 1.4),
          fontWeight: FontWeight.w700,
          color: c.onAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: o, width: tp.width + 12, height: tp.height + 6),
      const Radius.circular(9),
    );
    _ocupado.add(r.outerRect);
    canvas.drawRRect(r, Paint()..color = fundo);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = c.ink,
    );
    tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
  }

  /// Corta [p] em traços de [traco] px com [vao] px de espaço.
  static Path _tracejar(Path p, double traco, double vao) {
    final r = Path();
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += traco + vao) {
        r.addPath(m.extractPath(d, d + traco), Offset.zero);
      }
    }
    return r;
  }

  @override
  bool shouldRepaint(_PlantaPainter old) => true;
}

/// Marcadores dos alertas do piso, posicionados pela câmera. Alertas
/// próximos na tela viram um grupo com o número; relatos desta sessão
/// ainda não enviados aparecem como "Enviando…" ou "Não enviado".
class _CamadaAlertas extends StatelessWidget {
  const _CamadaAlertas({
    required this.cam,
    required this.tam,
    required this.alertas,
    required this.pendentes,
    required this.dados,
    required this.pontos,
  });

  final _Camera cam;
  final Size tam;
  final List<Ocorrencia> alertas;
  final List<EnvioPendente> pendentes;
  final ShoppingData dados;
  final Map<String, PontoReferencia> pontos;

  /// Lado do alvo de toque de cada marcador (≥ 48 dp).
  static const _lado = 48.0;

  bool _visivel(Offset o) => Rect.fromLTWH(
    -_lado / 2,
    -_lado / 2,
    tam.width + _lado,
    tam.height + _lado,
  ).contains(o);

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    // Raio de agrupamento: ~40 px na tela, convertido para a planta.
    final grupos = agrupar(alertas, 40 / cam.k);
    final filhos = <Widget>[];

    for (final g in grupos) {
      final o = cam.tela(Offset(g.first.x, g.first.y));
      if (!_visivel(o)) continue;
      final unico = g.length == 1;
      final rotulo = unico
          ? '${tr(context, 'Alerta da comunidade:')} '
                '${tr(context, fraseDoAlerta(g.first, pontos))}'
          : tr(context, '${g.length} alertas neste local');
      filhos.add(
        Positioned(
          left: o.dx - _lado / 2,
          top: o.dy - _lado / 2,
          width: _lado,
          height: _lado,
          child: Semantics(
            button: true,
            label: rotulo,
            hint: tr(context, 'Toque para ver os detalhes'),
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey(
                unico ? 'alerta-${g.first.id}' : 'grupo-${g.first.id}',
              ),
              behavior: HitTestBehavior.opaque,
              onTap: () => unico
                  ? mostrarDetalhesAlerta(context, g.first.id, dados)
                  : mostrarGrupoAlertas(context, g, dados),
              child: Center(
                child: unico
                    ? MarcadorAlerta(tipo: g.first.tipo)
                    : MarcadorGrupo(quantos: g.length),
              ),
            ),
          ),
        ),
      );
    }

    for (final p in pendentes) {
      final o = cam.tela(Offset(p.nova.x, p.nova.y));
      if (!_visivel(o)) continue;
      final falhou = p.estado == EstadoEnvio.falhou;
      final estado = tr(context, falhou ? 'Não enviado' : 'Enviando…');
      filhos.add(
        Positioned(
          left: o.dx - 50,
          top: o.dy - _lado / 2,
          width: 100,
          child: Semantics(
            button: true,
            label: '${tr(context, p.nova.tipo.rotulo)}: $estado',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('pendente-${p.chave}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => mostrarEnvioPendente(context, p),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _lado,
                    child: Center(child: MarcadorPendente(falhou: falhou)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: BorderRadius.circular(AcessaRadius.pill),
                      border: Border.all(
                        color: falhou ? c.simulation : c.border,
                      ),
                    ),
                    child: Text(
                      estado,
                      style: text.labelSmall?.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Stack(clipBehavior: Clip.none, children: filhos);
  }
}

/// Lista acessível "Alertas neste piso": o mesmo conteúdo dos marcadores,
/// em texto, para leitor de tela e para quem prefere lista a mapa.
class _ListaAlertasDoPiso extends StatelessWidget {
  const _ListaAlertasDoPiso({
    required this.alertas,
    required this.pendentes,
    required this.dados,
    required this.pontos,
    required this.agora,
  });

  final List<Ocorrencia> alertas;
  final List<EnvioPendente> pendentes;
  final ShoppingData dados;
  final Map<String, PontoReferencia> pontos;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            tr(context, 'Alertas neste piso'),
            style: text.titleLarge,
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            tr(context, resumoAlertasNoPiso(alertas.length)),
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
          ),
        ),
        for (final o in alertas)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AcessaSpacing.minTouch + 8,
            textColor: c.ink,
            leading: MarcadorAlerta(tipo: o.tipo, tamanho: 32),
            title: Text(tr(context, o.tipo.rotulo)),
            subtitle: Text(
              '${tr(context, 'Perto de: ${nomeDoLocal(o, pontos) ?? '—'}')} · '
              '${tr(context, 'confirmado ${haQuanto(o.confirmadaEm, agora)}')}',
              style: TextStyle(color: c.inkMuted),
            ),
            trailing: Icon(Icons.chevron_right, color: c.inkMuted),
            onTap: () => mostrarDetalhesAlerta(context, o.id, dados),
          ),
        for (final p in pendentes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AcessaSpacing.minTouch + 8,
            textColor: c.ink,
            leading: MarcadorPendente(
              falhou: p.estado == EstadoEnvio.falhou,
              tamanho: 32,
            ),
            title: Text(tr(context, p.nova.tipo.rotulo)),
            subtitle: Text(
              tr(
                context,
                p.estado == EstadoEnvio.falhou ? 'Não enviado' : 'Enviando…',
              ),
              style: TextStyle(color: c.inkMuted),
            ),
            onTap: () => mostrarEnvioPendente(context, p),
          ),
      ],
    );
  }
}
