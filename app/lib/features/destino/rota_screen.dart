import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/icones.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/rules/viagem.dart';
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

  ShoppingData get dados => widget.dados;

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
        SnackBar(content: Text('${escolhido.nome} já é a última parada.')),
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
    final resultado = dados.motor.calcularViagem(widget.origemId, [
      for (final p in _paradas) p.pontoId,
    ], criteriosDe(prefs));
    final destino = _paradas.last;

    var i = 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: 'Voltar para a busca',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AcessaSpacing.lg,
          0,
          AcessaSpacing.lg,
          AcessaSpacing.xl,
        ),
        children: [
          Entrance(
            index: i++,
            child: Text(
              'Rota até',
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
                      _aviso,
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
            ),
            ViagemImpossivel() => Entrance(
              index: i,
              child: _SemRotaCard(
                resultado: resultado.motivo,
                onRemoverParada: _paradas.length > 1
                    ? () => _remover(resultado.perna)
                    : null,
                nomeParada: _paradas[resultado.perna].nome,
              ),
            ),
          },
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
                          'Saindo de',
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
                            !varias
                                ? 'Destino'
                                : n == paradas.length - 1
                                ? 'Destino final'
                                : 'Parada ${n + 1}',
                            style: text.bodyMedium?.copyWith(color: c.inkMuted),
                          ),
                          Text(l.nome, style: text.titleMedium),
                          if (falhou == n)
                            Text(
                              'Sem caminho compatível até aqui',
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
                      'Mover ${l.nome} para antes',
                      n == 0 ? null : () => onMover(n, n - 1),
                    ),
                    botao(
                      Icons.arrow_downward,
                      'Mover ${l.nome} para depois',
                      n == paradas.length - 1 ? null : () => onMover(n, n + 1),
                    ),
                    botao(Icons.close, 'Remover ${l.nome}', () => onRemover(n)),
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
                onAdicionar == null
                    ? 'Limite de $maxParadas paradas'
                    : 'Adicionar outra parada',
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
  });

  final Viagem viagem;
  final Local destino;
  final PontoReferencia pontoDestino;
  final int primeiroIndice;
  final ShoppingData dados;

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
          child: Text('Você já está aqui.', style: text.titleLarge),
        ),
      );
    }

    final badges = <(IconData, String)>[
      if (viagem.criterios.semEscadas)
        (Icons.accessible_forward, 'Sem escadas')
      else if (viagem.usaEscada)
        (Icons.stairs_outlined, 'Tem degraus'),
      if (viagem.usaElevador) (Icons.elevator_outlined, 'Usa elevador'),
      if (viagem.criterios.caminhoTranquilo)
        (Icons.spa_outlined, 'Evita movimento'),
      if (varias) (Icons.alt_route, '${viagem.pernas.length} paradas'),
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
              text:
                  'Esta rota tem degraus. Se precisar evitar escadas, '
                  'ative "Rotas sem escadas" nas preferências.',
            ),
          ),
        ],
        const SizedBox(height: AcessaSpacing.lg),
        Entrance(
          index: i++,
          child: StickerButton(
            label: 'Iniciar navegação',
            icon: Icons.navigation_outlined,
            semanticHint: 'Abre a bússola e o mapa interativo',
            onPressed: () async {
              final nav = Navigator.of(context);
              final novoDestino = await nav.push<bool>(
                acessaRoute(NavegacaoScreen(viagem: viagem, dados: dados)),
              );
              // "Escolher novo destino" ao chegar: volta para "Para onde?".
              if (novoDestino == true) nav.pop();
            },
          ),
        ),
        const SizedBox(height: AcessaSpacing.lg),
        Entrance(
          index: i++,
          child: Semantics(
            header: true,
            child: Text('Passo a passo', style: text.titleLarge),
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
                  p == viagem.pernas.length - 1
                      ? 'Até o destino final: ${viagem.paradas[p].nome}'
                      : 'Até a parada ${p + 1}: ${viagem.paradas[p].nome}',
                  style: text.titleMedium?.copyWith(color: c.help),
                ),
              ),
            ),
          if (perna.etapas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AcessaSpacing.md),
              child: Text(
                'Você já está aqui.',
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
      label:
          '${viagem.distanciaM} metros, cerca de ${viagem.minutos} minutos. '
          'Pisos: ${viagem.pisos.join(' para ')}. ${badges.map((b) => b.$2).join('. ')}.',
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
              'cerca de ${viagem.minutos} min a pé',
              style: text.titleMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (n, p) in viagem.pisos.indexed) ...[
                  if (n > 0) Icon(Icons.arrow_forward, size: 18, color: fg),
                  Text(p, style: text.titleMedium?.copyWith(color: fg)),
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
  });
  final int numero;
  final EtapaRota etapa;
  final bool ultima;

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
                    Text(etapa.instrucao, style: text.bodyLarge),
                    Text(
                      '${etapa.para.nome} · ${exibir(etapa.para.piso)}',
                      style: text.bodyMedium?.copyWith(color: c.inkMuted),
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
          Text('Sobre o destino', style: text.titleLarge),
          const SizedBox(height: AcessaSpacing.sm),
          linha('Piso', exibir(ponto.piso)),
          linha('Horário', exibir(local.horario)),
          linha('Descrição', exibir(local.descricao)),
          linha('Recursos', exibirRecursos(local.recursos).join(', ')),
          const SizedBox(height: 4),
          Text(
            'Informações de demonstração, com dados fictícios.',
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
    this.onRemoverParada,
  });
  final SemRota resultado;
  final String nomeParada;

  /// Só existe quando há mais de uma parada.
  final VoidCallback? onRemoverParada;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
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
                      child: Text(resultado.motivo, style: text.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: AcessaSpacing.sm),
                Text(
                  resultado.existeComEscada
                      ? 'Sua preferência "Rotas sem escadas" continua ativa. '
                            'O app não muda isso sozinho.'
                      : 'Nenhum percurso cadastrado liga estes dois pontos.',
                  style: text.bodyLarge?.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.lg),
        if (onRemoverParada != null) ...[
          StickerButton(
            label: 'Remover a parada $nomeParada',
            icon: Icons.remove_circle_outline,
            onPressed: onRemoverParada,
          ),
          const SizedBox(height: AcessaSpacing.md),
        ],
        StickerButton(
          label: 'Escolher outro destino',
          icon: Icons.search,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: AcessaSpacing.md),
        StickerButton(
          label: 'Pedir ajuda (Ajuda+)',
          kind: StickerButtonKind.secondary,
          icon: Icons.volunteer_activism_outlined,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('O Ajuda+ chega numa próxima etapa (simulado).'),
            ),
          ),
        ),
        if (resultado.existeComEscada) ...[
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: 'Revisar minhas preferências',
            kind: StickerButtonKind.secondary,
            icon: Icons.tune,
            semanticHint: 'Abre as preferências. Nada muda sem sua escolha.',
            onPressed: () => Navigator.of(context).push(
              acessaRoute(const PreferencesScreen(continuarParaDestino: false)),
            ),
          ),
        ],
      ],
    );
  }
}
