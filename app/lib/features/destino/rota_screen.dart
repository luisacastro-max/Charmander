import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/icones.dart';
import '../../core/widgets/preference_toggle.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../core/voz/voz.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/alertas_apresentacao.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/ocorrencias.dart';
import '../../domain/rules/rota_adaptada.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/rules/viagem.dart';
import '../ajuda/ajuda_screen.dart';
import '../alertas/alertas_controller.dart';
import '../alertas/alertas_visual.dart';
import '../alertas/detalhes_alerta.dart';
import '../alertas/reportar_alerta_screen.dart';
import '../comunicacao/mensagens_rapidas.dart';
import '../navegacao/navegacao_screen.dart';
import '../welcome_preferences/preferences_scope.dart';
import '../welcome_preferences/preferences_screen.dart';
import 'destino_screen.dart';

/// Resumo da rota (T05 simplificada): distância, tempo, pisos, critérios
/// considerados e as etapas em texto (RF13, RF15, RF18). A rota é
/// recalculada quando as preferências mudam (RF45).
///
/// Etapa 3b: como num app de transporte, o visitante pode acrescentar
/// paradas ("primeiro o elevador, depois a Praça de Alimentação"),
/// reordenar e remover, antes de iniciar a navegação.
class RotaScreen extends StatefulWidget {
  const RotaScreen({
    super.key,
    required this.origemId,
    required this.destino,
    required this.dados,
    this.paradasAntes = const [],
  });

  final String origemId;

  /// Destino escolhido na tela "Para onde?".
  final Local destino;
  final ShoppingData dados;

  /// Paradas escolhidas com o "+" antes do destino.
  final List<Local> paradasAntes;

  @override
  State<RotaScreen> createState() => _RotaScreenState();
}

class _RotaScreenState extends State<RotaScreen> {
  late final List<Local> _paradas = [...widget.paradasAntes, widget.destino];
  String _aviso = '';

  /// O resumo falado sai uma vez só por abertura da tela.
  bool _resumoFalado = false;

  /// Último motivo de "sem rota" anunciado (evita repetir a cada rebuild).
  String? _motivoAnunciado;

  /// Trechos de elevador "em manutenção" na simulação (RN04). Só em
  /// memória desta tela: some ao sair e nunca vira preferência.
  Set<String> _emManutencao = const {};

  /// Alertas que a rota já desviava no último quadro (para anunciar só
  /// quando um alerta novo muda o caminho).
  Set<String>? _evitadosAntes;

  void _anunciarDesvio(List<Ocorrencia> evitados) {
    final ids = {for (final o in evitados) o.id};
    final antes = _evitadosAntes;
    _evitadosAntes = ids;
    if (antes == null || ids.difference(antes).isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        anunciar(
          context,
          'Rota atualizada para desviar de alerta da comunidade.',
        );
      }
    });
  }

  void _simularManutencao(bool ativa, Set<String> elevadores) {
    setState(() => _emManutencao = ativa ? elevadores : const {});
    anunciar(
      context,
      ativa
          ? 'Simulação: elevador em manutenção. Rota recalculada.'
          : 'Simulação encerrada. Rota recalculada.',
    );
  }

  ShoppingData get dados => widget.dados;

  /// Áudio (P11) e leitor de tela: fala o resumo ao abrir e anuncia
  /// quando a rota fica impossível. Roda depois do quadro, nunca em
  /// todo rebuild.
  void _falarSePreciso(ResultadoViagem resultado, Local destino) {
    String? fala;
    String? anuncio;
    if (resultado is ViagemImpossivel) {
      final motivo = resultado.motivo.motivo;
      if (motivo != _motivoAnunciado) {
        _motivoAnunciado = motivo;
        anuncio = motivo;
      }
      _resumoFalado = true;
    } else if (resultado is Viagem) {
      _motivoAnunciado = null;
      if (!_resumoFalado) {
        _resumoFalado = true;
        fala = resumoFalado(resultado, destino.nome);
      }
    }
    if (fala == null && anuncio == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (anuncio != null) anunciar(context, anuncio);
      if (fala != null) Voz.instancia.falar(context, fala);
    });
  }

  Future<void> _adicionarParada() async {
    final ultima = _paradas.last;
    final escolhido = await Navigator.of(context).push<Local>(
      acessaRoute(
        DestinoScreen(
          pontoInicial: ultima.pontoId,
          paradaDepoisDe: ultima.nome,
        ),
      ),
    );
    if (escolhido == null || !mounted) return;
    if (escolhido.pontoId == ultima.pontoId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, '${escolhido.nome} já é a última parada.')),
        ),
      );
      return;
    }
    setState(() {
      _paradas.add(escolhido);
      _aviso =
          '${escolhido.nome} adicionada como parada ${_paradas.length}. '
          'Rota recalculada.';
    });
  }

  void _remover(int i) => setState(() {
    final l = _paradas.removeAt(i);
    _aviso = '${l.nome} removida. Rota recalculada.';
  });

  void _mover(int i, int para) => setState(() {
    final l = _paradas.removeAt(i);
    _paradas.insert(para, l);
    _aviso = '${l.nome} agora é a parada ${para + 1}. Rota recalculada.';
  });

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final prefs = PreferencesScope.of(context).prefs;
    // Alertas da comunidade ativos entram nos critérios e a rota é
    // recalculada sozinha quando chegam, mudam ou deixam de valer.
    final alertas = AlertasScope.maybeOf(context);
    final impacto = alertas?.impacto(dados) ?? ImpactoAlertas.vazio;
    final criterios = impacto.aplicar(
      criteriosDe(prefs).copyWith(indisponiveis: _emManutencao),
    );
    final ids = [for (final p in _paradas) p.pontoId];
    final resultado = dados.motor.calcularViagem(
      widget.origemId,
      ids,
      criterios,
    );
    final semAlertas = criterios.temAlertas
        ? dados.motor.calcularViagem(widget.origemId, ids, criterios.semAlertas)
        : null;
    final evitados = semAlertas is Viagem
        ? alertasEvitados(semAlertas, resultado, impacto)
        : const <Ocorrencia>[];
    _anunciarDesvio(evitados);
    final noCaminho = resultado is Viagem
        ? alertasNaViagem(resultado, impacto)
        : const <AlertaNoCaminho>[];
    final destino = _paradas.last;
    _falarSePreciso(resultado, destino);

    // Rota mais usada x rota adaptada: só aparece quando o caminho muda.
    final comparacao = resultado is Viagem && criterios.temRestricao
        ? dados.motor.compararViagem(widget.origemId, ids, criterios)
        : null;
    final desvio = comparacao is ComparacaoViagem && comparacao.mudou
        ? comparacao
        : null;

    // A simulação aparece quando a rota usa elevador (ou já está ativa).
    final elevadores = _emManutencao.isNotEmpty
        ? _emManutencao
        : resultado is Viagem
        ? {for (final t in resultado.trechosDeElevador) t.id}
        : const <String>{};
    final simulacao = elevadores.isEmpty
        ? null
        : _SimulacaoManutencao(
            ativa: _emManutencao.isNotEmpty,
            onChanged: (v) => _simularManutencao(v, elevadores),
          );

    var i = 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: tr(context, 'Voltar para a busca'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      floatingActionButton: BotaoMensagensRapidas(destino: destino.nome),
      body: ListView(
        // Espaço extra para o botão "Mensagens rápidas" não cobrir o
        // último botão da lista.
        padding: EdgeInsets.fromLTRB(
          AcessaSpacing.lg,
          0,
          AcessaSpacing.lg,
          prefs.quickMessages ? AcessaSpacing.xl + 88 : AcessaSpacing.xl,
        ),
        children: [
          Entrance(
            index: i++,
            child: Text(
              tr(context, 'Rota até'),
              style: text.titleMedium?.copyWith(color: c.inkMuted),
            ),
          ),
          Entrance(
            index: i++,
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(iconeDoLocal(destino.icone), color: c.focus, size: 34),
                  const SizedBox(width: AcessaSpacing.sm),
                  Expanded(
                    child: Text(destino.nome, style: text.displayMedium),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          Entrance(
            index: i++,
            child: _PainelParadas(
              origem: dados.ponto(widget.origemId),
              paradas: _paradas,
              falhou: resultado is ViagemImpossivel ? resultado.perna : null,
              onAdicionar: _paradas.length < maxParadas
                  ? _adicionarParada
                  : null,
              onRemover: _remover,
              onMover: _mover,
            ),
          ),
          // Anuncia mudanças na lista de paradas para leitores de tela.
          Semantics(
            liveRegion: true,
            child: _aviso.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AcessaSpacing.sm),
                    child: Text(
                      tr(context, _aviso),
                      style: text.bodyMedium?.copyWith(color: c.inkMuted),
                    ),
                  ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          switch (resultado) {
            Viagem() => _ComRota(
              viagem: resultado,
              destino: destino,
              pontoDestino: dados.ponto(destino.pontoId),
              primeiroIndice: i,
              dados: dados,
              desvio: desvio,
              simulacao: simulacao,
              impacto: impacto,
              alertasNoCaminho: noCaminho,
              evitados: evitados,
            ),
            ViagemImpossivel() => Entrance(
              index: i,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (simulacao != null) ...[
                    simulacao,
                    const SizedBox(height: AcessaSpacing.md),
                  ],
                  if (evitados.isNotEmpty) ...[
                    _DesviosCard(evitados: evitados, dados: dados),
                    const SizedBox(height: AcessaSpacing.md),
                  ],
                  _SemRotaCard(
                    resultado: resultado.motivo,
                    onRemoverParada: _paradas.length > 1
                        ? () => _remover(resultado.perna)
                        : null,
                    nomeParada: _paradas[resultado.perna].nome,
                    onPedirAjuda: () => Navigator.of(context).push(
                      acessaRoute<void>(
                        AjudaScreen(
                          pontoId: widget.origemId,
                          destino: _paradas[resultado.perna].nome,
                          dados: dados,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          },
          const SizedBox(height: AcessaSpacing.lg),
          StickerButton(
            label: tr(context, 'Reportar problema'),
            icon: Icons.add_alert_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: tr(
              context,
              'Avisa outras pessoas sobre algo que atrapalha o caminho',
            ),
            onPressed: () => Navigator.of(context).push(
              acessaRoute<void>(
                ReportarAlertaScreen(
                  dados: dados,
                  pontoInicialId: widget.origemId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de paradas no estilo dos apps de transporte: origem, paradas
/// numeradas e o destino final, com botões para reordenar e remover
/// (botões em vez de arrastar, para quem usa leitor de tela ou teclado).
class _PainelParadas extends StatelessWidget {
  const _PainelParadas({
    required this.origem,
    required this.paradas,
    required this.falhou,
    required this.onAdicionar,
    required this.onRemover,
    required this.onMover,
  });

  final PontoReferencia origem;
  final List<Local> paradas;
  final int? falhou;
  final VoidCallback? onAdicionar;
  final ValueChanged<int> onRemover;
  final void Function(int de, int para) onMover;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final varias = paradas.length > 1;

    Widget marcador(Widget filho, Color cor, {bool cheio = true}) => Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cheio ? cor : c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: 2),
      ),
      child: filho,
    );

    Widget botao(IconData icone, String dica, VoidCallback? onTap) =>
        IconButton(
          tooltip: dica,
          onPressed: onTap,
          icon: Icon(icone),
          color: c.ink,
          disabledColor: c.inkMuted.withValues(alpha: .35),
          constraints: const BoxConstraints(
            minWidth: AcessaSpacing.minTouch,
            minHeight: AcessaSpacing.minTouch,
          ),
        );

    return StickerCard(
      color: c.surface,
      borderColor: c.navigation,
      padding: const EdgeInsets.fromLTRB(
        AcessaSpacing.md,
        AcessaSpacing.sm,
        AcessaSpacing.xs,
        AcessaSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AcessaSpacing.sm),
              child: Row(
                children: [
                  marcador(
                    Icon(Icons.my_location, size: 18, color: c.navigation),
                    c.navigation,
                    cheio: false,
                  ),
                  const SizedBox(width: AcessaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'Saindo de'),
                          style: text.bodyMedium?.copyWith(color: c.inkMuted),
                        ),
                        Text(origem.nome, style: text.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (n, l) in paradas.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  marcador(
                    n == paradas.length - 1
                        ? Icon(Icons.flag, size: 18, color: c.onAccent)
                        : Text(
                            '${n + 1}',
                            style: text.labelLarge?.copyWith(color: c.onAccent),
                          ),
                    falhou == n ? c.simulation : c.help,
                  ),
                  const SizedBox(width: AcessaSpacing.md),
                  Expanded(
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              context,
                              !varias
                                  ? 'Destino'
                                  : n == paradas.length - 1
                                  ? 'Destino final'
                                  : 'Parada ${n + 1}',
                            ),
                            style: text.bodyMedium?.copyWith(color: c.inkMuted),
                          ),
                          Text(l.nome, style: text.titleMedium),
                          if (falhou == n)
                            Text(
                              tr(context, 'Sem caminho compatível até aqui'),
                              style: text.bodyMedium?.copyWith(
                                color: c.simulation,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (varias) ...[
                    botao(
                      Icons.arrow_upward,
                      tr(context, 'Mover ${l.nome} para antes'),
                      n == 0 ? null : () => onMover(n, n - 1),
                    ),
                    botao(
                      Icons.arrow_downward,
                      tr(context, 'Mover ${l.nome} para depois'),
                      n == paradas.length - 1 ? null : () => onMover(n, n + 1),
                    ),
                    botao(
                      Icons.close,
                      tr(context, 'Remover ${l.nome}'),
                      () => onRemover(n),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AcessaSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                tr(
                  context,
                  onAdicionar == null
                      ? 'Limite de $maxParadas paradas'
                      : 'Adicionar outra parada',
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: c.focus,
                minimumSize: const Size(48, AcessaSpacing.minTouch),
                textStyle: text.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComRota extends StatelessWidget {
  const _ComRota({
    required this.viagem,
    required this.destino,
    required this.pontoDestino,
    required this.primeiroIndice,
    required this.dados,
    this.desvio,
    this.simulacao,
    this.impacto = ImpactoAlertas.vazio,
    this.alertasNoCaminho = const [],
    this.evitados = const [],
  });

  /// Alertas da comunidade ativos (para marcar as etapas com alerta).
  final ImpactoAlertas impacto;

  /// Avisos nos trechos que a rota usa.
  final List<AlertaNoCaminho> alertasNoCaminho;

  /// Alertas que a rota passou a evitar.
  final List<Ocorrencia> evitados;

  final Viagem viagem;
  final Local destino;
  final PontoReferencia pontoDestino;
  final int primeiroIndice;
  final ShoppingData dados;

  /// Comparação com a rota mais usada, quando a rota adaptada é outra.
  final ComparacaoViagem? desvio;

  /// Controle "Simular elevador em manutenção" (só quando faz sentido).
  final Widget? simulacao;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    var i = primeiroIndice;
    final varias = viagem.pernas.length > 1;

    if (viagem.totalEtapas == 0) {
      return Entrance(
        index: i,
        child: StickerCard(
          color: c.surface,
          borderColor: c.help,
          child: Text(
            tr(context, 'Você já está aqui.'),
            style: text.titleLarge,
          ),
        ),
      );
    }

    final badges = <(IconData, String)>[
      if (viagem.criterios.semEscadas)
        (Icons.accessible_forward, tr(context, 'Sem escadas'))
      else if (viagem.usaEscada)
        (Icons.stairs_outlined, tr(context, 'Tem degraus')),
      if (viagem.usaElevador)
        (Icons.elevator_outlined, tr(context, 'Usa elevador')),
      if (viagem.criterios.caminhoTranquilo)
        (Icons.spa_outlined, tr(context, 'Evita movimento')),
      if (varias)
        (Icons.alt_route, tr(context, '${viagem.pernas.length} paradas')),
    ];

    var numero = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          index: i++,
          child: _ResumoNeon(viagem: viagem, badges: badges),
        ),
        if (!viagem.criterios.semEscadas && viagem.usaEscada) ...[
          const SizedBox(height: AcessaSpacing.sm),
          Entrance(
            index: i++,
            child: SimulationNotice(
              text: tr(
                context,
                'Esta rota tem degraus. Se precisar evitar escadas, '
                'ative "Rotas sem escadas" nas preferências.',
              ),
            ),
          ),
        ],
        if (desvio case final d?) ...[
          const SizedBox(height: AcessaSpacing.md),
          Entrance(
            index: i++,
            child: _ComparacaoCard(comparacao: d),
          ),
        ],
        if (alertasNoCaminho.isNotEmpty) ...[
          const SizedBox(height: AcessaSpacing.md),
          _AlertasNoCaminhoCard(alertas: alertasNoCaminho, dados: dados),
        ],
        if (evitados.isNotEmpty) ...[
          const SizedBox(height: AcessaSpacing.md),
          _DesviosCard(evitados: evitados, dados: dados),
        ],
        const SizedBox(height: AcessaSpacing.lg),
        Entrance(
          index: i++,
          child: StickerButton(
            label: tr(context, 'Iniciar navegação'),
            icon: Icons.navigation_outlined,
            semanticHint: tr(context, 'Abre a bússola e o mapa interativo'),
            onPressed: () async {
              final nav = Navigator.of(context);
              final novoDestino = await nav.push<bool>(
                acessaRoute(
                  NavegacaoScreen(
                    viagem: viagem,
                    dados: dados,
                    rotaMaisUsada: desvio?.principal,
                  ),
                ),
              );
              // "Escolher novo destino" ao chegar: volta para "Para onde?".
              if (novoDestino == true) nav.pop();
            },
          ),
        ),
        if (simulacao case final s?) ...[
          const SizedBox(height: AcessaSpacing.lg),
          Entrance(index: i++, child: s),
        ],
        const SizedBox(height: AcessaSpacing.lg),
        Entrance(
          index: i++,
          child: Semantics(
            header: true,
            child: Text(tr(context, 'Passo a passo'), style: text.titleLarge),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        for (final (p, perna) in viagem.pernas.indexed) ...[
          if (varias)
            Padding(
              padding: const EdgeInsets.only(
                top: AcessaSpacing.xs,
                bottom: AcessaSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  tr(
                    context,
                    p == viagem.pernas.length - 1
                        ? 'Até o destino final: ${viagem.paradas[p].nome}'
                        : 'Até a parada ${p + 1}: ${viagem.paradas[p].nome}',
                  ),
                  style: text.titleMedium?.copyWith(color: c.help),
                ),
              ),
            ),
          if (perna.etapas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AcessaSpacing.md),
              child: Text(
                tr(context, 'Você já está aqui.'),
                style: text.bodyLarge?.copyWith(color: c.inkMuted),
              ),
            ),
          for (final (n, e) in perna.etapas.indexed)
            Entrance(
              index: (i + numero).clamp(0, 14),
              child: _Etapa(
                numero: ++numero,
                etapa: e,
                ultima: n == perna.etapas.length - 1,
                alertas: impacto.doTrecho(e.trecho.id),
              ),
            ),
        ],
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: _SobreDestino(local: destino, ponto: pontoDestino),
        ),
      ],
    );
  }
}

/// Cartão de destaque com distância animada (conta de 0 até o valor).
class _ResumoNeon extends StatelessWidget {
  const _ResumoNeon({required this.viagem, required this.badges});
  final Viagem viagem;
  final List<(IconData, String)> badges;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final fg = t.highContrast ? c.ink : c.onAccent;

    return Semantics(
      label: [
        tr(
          context,
          '${viagem.distanciaM} metros, cerca de ${viagem.minutos} minutos.',
        ),
        '${tr(context, 'Pisos:')} '
            '${viagem.pisos.map((p) => tr(context, p)).join(' ${tr(context, 'para')} ')}.',
        for (final b in badges) '${b.$2}.',
      ].join(' '),
      excludeSemantics: true,
      child: StickerCard(
        color: t.highContrast ? c.surface : c.help,
        borderColor: t.highContrast ? c.ink : c.shadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
              duration: motion.d(Motion.slow),
              curve: Motion.enter,
              builder: (context, v, _) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${(viagem.distanciaM * v).round()}',
                      style: text.displayLarge?.copyWith(color: fg),
                    ),
                    TextSpan(
                      text: ' m',
                      style: text.headlineMedium?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              tr(context, 'cerca de ${viagem.minutos} min a pé'),
              style: text.titleMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (n, p) in viagem.pisos.indexed) ...[
                  if (n > 0) Icon(Icons.arrow_forward, size: 18, color: fg),
                  Text(
                    tr(context, p),
                    style: text.titleMedium?.copyWith(color: fg),
                  ),
                ],
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: AcessaSpacing.sm),
              Wrap(
                spacing: AcessaSpacing.sm,
                runSpacing: AcessaSpacing.sm,
                children: [
                  for (final b in badges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: t.highContrast ? c.surface : c.onAccent,
                        borderRadius: BorderRadius.circular(AcessaRadius.pill),
                        border: t.highContrast
                            ? Border.all(color: c.ink, width: 2)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            b.$1,
                            size: 18,
                            color: t.highContrast ? c.ink : c.help,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            b.$2,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: t.highContrast ? c.ink : c.help,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({
    required this.numero,
    required this.etapa,
    required this.ultima,
    this.alertas = const [],
  });
  final int numero;
  final EtapaRota etapa;
  final bool ultima;

  /// Alertas da comunidade neste trecho.
  final List<Ocorrencia> alertas;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final troca = etapa.trecho.trocaPiso != null;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: troca ? c.navigation : c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.navigation, width: 2),
                  ),
                  child: Text(
                    '$numero',
                    style: text.labelLarge?.copyWith(
                      color: troca ? c.onAccent : c.ink,
                    ),
                  ),
                ),
                if (!ultima)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: c.navigation.withValues(alpha: .5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AcessaSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AcessaSpacing.md,
                  top: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, etapa.instrucao), style: text.bodyLarge),
                    Text(
                      '${etapa.para.nome} · '
                      '${tr(context, exibir(etapa.para.piso))}',
                      style: text.bodyMedium?.copyWith(color: c.inkMuted),
                    ),
                    for (final o in alertas)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            MarcadorAlerta(tipo: o.tipo, tamanho: 24),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tr(
                                  context,
                                  'Alerta da comunidade neste trecho: '
                                  '${o.tipo.rotulo}',
                                ),
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SobreDestino extends StatelessWidget {
  const _SobreDestino({required this.local, required this.ponto});
  final Local local;
  final PontoReferencia ponto;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    Widget linha(String rotulo, String valor) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: valor, style: text.bodyLarge),
          ],
        ),
      ),
    );
    return StickerCard(
      color: c.surface,
      borderColor: c.border.withValues(alpha: t.highContrast ? 1 : .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Sobre o destino'), style: text.titleLarge),
          const SizedBox(height: AcessaSpacing.sm),
          linha(tr(context, 'Piso'), tr(context, exibir(ponto.piso))),
          linha(tr(context, 'Horário'), tr(context, exibir(local.horario))),
          linha(tr(context, 'Descrição'), tr(context, exibir(local.descricao))),
          linha(
            tr(context, 'Recursos'),
            [for (final r in exibirRecursos(local.recursos)) tr(context, r)]
                .join(', '),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, 'Informações de demonstração, com dados fictícios.'),
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// RN04 / RF15: informa a limitação e oferece alternativas, sem mudar a
/// preferência do visitante por conta própria.
class _SemRotaCard extends StatelessWidget {
  const _SemRotaCard({
    required this.resultado,
    required this.nomeParada,
    required this.onPedirAjuda,
    this.onRemoverParada,
  });
  final SemRota resultado;
  final String nomeParada;

  /// Abre o Ajuda+ com o local atual.
  final VoidCallback onPedirAjuda;

  /// Só existe quando há mais de uma parada.
  final VoidCallback? onRemoverParada;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    // Bloqueio por alerta: explica e oferece ajuda, sem sugerir escadas.
    final porAlerta = resultado.bloqueiosPorAlerta.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: StickerCard(
            color: c.surface,
            borderColor: c.simulation,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: c.simulation,
                      size: 28,
                    ),
                    const SizedBox(width: AcessaSpacing.sm),
                    Expanded(
                      child: Text(
                        tr(context, resultado.motivo),
                        style: text.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AcessaSpacing.sm),
                Text(
                  tr(
                    context,
                    porAlerta
                        ? 'Um alerta da comunidade bloqueia o caminho que você '
                              'usaria. É um relato e pode já ter sido resolvido; '
                              'a rota volta sozinha quando o alerta deixar de '
                              'valer. Um funcionário do shopping pode ajudar.'
                        : resultado.existeComEscada
                        ? 'Sua preferência "Rotas sem escadas" continua ativa. '
                              'O app não muda isso sozinho.'
                        : 'Nenhum percurso cadastrado liga estes dois pontos.',
                  ),
                  style: text.bodyLarge?.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.lg),
        if (onRemoverParada != null) ...[
          StickerButton(
            label: tr(context, 'Remover a parada $nomeParada'),
            icon: Icons.remove_circle_outline,
            onPressed: onRemoverParada,
          ),
          const SizedBox(height: AcessaSpacing.md),
        ],
        StickerButton(
          label: tr(context, 'Escolher outro destino'),
          icon: Icons.search,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: AcessaSpacing.md),
        StickerButton(
          label: tr(context, 'Pedir ajuda'),
          kind: StickerButtonKind.secondary,
          icon: Icons.volunteer_activism_outlined,
          semanticHint: tr(
            context,
            'Abre o Ajuda+ com a sua localização atual',
          ),
          onPressed: onPedirAjuda,
        ),
        if (resultado.existeComEscada && !porAlerta) ...[
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: tr(context, 'Revisar minhas preferências'),
            kind: StickerButtonKind.secondary,
            icon: Icons.tune,
            semanticHint: tr(
              context,
              'Abre as preferências. Nada muda sem sua escolha.',
            ),
            onPressed: () => Navigator.of(context).push(
              acessaRoute(const PreferencesScreen(continuarParaDestino: false)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rota mais usada x rota adaptada (pedido do mentor): mostra, em texto,
/// o que a rota adaptada evita, o que usa no lugar e quanto a mais se
/// percorre. Só aparece quando o caminho muda de fato.
class _ComparacaoCard extends StatelessWidget {
  const _ComparacaoCard({required this.comparacao});
  final ComparacaoViagem comparacao;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final cmp = comparacao;
    final principal = cmp.principal;
    final adaptada = cmp.adaptada;

    String lista(List<String> l) => l.map((x) => tr(context, x)).join(', ');
    String troca(Viagem v) {
      final meios = meiosDeTrocaDePiso(v);
      return meios.isEmpty
          ? tr(context, 'Sem troca de piso')
          : '${tr(context, 'Troca de piso:')} ${lista(meios)}';
    }

    final evita = lista(cmp.nomesEvitados);
    final usa = lista(cmp.nomesSubstitutos);
    final temAcrescimo = cmp.extraM > 0 || cmp.extraMin > 0;
    final maior = principal.distanciaM > adaptada.distanciaM
        ? principal.distanciaM
        : adaptada.distanciaM;

    // Frase completa para o leitor de tela (nada só por cor ou ícone).
    final frase = [
      '${tr(context, 'Rota adaptada para você')}.',
      tr(
        context,
        'Rota mais usada: ${principal.distanciaM} metros, '
        'cerca de ${principal.minutos} minutos.',
      ),
      '${troca(principal)}.',
      tr(
        context,
        'Para você: ${adaptada.distanciaM} metros, '
        'cerca de ${adaptada.minutos} minutos.',
      ),
      '${troca(adaptada)}.',
      if (evita.isNotEmpty) '${tr(context, 'Evita:')} $evita.',
      if (usa.isNotEmpty) '${tr(context, 'Usa:')} $usa.',
      if (temAcrescimo)
        tr(context, '${cmp.extraM} metros e ${cmp.extraMin} min a mais.'),
    ].join(' ');

    Widget item(IconData icone, String rotulo, String valor) => Padding(
      padding: const EdgeInsets.only(top: AcessaSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: c.ink),
          const SizedBox(width: AcessaSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$rotulo ',
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: valor, style: text.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: frase,
      excludeSemantics: true,
      child: StickerCard(
        color: c.surface,
        borderColor: t.highContrast ? c.ink : c.help,
        borderWidth: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: c.ink, size: 28),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Text(
                    tr(context, 'Rota adaptada para você'),
                    style: text.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AcessaSpacing.sm),
            _LinhaComparacao(
              rotulo: tr(context, 'Rota mais usada'),
              viagem: principal,
              troca: troca(principal),
              fracao: principal.distanciaM / maior,
              cor: c.inkMuted,
              destaque: false,
            ),
            const SizedBox(height: AcessaSpacing.sm),
            _LinhaComparacao(
              rotulo: tr(context, 'Para você'),
              viagem: adaptada,
              troca: troca(adaptada),
              fracao: adaptada.distanciaM / maior,
              cor: t.highContrast ? c.ink : c.help,
              destaque: true,
            ),
            const SizedBox(height: AcessaSpacing.sm),
            if (evita.isNotEmpty)
              item(Icons.do_not_step, tr(context, 'Evita:'), evita),
            if (usa.isNotEmpty)
              item(Icons.check_circle_outline, tr(context, 'Usa:'), usa),
            if (temAcrescimo) ...[
              const SizedBox(height: AcessaSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.marker,
                    borderRadius: BorderRadius.circular(AcessaRadius.pill),
                    border: Border.all(color: c.ink, width: 2),
                  ),
                  child: Text(
                    '${tr(context, 'Desvio:')} '
                    '+${cmp.extraM} m · +${cmp.extraMin} min',
                    style: text.titleMedium?.copyWith(color: c.onMarker),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uma das rotas comparadas: rótulo, metros, minutos, como troca de piso e
/// uma barra proporcional à distância (cresce ao aparecer; sem animação
/// com movimento reduzido).
class _LinhaComparacao extends StatelessWidget {
  const _LinhaComparacao({
    required this.rotulo,
    required this.viagem,
    required this.troca,
    required this.fracao,
    required this.cor,
    required this.destaque,
  });

  final String rotulo;
  final Viagem viagem;
  final String troca;
  final double fracao;
  final Color cor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AcessaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              rotulo,
              style: text.titleMedium?.copyWith(
                color: destaque ? c.ink : c.inkMuted,
              ),
            ),
            Text(
              '${viagem.distanciaM} m · ${viagem.minutos} min',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Text(troca, style: text.bodyMedium?.copyWith(color: c.inkMuted)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: motion.enabled ? 0 : 1, end: 1),
          duration: motion.d(Motion.slow),
          curve: Motion.enter,
          builder: (context, v, _) => Container(
            height: 12,
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(AcessaRadius.pill),
              border: Border.all(color: c.border.withValues(alpha: .5)),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (fracao * v).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: destaque ? cor : cor.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(AcessaRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simulação de elevador em manutenção (RN04, RF48). Identificada como
/// simulação; o estado fica só na tela de rota.
class _SimulacaoManutencao extends StatelessWidget {
  const _SimulacaoManutencao({required this.ativa, required this.onChanged});
  final bool ativa;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreferenceToggle(
          icon: Icons.construction,
          title: tr(context, 'Simular elevador em manutenção'),
          description: tr(
            context,
            'Simulação para demonstração: recalcula a rota como se o '
            'elevador parasse. Nada muda no shopping.',
          ),
          value: ativa,
          accent: c.simulation,
          onChanged: onChanged,
        ),
        Semantics(
          liveRegion: true,
          child: ativa
              ? Padding(
                  padding: const EdgeInsets.only(top: AcessaSpacing.sm),
                  child: SimulationNotice(
                    text: tr(
                      context,
                      'Simulação: elevador em manutenção. '
                      'Desligue a simulação para voltar à rota pelo elevador.',
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Frase curta falada ao abrir a rota (em português; a voz traduz).
String resumoFalado(Viagem viagem, String destino) {
  if (viagem.totalEtapas == 0) return 'Você já está aqui.';
  return 'Rota até $destino: ${viagem.distanciaM} metros, '
      'cerca de ${viagem.minutos} minutos a pé.';
}

/// "Alertas da comunidade no caminho": avisos nos trechos que a rota usa
/// (quando não há desvio razoável). Tocar abre os detalhes.
class _AlertasNoCaminhoCard extends StatelessWidget {
  const _AlertasNoCaminhoCard({required this.alertas, required this.dados});

  final List<AlertaNoCaminho> alertas;
  final ShoppingData dados;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final pontos = {for (final p in dados.pontos) p.id: p};
    return Semantics(
      liveRegion: true,
      container: true,
      child: StickerCard(
        color: c.surface,
        borderColor: t.highContrast ? c.ink : c.simulation,
        borderWidth: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                tr(context, 'Alertas da comunidade no caminho'),
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: AcessaSpacing.xs),
            Text(
              tr(
                context,
                'Relatos de visitantes, não verificados. A rota passa por estes '
                'trechos; vá com atenção.',
              ),
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            for (final a in alertas)
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AcessaSpacing.minTouch + 8,
                  textColor: c.ink,
                  leading: MarcadorAlerta(tipo: a.ocorrencia.tipo, tamanho: 32),
                  title: Text(tr(context, a.ocorrencia.tipo.rotulo)),
                  subtitle: Text(
                    tr(
                      context,
                      'Perto de: ${nomeDoLocal(a.ocorrencia, pontos) ?? '—'}',
                    ),
                    style: TextStyle(color: c.inkMuted),
                  ),
                  trailing: Icon(Icons.chevron_right, color: c.inkMuted),
                  onTap: () =>
                      mostrarDetalhesAlerta(context, a.ocorrencia.id, dados),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Desviamos de: …": alertas que mudaram o caminho.
class _DesviosCard extends StatelessWidget {
  const _DesviosCard({required this.evitados, required this.dados});

  final List<Ocorrencia> evitados;
  final ShoppingData dados;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final pontos = {for (final p in dados.pontos) p.id: p};
    final itens = [
      for (final o in evitados) tr(context, fraseDoAlerta(o, pontos)),
    ];
    return Semantics(
      liveRegion: true,
      container: true,
      child: StickerCard(
        color: c.surface,
        borderColor: t.highContrast ? c.ink : c.help,
        borderWidth: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: c.ink, size: 26),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Text(
                    tr(context, 'Desviamos de:'),
                    style: text.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AcessaSpacing.xs),
            for (final (i, o) in evitados.indexed)
              Padding(
                padding: const EdgeInsets.only(top: AcessaSpacing.xs),
                child: Row(
                  children: [
                    MarcadorAlerta(tipo: o.tipo, tamanho: 28),
                    const SizedBox(width: AcessaSpacing.sm),
                    Expanded(child: Text(itens[i], style: text.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: AcessaSpacing.xs),
            Text(
              tr(context, 'Relato da comunidade, não verificado'),
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
