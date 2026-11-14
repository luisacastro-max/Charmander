import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/voz/voz.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/comunicacao.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/assistencia.dart';
import '../../domain/rules/informacao.dart';
import '../comunicacao/cartao_ajuda_screen.dart';
import '../comunicacao/mensagens_rapidas.dart';
import '../welcome_preferences/preferences_scope.dart';
import 'ajuda_animacoes.dart';

enum _Etapa { pedido, revisao, acompanhamento }

/// Ajuda+ (T09/T10, RF36–RF43): pedir apoio só quando quiser, do seu jeito.
///
/// 1. **Pedido:** o que está acontecendo, onde você está (confirmado pelo
///    visitante), como prefere ser atendido e detalhes opcionais.
/// 2. **Revisão:** resumo para confirmar ou corrigir antes de enviar.
/// 3. **Acompanhamento:** estados demonstrativos, cancelar, cartão de
///    ajuda durante a espera e retorno ao percurso.
///
/// **Simulação:** nenhum pedido sai do aparelho e nenhuma equipe real é
/// acionada.
class AjudaScreen extends StatefulWidget {
  const AjudaScreen({
    super.key,
    this.pontoId,
    this.destino,
    this.dados,
    this.durantePercurso = false,
  });

  /// Ponto de referência atual (beacon simulado). Sem ele, a Entrada
  /// Principal é sugerida e o visitante confirma ou troca.
  final String? pontoId;

  /// Destino da rota, se houver, para o cartão de ajuda.
  final String? destino;
  final ShoppingData? dados;

  /// Aberto durante a navegação: ao final, oferece retomar o percurso.
  final bool durantePercurso;

  @override
  State<AjudaScreen> createState() => _AjudaScreenState();
}

class _AjudaScreenState extends State<AjudaScreen> {
  _Etapa _etapa = _Etapa.pedido;
  CategoriaAjuda? _categoria;
  FormaAtendimento? _forma;
  String? _pontoId;
  final _detalhes = TextEditingController();
  bool _faltaCategoria = false;
  PedidoAjuda? _pedido;

  /// Direção da troca de etapa (para a transição deslizar para o lado certo).
  bool _avancando = true;

  /// Conta tentativas sem categoria, para a lista "tremer" a cada uma.
  int _tentativasSemCategoria = 0;

  void _irPara(_Etapa nova) {
    _avancando = nova.index >= _etapa.index;
    _etapa = nova;
  }

  ShoppingData? get _dados => widget.dados ?? DadosScope.maybeOf(context);

  PontoReferencia? get _ponto {
    final d = _dados;
    final id = _pontoId ?? widget.pontoId ?? 'ENT_P';
    if (d == null) return null;
    return d.pontos.where((p) => p.id == id).firstOrNull;
  }

  String get _local {
    final p = _ponto;
    return p == null ? 'Local não informado' : '${p.nome} · ${exibir(p.piso)}';
  }

  /// Respeita as preferências já escolhidas (sem perguntar de novo).
  FormaAtendimento get _formaEscolhida {
    if (_forma != null) return _forma!;
    final p = PreferencesScope.maybeOf(context)?.prefs;
    if (p == null) return FormaAtendimento.presencial;
    if (p.textCommunication || p.quickMessages) {
      return FormaAtendimento.mensagem;
    }
    if (p.audioGuidance) return FormaAtendimento.audio;
    return FormaAtendimento.presencial;
  }

  @override
  void dispose() {
    _detalhes.dispose();
    super.dispose();
  }

  /// Leitor de tela e, com "Orientações por áudio", voz — no idioma do
  /// visitante. [s] em português.
  void _anunciar(String s) => anunciar(context, s);

  void _revisar() {
    if (_categoria == null) {
      setState(() {
        _faltaCategoria = true;
        _tentativasSemCategoria++;
      });
      HapticFeedback.lightImpact();
      _anunciar('Escolha o que está acontecendo.');
      return;
    }
    setState(() => _irPara(_Etapa.revisao));
  }

  void _enviar() {
    final p = PedidoAjuda(
      categoria: _categoria!,
      forma: _formaEscolhida,
      local: _local,
      detalhes: _detalhes.text.trim(),
    );
    setState(() {
      _pedido = p;
      _irPara(_Etapa.acompanhamento);
    });
    HapticFeedback.mediumImpact();
    _anunciar(p.aviso);
  }

  void _mudarPedido(PedidoAjuda novo) {
    setState(() => _pedido = novo);
    HapticFeedback.selectionClick();
    _anunciar(novo.aviso);
  }

  void _novoPedido() => setState(() {
    _irPara(_Etapa.pedido);
    _pedido = null;
    _categoria = null;
    _detalhes.clear();
  });

  void _abrirCartao() =>
      Navigator.of(context)
          .push(acessaRoute<void>(CartaoAjudaScreen(destino: widget.destino)));

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final titulo = switch (_etapa) {
      _Etapa.pedido => 'Ajuda+',
      _Etapa.revisao => tr(context, 'Confira seu pedido'),
      _Etapa.acompanhamento => tr(context, 'Acompanhamento'),
    };
    final mensagensRapidas =
        PreferencesScope.maybeOf(context)?.prefs.quickMessages ?? false;
    return PopScope(
      // Na revisão, "voltar" corrige o pedido em vez de sair.
      canPop: _etapa != _Etapa.revisao,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) setState(() => _irPara(_Etapa.pedido));
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: AnimatedSwitcher(
            duration: motion.d(Motion.base),
            switchInCurve: Motion.enter,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, .4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            layoutBuilder: (atual, anteriores) => Stack(
              alignment: Alignment.centerLeft,
              children: [...anteriores, ?atual],
            ),
            child: Text(titulo, key: ValueKey(titulo)),
          ),
          leading: IconButton(
            tooltip: tr(context, 'Voltar'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              tooltip: tr(context, 'Cartão de ajuda'),
              icon: const Icon(Icons.front_hand_outlined),
              onPressed: _abrirCartao,
            ),
          ],
        ),
        // Com "Mensagens rápidas em destaque", o botão flutuante fica sempre
        // à mão; a lista ganha espaço embaixo para ele não cobrir botões.
        floatingActionButton: BotaoMensagensRapidas(destino: widget.destino),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AcessaSpacing.lg,
                0,
                AcessaSpacing.lg,
                AcessaSpacing.md,
              ),
              child: ProgressoEtapas(atual: _etapa.index),
            ),
            Expanded(
              // Transição de "eixo compartilhado": a etapa nova desliza do
              // lado para onde o pedido avança; a antiga sai pelo outro.
              child: AnimatedSwitcher(
                duration: motion.d(Motion.base + Motion.quick),
                switchInCurve: Motion.enter,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) {
                  final entrando = child.key == ValueKey(_etapa);
                  final lado = _avancando ? 1.0 : -1.0;
                  return IgnorePointer(
                    ignoring: !entrando,
                    child: ExcludeSemantics(
                      excluding: !entrando,
                      child: FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: Offset((entrando ? .12 : -.12) * lado, 0),
                            end: Offset.zero,
                          ).animate(a),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                layoutBuilder: (atual, anteriores) => Stack(
                  fit: StackFit.expand,
                  children: [...anteriores, ?atual],
                ),
                child: ListView(
                  key: ValueKey(_etapa),
                  // Cada etapa tem a própria rolagem durante a transição.
                  primary: false,
                  padding: EdgeInsets.fromLTRB(
                    AcessaSpacing.lg,
                    0,
                    AcessaSpacing.lg,
                    AcessaSpacing.xl + (mensagensRapidas ? 72 : 0),
                  ),
                  children: switch (_etapa) {
                    _Etapa.pedido => _formulario(context),
                    _Etapa.revisao => _revisao(context),
                    _Etapa.acompanhamento => _acompanhamento(context),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 1. Pedido ─────────────────────────

  List<Widget> _formulario(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final dados = _dados;
    final ponto = _ponto;
    final sugestoes = ponto == null || dados == null
        ? const <AcaoSugerida>[]
        : dados.sugestoes
              .where((s) => s.pontoId == ponto.id)
              .expand((s) => s.acoes)
              .where((a) => a.mensagem != null)
              .toList();

    return [
      Surgir(
        index: 0,
        child: Text(
          tr(
            context,
            'Peça apoio só se quiser. Você decide como ser atendido(a).',
          ),
          style: text.bodyLarge,
        ),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      Surgir(index: 1, child: _Titulo(tr(context, 'O que está acontecendo?'))),
      if (_faltaCategoria && _categoria == null)
        Semantics(
          liveRegion: true,
          child: Tremor(
            aoAparecer: true,
            gatilho: _tentativasSemCategoria,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: c.ink),
                  const SizedBox(width: AcessaSpacing.xs),
                  Expanded(
                    child: Text(
                      tr(context, 'Escolha uma opção para continuar.'),
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      // A lista inteira balança quando se tenta seguir sem escolher.
      Tremor(
        gatilho: _tentativasSemCategoria,
        child: RadioGroup<CategoriaAjuda>(
          groupValue: _categoria,
          onChanged: (v) => setState(() => _categoria = v),
          child: Column(
            children: [
              for (final (n, cat) in CategoriaAjuda.values.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
                  child: Surgir(
                    index: 2 + n,
                    child: _Opcao(
                      icone: _iconeCategoria(cat),
                      texto: tr(context, cat.texto),
                      selecionada: _categoria == cat,
                      // Contraste do círculo também na opção destacada.
                      radio: Radio<CategoriaAjuda>(
                        value: cat,
                        fillColor: WidgetStatePropertyAll(
                          _categoria == cat ? c.onAccent : c.ink,
                        ),
                      ),
                      onTap: () => setState(() => _categoria = cat),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AcessaSpacing.md),
      Surgir(index: 7, child: _Titulo(tr(context, 'Onde você está'))),
      StickerCard(
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PinoCaindo(local: _local),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.of(context).d(Motion.base),
                    transitionBuilder: (child, a) =>
                        FadeTransition(opacity: a, child: child),
                    layoutBuilder: (atual, anteriores) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...anteriores, ?atual],
                    ),
                    child: Text(
                      tr(context, _local),
                      key: ValueKey(_local),
                      style: text.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            if (ponto != null) ...[
              const SizedBox(height: AcessaSpacing.xs),
              Text(
                tr(
                  context,
                  'Pelo beacon ${ponto.beacon} (simulado). Confira e troque '
                  'se não estiver certo.',
                ),
                style: text.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            ],
            if (dados != null) ...[
              const SizedBox(height: AcessaSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: ponto?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(context, 'Trocar local'),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in dados.pontosSimulaveis)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(tr(context, '${p.nome} · ${exibir(p.piso)}')),
                    ),
                ],
                onChanged: (id) => setState(() => _pontoId = id),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      _Titulo(tr(context, 'Como prefere ser atendido(a)?')),
      Wrap(
        spacing: AcessaSpacing.sm,
        runSpacing: AcessaSpacing.sm,
        children: [
          for (final f in FormaAtendimento.values)
            ChoiceChip(
              label: Text(tr(context, f.texto)),
              avatar: Icon(_iconeForma(f), size: 20),
              selected: _formaEscolhida == f,
              onSelected: (_) => setState(() => _forma = f),
              showCheckmark: false,
              labelStyle: text.titleMedium?.copyWith(
                color: _formaEscolhida == f ? c.onPrimary : c.ink,
              ),
              selectedColor: c.primary,
              backgroundColor: c.surface,
              side: BorderSide(color: c.border, width: 1.5),
            ),
        ],
      ),
      const SizedBox(height: AcessaSpacing.xs),
      Text(
        tr(
          context,
          'É a sua preferência; a disponibilidade depende do shopping.',
        ),
        style: text.bodyMedium?.copyWith(color: c.inkMuted),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      _Titulo(tr(context, 'Detalhes (opcional)')),
      if (sugestoes.isNotEmpty) ...[
        Text(tr(context, 'Frases para este local:'), style: text.bodyMedium),
        const SizedBox(height: AcessaSpacing.xs),
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          children: [
            for (final s in sugestoes)
              ActionChip(
                label: Text(tr(context, s.titulo)),
                avatar: const Icon(Icons.add, size: 18),
                onPressed: () =>
                    setState(() => _detalhes.text = tr(context, s.mensagem!)),
              ),
          ],
        ),
        const SizedBox(height: AcessaSpacing.sm),
      ],
      TextField(
        controller: _detalhes,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: tr(context, 'Se quiser, conte mais'),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      StickerButton(
        label: tr(context, 'Revisar pedido'),
        icon: Icons.arrow_forward,
        onPressed: _revisar,
      ),
      const SizedBox(height: AcessaSpacing.md),
      SimulationNotice(
        text: tr(
          context,
          'Demonstração: o pedido fica só neste aparelho e nenhuma equipe '
          'real é acionada.',
        ),
      ),
    ];
  }

  // ───────────────────────── 2. Revisão ─────────────────────────

  List<Widget> _revisao(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detalhes = _detalhes.text.trim();
    final linhas = [
      _Linha(
        Icons.help_outline,
        tr(context, 'O que acontece'),
        tr(context, _categoria!.texto),
      ),
      _Linha(Icons.my_location, tr(context, 'Onde'), tr(context, _local)),
      _Linha(
        _iconeForma(_formaEscolhida),
        tr(context, 'Atendimento'),
        tr(context, _formaEscolhida.texto),
      ),
      _Linha(
        Icons.notes,
        tr(context, 'Detalhes'),
        detalhes.isEmpty ? tr(context, 'Nenhum') : detalhes,
      ),
    ];
    return [
      Surgir(
        index: 0,
        child: Text(tr(context, 'Está tudo certo?'), style: text.headlineSmall),
      ),
      const SizedBox(height: AcessaSpacing.md),
      Surgir(
        index: 1,
        child: StickerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cada item do resumo entra em sequência, como um checklist.
              for (final (n, l) in linhas.indexed)
                Surgir(index: 2 + n, child: l),
            ],
          ),
        ),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      Surgir(
        index: 6,
        child: StickerButton(
          label: tr(context, 'Confirmar e pedir ajuda'),
          icon: Icons.check,
          onPressed: _enviar,
        ),
      ),
      const SizedBox(height: AcessaSpacing.sm),
      Surgir(
        index: 7,
        child: StickerButton(
          label: tr(context, 'Corrigir'),
          icon: Icons.edit_outlined,
          kind: StickerButtonKind.secondary,
          onPressed: () => setState(() => _irPara(_Etapa.pedido)),
        ),
      ),
    ];
  }

  // ─────────────────────── 3. Acompanhamento ───────────────────────

  List<Widget> _acompanhamento(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final p = _pedido!;
    final motion = Motion.of(context);
    return [
      Surgir(
        index: 0,
        child: StickerCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, p.categoria.texto),
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: AcessaSpacing.xs),
                    Text('📍 ${tr(context, p.local)}', style: text.bodyLarge),
                    Text(
                      tr(context, 'Preferência: ${p.forma.texto}'),
                      style: text.bodyLarge,
                    ),
                    if (p.detalhes.isNotEmpty)
                      Text('“${p.detalhes}”', style: text.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(width: AcessaSpacing.sm),
              // Momento do envio: o selo cresce, o ✓ se desenha e
              // solta confete (uma vez, ao abrir o acompanhamento).
              const SeloEnviado(),
            ],
          ),
        ),
      ),
      const SizedBox(height: AcessaSpacing.md),
      Semantics(
        liveRegion: true,
        child: Surgir(
          index: 2,
          // Ao cancelar, a linha do tempo perde a cor e encolhe; o aviso
          // de cancelado entra no lugar com uma tremidinha.
          child: AnimatedSwitcher(
            duration: motion.d(Motion.slow),
            switchInCurve: Motion.enter,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, a) {
              final saindo = child.key == const ValueKey('estados');
              // Align em vez de SizeTransition: não recorta o confete.
              return FadeTransition(
                opacity: a,
                child: AnimatedBuilder(
                  animation: a,
                  builder: (context, filho) => Align(
                    alignment: Alignment.topCenter,
                    heightFactor: a.value.clamp(0.0, 1.0),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        _saturacao(saindo && p.cancelado ? a.value : 1),
                      ),
                      child: filho,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: p.cancelado
                ? Tremor(
                    key: const ValueKey('cancelado'),
                    aoAparecer: true,
                    child: StickerCard(
                      shadow: false,
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: c.ink, size: 30),
                          const SizedBox(width: AcessaSpacing.sm),
                          Expanded(
                            child: Text(
                              tr(context, 'Solicitação cancelada'),
                              style: text.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : LinhaDoTempo(key: const ValueKey('estados'), atual: p.estado),
          ),
        ),
      ),
      const SizedBox(height: AcessaSpacing.md),
      Surgir(
        index: 3,
        child: SimulationNotice(
          text: tr(
            context,
            'Simulação para demonstração: nenhuma equipe real foi acionada.',
          ),
        ),
      ),
      const SizedBox(height: AcessaSpacing.lg),
      if (p.emAndamento) ...[
        Surgir(
          key: const ValueKey('avancar'),
          index: 4,
          child: StickerButton(
            label: tr(context, 'Avançar etapa (demonstração)'),
            icon: Icons.fast_forward_outlined,
            onPressed: () => _mudarPedido(p.avancar()),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Surgir(
          key: const ValueKey('cartao'),
          index: 5,
          child: StickerButton(
            label: tr(context, 'Mostrar cartão enquanto espera'),
            icon: Icons.front_hand_outlined,
            kind: StickerButtonKind.secondary,
            onPressed: _abrirCartao,
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Surgir(
          key: const ValueKey('cancelar'),
          index: 6,
          child: StickerButton(
            label: tr(context, 'Cancelar solicitação'),
            icon: Icons.close,
            kind: StickerButtonKind.secondary,
            onPressed: () => _mudarPedido(p.cancelar()),
          ),
        ),
      ] else ...[
        // Chaves próprias: os botões finais entram em cascata ao aparecer.
        if (widget.durantePercurso) ...[
          Surgir(
            key: const ValueKey('retomar'),
            index: 2,
            child: StickerButton(
              label: tr(context, 'Retomar percurso'),
              icon: Icons.navigation_outlined,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: AcessaSpacing.sm),
        ],
        Surgir(
          key: const ValueKey('inicio'),
          index: 3,
          child: StickerButton(
            label: tr(context, 'Voltar ao início'),
            icon: Icons.home_outlined,
            kind: widget.durantePercurso
                ? StickerButtonKind.secondary
                : StickerButtonKind.primary,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Surgir(
          key: const ValueKey('novo'),
          index: 4,
          child: StickerButton(
            label: tr(context, 'Novo pedido'),
            icon: Icons.add,
            kind: StickerButtonKind.secondary,
            onPressed: _novoPedido,
          ),
        ),
      ],
    ];
  }
}

IconData _iconeCategoria(CategoriaAjuda c) => switch (c) {
  CategoriaAjuda.encontrarLocal => Icons.travel_explore,
  CategoriaAjuda.acompanhamento => Icons.directions_walk,
  CategoriaAjuda.barreira => Icons.do_not_step,
  CategoriaAjuda.comunicacao => Icons.forum_outlined,
  CategoriaAjuda.funcionario => Icons.badge_outlined,
};

IconData _iconeForma(FormaAtendimento f) => switch (f) {
  FormaAtendimento.mensagem => Icons.chat_outlined,
  FormaAtendimento.audio => Icons.volume_up_outlined,
  FormaAtendimento.presencial => Icons.person_outline,
};

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

/// Opção grande, toda clicável (não só o círculo do rádio).
///
/// Ao ser escolhida, acende em limão, "salta" um pouco e o ícone dá uma
/// balançadinha (uma vez). O rádio e a cor continuam dizendo o estado.
class _Opcao extends StatefulWidget {
  const _Opcao({
    required this.icone,
    required this.texto,
    required this.selecionada,
    required this.radio,
    required this.onTap,
  });

  final IconData icone;
  final String texto;
  final bool selecionada;
  final Widget radio;
  final VoidCallback onTap;

  @override
  State<_Opcao> createState() => _OpcaoState();
}

class _OpcaoState extends State<_Opcao> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(_Opcao old) {
    super.didUpdateWidget(old);
    if (!old.selecionada && widget.selecionada) {
      if (Motion.of(context).enabled) _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    if (!motion.enabled && _c.isAnimating) _c.value = 1;
    final sel = widget.selecionada;
    return MergeSemantics(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AcessaRadius.card),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            // Pulo curto: cresce 4% e volta (sen(πt) começa e termina em 0).
            return Transform.scale(
              scale: 1 + .04 * math.sin(math.pi * t),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: motion.d(Motion.base),
            curve: Motion.pop,
            padding: const EdgeInsets.symmetric(
              horizontal: AcessaSpacing.sm,
              vertical: AcessaSpacing.xs,
            ),
            // Selecionada "descola" do fundo: sobe e ganha sombra.
            transform: Matrix4.translationValues(sel ? -2 : 0, sel ? -2 : 0, 0),
            decoration: BoxDecoration(
              color: sel ? c.help : c.surface,
              borderRadius: BorderRadius.circular(AcessaRadius.card),
              border: Border.all(
                color: sel ? c.shadow : c.border,
                width: AcessaSticker.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: sel ? c.shadow : c.shadow.withValues(alpha: 0),
                  offset: sel ? AcessaSticker.shadowOffset : Offset.zero,
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                widget.radio,
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) {
                    final t = _c.value;
                    // Balançadinha: três idas e vindas que vão diminuindo.
                    final ang = math.sin(t * math.pi * 6) * .35 * (1 - t);
                    return Transform.rotate(angle: ang, child: child);
                  },
                  child: Icon(widget.icone, color: sel ? c.onAccent : c.ink),
                ),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Text(
                    widget.texto,
                    style: text.titleMedium?.copyWith(
                      color: sel ? c.onAccent : c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.rotulo, this.valor);
  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: c.inkMuted),
            const SizedBox(width: AcessaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                  Text(valor, style: text.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matriz de saturação (1 = cores normais, 0 = tons de cinza).
List<double> _saturacao(double s) {
  const r = .2126, g = .7152, b = .0722;
  final i = 1 - s;
  return [
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0, //
    r * i, g * i, b * i + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
