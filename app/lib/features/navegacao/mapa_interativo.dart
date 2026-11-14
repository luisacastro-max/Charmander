import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/icones.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/rules/viagem.dart';

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
  });

  final ShoppingData dados;
  final EstadoNavegacao estado;
  final double altura;

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
  bool _seguir = true;
  bool _norteParaCima = false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (p == _pisoAtual) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Piso:', style: text.titleMedium),
            for (final p in dados.pisos)
              Semantics(
                selected: _piso == p,
                inMutuallyExclusiveGroup: true,
                child: ChoiceChip(
                  label: Text(p == _pisoAtual ? '$p (você)' : p),
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
                    'Vendo o $_piso. Você está no $_pisoAtual.',
                    style: text.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _recentralizar,
                  style: TextButton.styleFrom(
                    foregroundColor: c.focus,
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                  ),
                  child: const Text('Ver meu piso'),
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
              return Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      container: true,
                      image: true,
                      label: _descricao(estado),
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
                              piso: _piso,
                              c: c,
                              glow: !t.highContrast,
                              cam: _camera,
                              kPiso: _kPiso,
                              voce: _posAgora,
                              rumo: _rumoAgora,
                              pulso: _pulso.isAnimating ? _pulso.value : 0,
                              textScale: MediaQuery.textScalerOf(context)
                                  .scale(1),
                            ),
                          ),
                        ),
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
                            ? 'Girar o mapa na direção da caminhada'
                            : 'Deixar o norte do mapa para cima',
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
                          dica: 'Aproximar o mapa',
                          onTap: () => _zoomBotao(1.4),
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 6),
                        _BotaoMapa(
                          dica: 'Afastar o mapa',
                          onTap: () => _zoomBotao(1 / 1.4),
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 6),
                        _BotaoMapa(
                          dica: 'Ver a rota inteira',
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
                        label: const Text('Recentralizar'),
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
        const _Legenda(),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          _norteParaCima
              ? 'Norte do mapa para cima. Toque na bússola para o mapa '
                    'girar na direção da caminhada.'
              : 'O mapa gira para a sua direção ficar para cima. Toque na '
                    'bússola para fixar o norte do mapa. Mapa ilustrativo, '
                    'com dados fictícios.',
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }

  /// O que o mapa mostra, em texto (RNF04: imagem nunca é a única fonte).
  String _descricao(EstadoNavegacao estado) {
    final nesse = <String>[];
    for (final perna in estado.viagem.pernas) {
      for (final p in perna.pontos) {
        if (p.piso == _piso && (nesse.isEmpty || nesse.last != p.nome)) {
          nesse.add(p.nome);
        }
      }
    }
    final b = StringBuffer('Mapa do $_piso. ');
    if (estado.pontoAtual.piso == _piso) {
      b.write('Você está em ${estado.pontoAtual.nome}. ');
    } else {
      b.write('Você está no ${estado.pontoAtual.piso}. ');
    }
    if (nesse.isEmpty) {
      b.write('A rota não passa por este piso.');
    } else {
      b.write('Neste piso a rota passa por ${nesse.join(', ')}.');
    }
    final prox = estado.proximoPonto;
    if (prox != null) b.write(' Próximo ponto: ${prox.nome}.');
    b.write(
      _seguir
          ? (_norteParaCima
                ? ' O mapa acompanha você, com o norte do mapa para cima.'
                : ' O mapa acompanha você e gira na direção da caminhada.')
          : ' O mapa está solto; use Recentralizar para voltar a seguir.',
    );
    return b.toString();
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
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    Widget item(Widget simbolo, String rotulo) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        simbolo,
        const SizedBox(width: 6),
        Text(rotulo, style: text.bodyMedium),
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
        item(Icon(Icons.navigation, size: 18, color: c.marker), 'Você'),
        item(linha(c.navigation), 'A percorrer'),
        item(linha(c.inkMuted.withValues(alpha: .5)), 'Já percorrido'),
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
          'Parada',
        ),
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
    required this.piso,
    required this.c,
    required this.glow,
    required this.cam,
    required this.kPiso,
    required this.voce,
    required this.rumo,
    required this.pulso,
    required this.textScale,
  });

  final ShoppingData dados;
  final EstadoNavegacao estado;
  final String piso;
  final AcessaColors c;
  final bool glow;
  final _Camera cam;
  final double kPiso;
  final Offset voce;
  final double rumo;
  final double pulso;
  final double textScale;

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
            trocas.add((e.de, '${_seta(e)} ${e.para.piso}'));
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
      if (p.piso != piso) continue;
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

  @override
  bool shouldRepaint(_PlantaPainter old) => true;
}
