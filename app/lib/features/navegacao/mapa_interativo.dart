import 'dart:math' as math;

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

/// Mapa interativo do piso (RF17, RF19, RF48): zoom com gesto ou botões,
/// "Você está aqui", rota desenhada (feito / a fazer), paradas numeradas e
/// troca de piso. O mapa é complemento: tudo o que ele mostra também está
/// em texto na tela de navegação e na descrição para leitores de tela.
class MapaInterativo extends StatefulWidget {
  const MapaInterativo({super.key, required this.dados, required this.estado});

  final ShoppingData dados;
  final EstadoNavegacao estado;

  @override
  State<MapaInterativo> createState() => _MapaInterativoState();
}

class _MapaInterativoState extends State<MapaInterativo>
    with SingleTickerProviderStateMixin {
  final _tc = TransformationController();
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late String _piso = _pisoAtual;
  Size _tam = Size.zero;

  String get _pisoAtual => widget.estado.pontoAtual.piso ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulsar();
  }

  @override
  void didUpdateWidget(MapaInterativo old) {
    super.didUpdateWidget(old);
    if (old.estado.pontoAtual.id != widget.estado.pontoAtual.id) {
      // O mapa acompanha o visitante: volta para o piso dele e, se houver
      // zoom, recentraliza no novo ponto.
      _piso = _pisoAtual;
      if (_escala > 1.01) _centralizar(_escala);
      _pulsar();
    }
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
    _tc.dispose();
    _pulso.dispose();
    super.dispose();
  }

  double get _escala => _tc.value.getMaxScaleOnAxis();

  Offset _noDesenho(PontoReferencia p) =>
      Offset(p.x / _larguraMapa * _tam.width, p.y / _alturaMapa * _tam.height);

  /// Coloca [alvo] (coordenadas do desenho) no centro, na escala [s].
  void _focar(Offset alvo, double s) {
    if (_tam.isEmpty) return;
    final tx = (_tam.width / 2 - alvo.dx * s).clamp(
      _tam.width - _tam.width * s,
      0.0,
    );
    final ty = (_tam.height / 2 - alvo.dy * s).clamp(
      _tam.height - _tam.height * s,
      0.0,
    );
    _tc.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _centralizar([double? s]) {
    if (_piso != _pisoAtual) setState(() => _piso = _pisoAtual);
    _focar(_noDesenho(widget.estado.pontoAtual), s ?? math.max(_escala, 2));
  }

  void _zoom(double fator) {
    final centro = _tc.toScene(_tam.center(Offset.zero));
    _focar(centro, (_escala * fator).clamp(1.0, 4.0));
  }

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
                  onSelected: (_) => setState(() => _piso = p),
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
                  onPressed: () => setState(() => _piso = _pisoAtual),
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
        AspectRatio(
          aspectRatio: _larguraMapa / _alturaMapa,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
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
                return Semantics(
                  container: true,
                  image: true,
                  label: _descricao(dados, estado),
                  excludeSemantics: true,
                  child: InteractiveViewer(
                    transformationController: _tc,
                    minScale: 1,
                    maxScale: 4,
                    child: CustomPaint(
                      size: _tam,
                      painter: _PlantaPainter(
                        dados: dados,
                        estado: estado,
                        piso: _piso,
                        c: c,
                        glow: !t.highContrast,
                        pulso: _pulso,
                        zoom: _tc,
                        textScale: MediaQuery.textScalerOf(context).scale(1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        // Botões fora do desenho, para não cobrir nenhuma parte do mapa.
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _BotaoMapa(
              icone: Icons.add,
              dica: 'Aproximar o mapa',
              onTap: () => _zoom(1.5),
            ),
            const SizedBox(width: AcessaSpacing.sm),
            _BotaoMapa(
              icone: Icons.remove,
              dica: 'Afastar o mapa',
              onTap: () => _zoom(1 / 1.5),
            ),
            const SizedBox(width: AcessaSpacing.sm),
            _BotaoMapa(
              icone: Icons.my_location,
              dica: 'Centralizar em você',
              onTap: _centralizar,
            ),
          ],
        ),
        const SizedBox(height: AcessaSpacing.sm),
        const _Legenda(),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          'Use dois dedos ou os botões + e − para aproximar e ver o nome '
          'de todos os lugares. '
          'Mapa ilustrativo, com dados fictícios.',
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }

  /// O que o mapa mostra, em texto (RNF04: imagem nunca é a única fonte).
  String _descricao(ShoppingData dados, EstadoNavegacao estado) {
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
    return b.toString();
  }
}

class _BotaoMapa extends StatelessWidget {
  const _BotaoMapa({
    required this.icone,
    required this.dica,
    required this.onTap,
  });
  final IconData icone;
  final String dica;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Material(
      color: c.background,
      shape: CircleBorder(side: BorderSide(color: c.border, width: 1.5)),
      child: IconButton(
        tooltip: dica,
        onPressed: onTap,
        icon: Icon(icone),
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
    Widget bola(Color cor, {Widget? filho}) => Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
        border: Border.all(color: c.ink, width: 2),
      ),
      child: filho,
    );
    Widget linha(Color cor) => Container(
      width: 22,
      height: 5,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Wrap(
      spacing: AcessaSpacing.md,
      runSpacing: AcessaSpacing.xs,
      children: [
        item(bola(c.marker), 'Você'),
        item(linha(c.navigation), 'A percorrer'),
        item(linha(c.inkMuted.withValues(alpha: .5)), 'Já percorrido'),
        item(
          bola(
            c.help,
            filho: Text(
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

class _PlantaPainter extends CustomPainter {
  _PlantaPainter({
    required this.dados,
    required this.estado,
    required this.piso,
    required this.c,
    required this.glow,
    required this.pulso,
    required this.zoom,
    required this.textScale,
  }) : super(repaint: Listenable.merge([pulso, zoom]));

  final ShoppingData dados;
  final EstadoNavegacao estado;
  final String piso;
  final AcessaColors c;
  final bool glow;
  final Animation<double> pulso;

  /// Com pouco zoom, só os pontos da rota têm nome (evita sobreposição).
  final TransformationController zoom;
  final double textScale;

  late double _k;

  Offset _p(PontoReferencia p) => Offset(p.x * _k, p.y * _k);

  @override
  void paint(Canvas canvas, Size size) {
    _k = size.width / _larguraMapa;
    final noPiso = {
      for (final p in dados.pontos)
        if (p.piso == piso) p.id: p,
    };

    // 1. Planta: corredores largos e finos (base do desenho).
    final corredor = Paint()
      ..color = c.mapLine.withValues(alpha: .55)
      ..strokeWidth = 14 * _k
      ..strokeCap = StrokeCap.round;
    final eixo = Paint()
      ..color = c.mapLine
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final t in dados.trechos) {
      final a = noPiso[t.de], b = noPiso[t.para];
      if (a == null || b == null) continue;
      canvas.drawLine(_p(a), _p(b), corredor);
      canvas.drawLine(_p(a), _p(b), eixo);
    }

    // 2. Rota: já percorrido apagado, a percorrer em destaque.
    final feitas = estado.etapasFeitas;
    var g = 0;
    final aFazer = Path(), feito = Path(), atual = Path();
    final trocas = <(PontoReferencia, String)>[];
    for (final perna in estado.viagem.pernas) {
      for (final e in perna.etapas) {
        final idx = g++;
        if (e.trecho.trocaPiso != null) {
          if (e.de.piso == piso) {
            trocas.add((e.de, '${_seta(e)} ${e.para.piso}'));
          }
          continue;
        }
        if (e.de.piso != piso || e.para.piso != piso) continue;
        final alvo = idx < feitas
            ? feito
            : idx == feitas
            ? atual
            : aFazer;
        alvo
          ..moveTo(_p(e.de).dx, _p(e.de).dy)
          ..lineTo(_p(e.para).dx, _p(e.para).dy);
      }
    }
    Paint traco(Color cor, double w) => Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(feito, traco(c.inkMuted.withValues(alpha: .5), 4));
    if (glow) {
      canvas.drawPath(
        atual,
        traco(c.navigation.withValues(alpha: .4), 14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(aFazer, traco(c.navigation, 4.5));
    canvas.drawPath(atual, traco(c.navigation, 7));

    // 3. Pontos do piso, com ícone e nome.
    final icones = {for (final l in dados.locais) l.pontoId: l.icone};
    final naRota = {
      for (final perna in estado.viagem.pernas)
        for (final p in perna.pontos) p.id,
    };
    final todosOsNomes = zoom.value.getMaxScaleOnAxis() >= 1.8;
    for (final p in noPiso.values) {
      if (p.tipo == TipoPonto.corredor) continue;
      final o = _p(p);
      final destaque = naRota.contains(p.id);
      canvas.drawCircle(
        o,
        9,
        Paint()..color = destaque ? c.surface : c.background,
      );
      canvas.drawCircle(
        o,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = destaque ? 2 : 1.2
          ..color = destaque ? c.ink : c.mapLine,
      );
      final icone = p.tipo == TipoPonto.escada
          ? Icons.stairs_outlined
          : iconeDoLocal(icones[p.id] ?? '');
      _icone(canvas, icone, o, 11, destaque ? c.ink : c.inkMuted);
      // O ponto atual já tem a etiqueta "Você".
      if (p.id == estado.pontoAtual.id) continue;
      if (!destaque && !todosOsNomes) continue;
      _texto(
        canvas,
        p.nome,
        o + const Offset(0, 15),
        tamanho: destaque ? 8.5 : 7.5,
        cor: destaque ? c.ink : c.inkMuted,
        negrito: destaque,
      );
    }

    // 4. Trocas de piso da rota neste piso ("↑ 2º piso").
    for (final (p, rotulo) in trocas) {
      _etiqueta(canvas, rotulo, _p(p) + const Offset(-36, -14), c.navigation);
    }

    // 5. Paradas numeradas e destino final.
    final paradas = estado.viagem.paradas;
    for (final (i, p) in paradas.indexed) {
      if (p.piso != piso) continue;
      final o = _p(p) + const Offset(11, -11);
      final ok = i < estado.perna || (i == estado.perna && estado.naParada);
      canvas.drawCircle(o, 9, Paint()..color = c.help);
      canvas.drawCircle(
        o,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c.ink,
      );
      if (i == paradas.length - 1) {
        _icone(canvas, Icons.flag, o, 12, c.onAccent);
      } else if (ok) {
        _icone(canvas, Icons.check, o, 12, c.onAccent);
      } else {
        _texto(
          canvas,
          '${i + 1}',
          o,
          tamanho: 10,
          cor: c.onAccent,
          negrito: true,
          centroVertical: true,
        );
      }
    }

    // 6. Você está aqui: ponto rosa, seta da direção e pulso curto.
    final aqui = estado.pontoAtual;
    if (aqui.piso == piso) {
      final o = _p(aqui);
      final v = pulso.isAnimating ? pulso.value : 0.0;
      if (v > 0) {
        canvas.drawCircle(
          o,
          10 + 18 * v,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = c.marker.withValues(alpha: 1 - v),
        );
      }
      final dir = estado.direcao;
      if (dir != null) {
        canvas.save();
        canvas.translate(o.dx, o.dy);
        canvas.rotate(dir * math.pi / 180);
        canvas.drawPath(
          Path()
            ..moveTo(0, -22)
            ..lineTo(-7, -11)
            ..lineTo(7, -11)
            ..close(),
          Paint()..color = c.marker,
        );
        canvas.restore();
      }
      canvas.drawCircle(o, 9, Paint()..color = c.ink);
      canvas.drawCircle(o, 6.5, Paint()..color = c.marker);
      _etiqueta(canvas, 'Você', o + const Offset(0, 26), c.marker);
    }
  }

  String _seta(EtapaRota e) {
    final pisos = dados.pisos;
    return pisos.indexOf(e.para.piso ?? '') > pisos.indexOf(e.de.piso ?? '')
        ? '↑'
        : '↓';
  }

  void _icone(Canvas canvas, IconData i, Offset o, double tam, Color cor) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(i.codePoint),
        style: TextStyle(
          fontFamily: i.fontFamily,
          package: i.fontPackage,
          fontSize: tam,
          color: cor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
  }

  void _texto(
    Canvas canvas,
    String s,
    Offset o, {
    required double tamanho,
    required Color cor,
    bool negrito = false,
    bool centroVertical = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: tamanho * textScale.clamp(1.0, 1.4),
          height: 1.1,
          fontWeight: negrito ? FontWeight.w700 : FontWeight.w400,
          color: cor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 70);
    tp.paint(
      canvas,
      Offset(o.dx - tp.width / 2, centroVertical ? o.dy - tp.height / 2 : o.dy),
    );
  }

  void _etiqueta(Canvas canvas, String s, Offset o, Color fundo) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: 9 * textScale.clamp(1.0, 1.4),
          fontWeight: FontWeight.w700,
          color: c.onAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: o, width: tp.width + 10, height: tp.height + 4),
      const Radius.circular(8),
    );
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
  bool shouldRepaint(_PlantaPainter old) =>
      old.estado != estado ||
      old.piso != piso ||
      old.c != c ||
      old.glow != glow ||
      old.textScale != textScale;
}
