import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/voz/voz.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/repositories/ocorrencias_repositorio.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/alertas_apresentacao.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/ocorrencias.dart';
import 'alertas_controller.dart';
import 'alertas_visual.dart';

enum _Fase { editando, enviando, enviado, falhou }

/// "Reportar problema": 1) o que está acontecendo, 2) onde (mini-planta,
/// começando na posição atual), 3) descrição opcional e 4) enviar.
///
/// Tudo numa página, com seções numeradas, para quem usa leitor de tela
/// percorrer em ordem. O pino pode ser ajustado por toque, por setas ou
/// escolhendo o ponto de referência mais próximo numa lista.
class ReportarAlertaScreen extends StatefulWidget {
  const ReportarAlertaScreen({
    super.key,
    required this.dados,
    required this.pontoInicialId,
  });

  final ShoppingData dados;

  /// Onde o visitante está (beacon simulado): posição inicial do pino.
  final String pontoInicialId;

  @override
  State<ReportarAlertaScreen> createState() => _ReportarAlertaScreenState();
}

class _ReportarAlertaScreenState extends State<ReportarAlertaScreen> {
  late final PontoReferencia _inicio = widget.dados.ponto(
    widget.pontoInicialId,
  );
  late String _piso = _inicio.piso ?? widget.dados.pisos.first;
  late double _x = _inicio.x;
  late double _y = _inicio.y;
  TipoOcorrencia? _tipo;
  final _descricao = TextEditingController();

  _Fase _fase = _Fase.editando;
  EnvioPendente? _envio;
  ResultadoRegistro? _resultado;

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  PontoReferencia? get _perto => pontoMaisProximo(_pontosDoPiso, _piso, _x, _y);

  List<PontoReferencia> get _pontosDoPiso => [
    for (final p in widget.dados.pontos)
      if (p.piso == _piso && p.tipo != TipoPonto.corredor) p,
  ];

  void _posicionar(double x, double y, {bool anunciarLocal = false}) {
    setState(() {
      _x = x.clamp(0.0, larguraPlanta);
      _y = y.clamp(0.0, alturaPlanta);
    });
    if (anunciarLocal && _perto != null) {
      anunciar(context, 'Pino perto de: ${_perto!.nome}');
    }
  }

  void _mover(int dx, int dy) {
    final p = moverPino(_x, _y, dx, dy);
    _posicionar(p.x, p.y, anunciarLocal: true);
  }

  void _trocarPiso(String piso) {
    if (piso == _piso) return;
    // No outro piso, o pino começa no centro da planta.
    setState(() {
      _piso = piso;
      _x = larguraPlanta / 2;
      _y = alturaPlanta / 2;
    });
  }

  Future<void> _enviar() async {
    final tipo = _tipo;
    if (tipo == null) return;
    final a = AlertasScope.of(context);
    final nova = NovaOcorrencia(
      shoppingId: a.shoppingId,
      tipo: tipo,
      piso: _piso,
      x: _x,
      y: _y,
      pontoId: _perto?.id,
      descricao: descricaoLimpa(_descricao.text),
    );
    setState(() => _fase = _Fase.enviando);
    final futuro = a.reportar(nova);
    _envio = a.pendentes.isEmpty ? null : a.pendentes.last;
    _concluir(await futuro);
  }

  Future<void> _tentarDeNovo() async {
    final p = _envio;
    if (p == null) return;
    setState(() => _fase = _Fase.enviando);
    _concluir(await AlertasScope.of(context).tentarDeNovo(p));
  }

  void _descartar() {
    final p = _envio;
    if (p != null) AlertasScope.of(context).descartar(p);
    Navigator.of(context).maybePop();
  }

  void _concluir(ResultadoRegistro? r) {
    if (!mounted) return;
    setState(() {
      _resultado = r;
      _fase = r == null ? _Fase.falhou : _Fase.enviado;
    });
    anunciar(
      context,
      r == null
          ? 'Não foi possível enviar o alerta.'
          : r.duplicada
          ? 'Somado a um alerta igual que já existia.'
          : 'Alerta enviado. Obrigado!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: tr(context, 'Voltar'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _fase == _Fase.editando ? _formulario(context) : _estado(context),
    );
  }

  Widget _secao(BuildContext context, String titulo) => Padding(
    padding: const EdgeInsets.only(
      top: AcessaSpacing.lg,
      bottom: AcessaSpacing.sm,
    ),
    child: Semantics(
      header: true,
      child: Text(
        tr(context, titulo),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  );

  Widget _formulario(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final a = AlertasScope.of(context);
    final perto = _perto;
    String t(String pt) => tr(context, pt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AcessaSpacing.lg,
        0,
        AcessaSpacing.lg,
        AcessaSpacing.xl,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(t('Reportar problema'), style: text.displayMedium),
        ),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          t(
            'Avise outras pessoas sobre algo que atrapalha o caminho. '
            'O alerta é um relato seu, não uma informação oficial do shopping.',
          ),
          style: text.bodyLarge?.copyWith(color: c.inkMuted),
        ),
        _secao(context, '1. O que está acontecendo?'),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - AcessaSpacing.sm) / 2;
            return Wrap(
              spacing: AcessaSpacing.sm,
              runSpacing: AcessaSpacing.sm,
              children: [
                for (final tipo in TipoOcorrencia.values)
                  SizedBox(
                    width: w,
                    child: _BotaoTipo(
                      tipo: tipo,
                      selecionado: _tipo == tipo,
                      onTap: () => setState(() => _tipo = tipo),
                    ),
                  ),
              ],
            );
          },
        ),
        _secao(context, '2. Onde?'),
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t('Andar:'), style: text.titleMedium),
            for (final p in widget.dados.pisos)
              Semantics(
                selected: _piso == p,
                inMutuallyExclusiveGroup: true,
                child: ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(t(p)),
                  selected: _piso == p,
                  onSelected: (_) => _trocarPiso(p),
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
        const SizedBox(height: AcessaSpacing.sm),
        _MiniPlanta(
          dados: widget.dados,
          piso: _piso,
          x: _x,
          y: _y,
          descricao: [
            t('Planta do $_piso.'),
            if (perto != null) t('Pino perto de: ${perto.nome}'),
            t('Toque para posicionar o pino.'),
          ].join(' '),
          onToque: (x, y) => _posicionar(x, y),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Seta(
              icone: Icons.arrow_back,
              dica: t('Mover o pino para a esquerda'),
              onTap: () => _mover(-1, 0),
            ),
            Column(
              children: [
                _Seta(
                  icone: Icons.arrow_upward,
                  dica: t('Mover o pino para cima'),
                  onTap: () => _mover(0, -1),
                ),
                const SizedBox(height: AcessaSpacing.xs),
                _Seta(
                  icone: Icons.arrow_downward,
                  dica: t('Mover o pino para baixo'),
                  onTap: () => _mover(0, 1),
                ),
              ],
            ),
            _Seta(
              icone: Icons.arrow_forward,
              dica: t('Mover o pino para a direita'),
              onTap: () => _mover(1, 0),
            ),
          ],
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(
            t('Perto de: ${perto?.nome ?? '—'}'),
            style: text.titleMedium,
          ),
        ),
        const SizedBox(height: AcessaSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: c.simulation, size: 20),
            const SizedBox(width: AcessaSpacing.sm),
            Expanded(
              child: Text(
                t(
                  'A posição dentro do shopping pode ser imprecisa. '
                  'Confira o ponto e o andar antes de enviar.',
                ),
                style: text.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AcessaSpacing.sm),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          minTileHeight: AcessaSpacing.minTouch,
          iconColor: c.ink,
          collapsedIconColor: c.ink,
          textColor: c.ink,
          collapsedTextColor: c.ink,
          title: Text(t('Escolher o ponto mais próximo numa lista')),
          children: [
            for (final p in _pontosDoPiso)
              ListTile(
                minTileHeight: AcessaSpacing.minTouch,
                selected: perto?.id == p.id,
                selectedColor: c.focus,
                textColor: c.ink,
                iconColor: c.ink,
                leading: Icon(
                  perto?.id == p.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(p.nome),
                onTap: () => _posicionar(p.x, p.y, anunciarLocal: true),
              ),
          ],
        ),
        _secao(context, '3. Detalhes (opcional)'),
        TextField(
          controller: _descricao,
          maxLength: NovaOcorrencia.maxDescricao,
          maxLines: 3,
          minLines: 2,
          style: text.bodyLarge,
          decoration: InputDecoration(
            labelText: t('Descrição (opcional)'),
            hintText: t('Ex.: poça perto da entrada da loja'),
            helperText: t(
              'Não escreva nomes, telefones ou outros dados pessoais.',
            ),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: c.inkMuted),
            hintStyle: TextStyle(color: c.inkMuted),
            helperStyle: TextStyle(color: c.inkMuted),
            counterStyle: TextStyle(color: c.inkMuted),
            floatingLabelStyle: TextStyle(color: c.focus),
          ),
        ),
        const SizedBox(height: AcessaSpacing.lg),
        if (_tipo == null)
          Padding(
            padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
            child: Text(
              t('Escolha o que está acontecendo para enviar.'),
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ),
        StickerButton(
          label: t('Enviar alerta'),
          icon: Icons.send,
          semanticHint: _tipo == null
              ? t('Escolha o que está acontecendo para enviar.')
              : t(
                  '${_tipo!.rotulo}, ${exibir(_piso)}, '
                  'perto de ${perto?.nome ?? '—'}',
                ),
          onPressed: _tipo == null ? null : _enviar,
        ),
        if (!a.compartilhado) ...[
          const SizedBox(height: AcessaSpacing.md),
          SimulationNotice(
            text: t('Simulação: os alertas ficam só neste aparelho'),
          ),
        ],
      ],
    );
  }

  Widget _estado(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final a = AlertasScope.of(context);
    String t(String pt) => tr(context, pt);
    final r = _resultado;

    final List<Widget> filhos = switch (_fase) {
      _Fase.enviando => [
        Row(
          children: [
            // Ícone parado (sem animação infinita): o texto diz o estado.
            Icon(Icons.cloud_upload_outlined, color: c.ink, size: 28),
            const SizedBox(width: AcessaSpacing.md),
            Expanded(
              child: Text(t('Enviando alerta…'), style: text.titleLarge),
            ),
          ],
        ),
      ],
      _Fase.enviado => [
        Row(
          children: [
            Icon(Icons.check_circle, color: c.help, size: 32),
            const SizedBox(width: AcessaSpacing.sm),
            Expanded(
              child: Text(
                t(
                  r?.duplicada ?? false
                      ? 'Somado a um alerta igual que já existia.'
                      : 'Alerta enviado. Obrigado!',
                ),
                style: text.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Text(
          t(
            a.compartilhado
                ? 'Outras pessoas neste shopping já podem ver o alerta.'
                : 'Simulação: os alertas ficam só neste aparelho',
          ),
          style: text.bodyLarge,
        ),
        const SizedBox(height: AcessaSpacing.lg),
        StickerButton(
          label: t('Concluir'),
          icon: Icons.check,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      _Fase.falhou => [
        Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: c.simulation, size: 32),
            const SizedBox(width: AcessaSpacing.sm),
            Expanded(
              child: Text(
                t('Não foi possível enviar o alerta.'),
                style: text.titleLarge,
              ),
            ),
          ],
        ),
        if (_envio?.erro case final e?) ...[
          const SizedBox(height: AcessaSpacing.sm),
          Text(t(e), style: text.bodyLarge),
        ],
        const SizedBox(height: AcessaSpacing.sm),
        Text(
          t('O relato fica guardado neste aparelho até você decidir.'),
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AcessaSpacing.lg),
        StickerButton(
          label: t('Tentar de novo'),
          icon: Icons.refresh,
          onPressed: _tentarDeNovo,
        ),
        const SizedBox(height: AcessaSpacing.sm),
        StickerButton(
          label: t('Descartar'),
          icon: Icons.delete_outline,
          kind: StickerButtonKind.secondary,
          onPressed: _descartar,
        ),
      ],
      _Fase.editando => const [],
    };

    return ListView(
      padding: const EdgeInsets.all(AcessaSpacing.lg),
      children: [
        Semantics(
          liveRegion: true,
          child: StickerCard(
            color: c.surface,
            borderColor: _fase == _Fase.falhou ? c.simulation : c.border,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tipo case final tipo?) ...[
                  RotuloTipo(tipo: tipo),
                  const SizedBox(height: AcessaSpacing.md),
                ],
                ...filhos,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão grande de um tipo de problema.
class _BotaoTipo extends StatelessWidget {
  const _BotaoTipo({
    required this.tipo,
    required this.selecionado,
    required this.onTap,
  });

  final TipoOcorrencia tipo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      hint: tr(context, rotuloEfeito(tipo)),
      child: Material(
        color: selecionado && !t.highContrast ? c.mapLine : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AcessaRadius.button),
          side: BorderSide(
            color: selecionado ? c.primary : c.border.withValues(alpha: .5),
            width: selecionado ? 4 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AcessaRadius.button),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(AcessaSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MarcadorAlerta(tipo: tipo, tamanho: 40),
                      if (selecionado) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle, color: c.primary, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, tipo.rotulo),
                    textAlign: TextAlign.center,
                    style: text.titleSmall?.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Seta extends StatelessWidget {
  const _Seta({required this.icone, required this.dica, required this.onTap});
  final IconData icone;
  final String dica;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AcessaSpacing.xs),
      child: Material(
        color: c.surface,
        shape: CircleBorder(side: BorderSide(color: c.border, width: 1.5)),
        child: IconButton(
          tooltip: dica,
          onPressed: onTap,
          icon: Icon(icone),
          color: c.ink,
          constraints: const BoxConstraints(
            minWidth: AcessaSpacing.minTouch + 4,
            minHeight: AcessaSpacing.minTouch + 4,
          ),
        ),
      ),
    );
  }
}

/// Planta simplificada do piso para posicionar o pino.
class _MiniPlanta extends StatelessWidget {
  const _MiniPlanta({
    required this.dados,
    required this.piso,
    required this.x,
    required this.y,
    required this.descricao,
    required this.onToque,
  });

  final ShoppingData dados;
  final String piso;
  final double x;
  final double y;
  final String descricao;
  final void Function(double x, double y) onToque;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return AspectRatio(
      aspectRatio: larguraPlanta / alturaPlanta,
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(AcessaRadius.card),
          border: Border.all(color: c.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, box) {
            final tam = box.biggest;
            final k =
                (tam.width / larguraPlanta < tam.height / alturaPlanta
                    ? tam.width / larguraPlanta
                    : tam.height / alturaPlanta) *
                .92;
            final origem = Offset(
              (tam.width - larguraPlanta * k) / 2,
              (tam.height - alturaPlanta * k) / 2,
            );
            return Semantics(
              image: true,
              label: descricao,
              child: GestureDetector(
                onTapUp: (d) {
                  final m = (d.localPosition - origem) / k;
                  onToque(m.dx, m.dy);
                },
                child: CustomPaint(
                  size: tam,
                  painter: _MiniPlantaPainter(
                    dados: dados,
                    piso: piso,
                    pino: Offset(x, y),
                    k: k,
                    origem: origem,
                    c: c,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniPlantaPainter extends CustomPainter {
  _MiniPlantaPainter({
    required this.dados,
    required this.piso,
    required this.pino,
    required this.k,
    required this.origem,
    required this.c,
  });

  final ShoppingData dados;
  final String piso;
  final Offset pino;
  final double k;
  final Offset origem;
  final AcessaColors c;

  Offset _t(double x, double y) => origem + Offset(x, y) * k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(_t(-6, -6), _t(larguraPlanta + 6, alturaPlanta + 6)),
        const Radius.circular(8),
      ),
      Paint()..color = c.surface,
    );
    final noPiso = {
      for (final p in dados.pontos)
        if (p.piso == piso) p.id: p,
    };
    final rua = Paint()
      ..color = c.mapLine
      ..strokeWidth = (12 * k).clamp(6.0, 22.0)
      ..strokeCap = StrokeCap.round;
    for (final t in dados.trechos) {
      final a = noPiso[t.de], b = noPiso[t.para];
      if (a == null || b == null) continue;
      canvas.drawLine(_t(a.x, a.y), _t(b.x, b.y), rua);
    }
    for (final p in noPiso.values) {
      if (p.tipo == TipoPonto.corredor) continue;
      canvas.drawCircle(_t(p.x, p.y), 5, Paint()..color = c.inkMuted);
    }
    // Pino: alfinete com contorno forte (visível em qualquer tema).
    final o = _t(pino.dx, pino.dy);
    final cabeca = o - const Offset(0, 22);
    final corpo = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(cabeca.dx - 9, cabeca.dy + 4)
      ..lineTo(cabeca.dx + 9, cabeca.dy + 4)
      ..close();
    final contorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = c.ink;
    canvas.drawPath(corpo, Paint()..color = c.marker);
    canvas.drawPath(corpo, contorno);
    canvas.drawCircle(cabeca, 11, Paint()..color = c.marker);
    canvas.drawCircle(cabeca, 11, contorno);
    canvas.drawCircle(cabeca, 4, Paint()..color = c.ink);
  }

  @override
  bool shouldRepaint(_MiniPlantaPainter old) =>
      old.pino != pino || old.piso != piso || old.k != k || old.c != c;
}
