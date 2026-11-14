import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/ocorrencia.dart';

/// Ícone fácil de reconhecer para cada tipo de alerta. Sempre aparece com
/// o rótulo em texto (o ícone nunca é a única informação).
IconData iconeDoTipo(TipoOcorrencia t) => switch (t) {
  TipoOcorrencia.pisoMolhado => Icons.water_drop_outlined,
  TipoOcorrencia.passagemInterditada => Icons.do_not_disturb_on_outlined,
  TipoOcorrencia.obstaculo => Icons.inventory_2_outlined,
  TipoOcorrencia.elevadorParado => Icons.elevator_outlined,
  TipoOcorrencia.escadaRolanteParada => Icons.escalator_outlined,
  TipoOcorrencia.rampaBloqueada => Icons.accessible_forward,
  TipoOcorrencia.localCheio => Icons.groups_outlined,
  TipoOcorrencia.outro => Icons.help_outline,
};

bool bloqueia(TipoOcorrencia t) => t.efeito == EfeitoOcorrencia.bloqueia;

/// O que a forma do marcador significa, em texto (legenda e leitor de tela).
String rotuloEfeito(TipoOcorrencia t) =>
    bloqueia(t) ? 'Bloqueia a passagem' : 'Atenção no caminho';

/// Cor de preenchimento do marcador. A cor só reforça: o que diferencia
/// bloqueio de aviso é a **forma** (octógono x triângulo).
Color corDoEfeito(AcessaColors c, TipoOcorrencia t) =>
    bloqueia(t) ? c.marker : c.simulation;

/// Marcador de alerta: octógono (como a placa "Pare") para o que bloqueia
/// a passagem e triângulo (placa de atenção) para o que pede cuidado.
/// Contorno grosso na cor do texto para contrastar com qualquer fundo,
/// inclusive no alto contraste.
class MarcadorAlerta extends StatelessWidget {
  const MarcadorAlerta({super.key, required this.tipo, this.tamanho = 36});

  final TipoOcorrencia tipo;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final octo = bloqueia(tipo);
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: _FormaPainter(
          octogono: octo,
          preenchimento: corDoEfeito(c, tipo),
          contorno: c.ink,
          halo: c.background,
        ),
        child: Align(
          // No triângulo, o ícone desce para o centro visual da forma.
          alignment: octo ? Alignment.center : const Alignment(0, .45),
          child: Icon(
            iconeDoTipo(tipo),
            size: tamanho * (octo ? .52 : .40),
            color: c.onAccent,
          ),
        ),
      ),
    );
  }
}

class _FormaPainter extends CustomPainter {
  _FormaPainter({
    required this.octogono,
    required this.preenchimento,
    required this.contorno,
    required this.halo,
  });

  final bool octogono;
  final Color preenchimento;
  final Color contorno;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final centro = size.center(Offset.zero);
    final p = Path();
    if (octogono) {
      for (var i = 0; i < 8; i++) {
        final a = math.pi / 8 + i * math.pi / 4;
        final pt = centro + Offset(math.cos(a), math.sin(a)) * (r - 2);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
    } else {
      p
        ..moveTo(centro.dx, 2)
        ..lineTo(size.width - 2, size.height - 3)
        ..lineTo(2, size.height - 3);
    }
    p.close();
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = halo,
    );
    canvas.drawPath(p, Paint()..color = preenchimento);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = contorno,
    );
  }

  @override
  bool shouldRepaint(_FormaPainter old) =>
      old.octogono != octogono ||
      old.preenchimento != preenchimento ||
      old.contorno != contorno ||
      old.halo != halo;
}

/// Marcador de um grupo de alertas próximos: círculo com o número.
class MarcadorGrupo extends StatelessWidget {
  const MarcadorGrupo({super.key, required this.quantos, this.tamanho = 36});

  final int quantos;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.ink,
        shape: BoxShape.circle,
        border: Border.all(color: c.background, width: 3),
        boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(2, 2))],
      ),
      child: Text(
        '$quantos',
        style: TextStyle(
          fontSize: tamanho * .42,
          fontWeight: FontWeight.w800,
          color: c.background,
        ),
      ),
    );
  }
}

/// Marcador de um relato desta sessão que ainda não chegou ao servidor.
class MarcadorPendente extends StatelessWidget {
  const MarcadorPendente({super.key, required this.falhou, this.tamanho = 36});

  final bool falhou;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: falhou ? c.simulation : c.inkMuted, width: 3),
      ),
      child: Icon(
        falhou ? Icons.cloud_off_outlined : Icons.cloud_upload_outlined,
        size: tamanho * .5,
        color: c.ink,
      ),
    );
  }
}

/// Ícone do tipo + rótulo traduzido, numa linha.
class RotuloTipo extends StatelessWidget {
  const RotuloTipo({super.key, required this.tipo, this.estilo});

  final TipoOcorrencia tipo;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MarcadorAlerta(tipo: tipo, tamanho: 32),
        const SizedBox(width: AcessaSpacing.sm),
        Expanded(
          child: Text(
            tr(context, tipo.rotulo),
            style: estilo ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

/// Legenda das formas (bloqueio x aviso), para o mapa.
class LegendaAlertas extends StatelessWidget {
  const LegendaAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget item(TipoOcorrencia t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarcadorAlerta(tipo: t, tamanho: 22),
        const SizedBox(width: 6),
        Flexible(
          child: Text(tr(context, rotuloEfeito(t)), style: text.bodyMedium),
        ),
      ],
    );
    return Wrap(
      spacing: AcessaSpacing.md,
      runSpacing: AcessaSpacing.xs,
      children: [
        item(TipoOcorrencia.passagemInterditada),
        item(TipoOcorrencia.pisoMolhado),
      ],
    );
  }
}
