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
import '../welcome_preferences/preferences_scope.dart';
import '../welcome_preferences/preferences_screen.dart';
import 'destino_screen.dart';

/// Resumo da rota (T05 simplificada): distância, tempo, pisos, critérios
/// considerados e as etapas em texto (RF13, RF15, RF18). A rota é
/// recalculada quando as preferências mudam (RF45).
class RotaScreen extends StatelessWidget {
  const RotaScreen({
    super.key,
    required this.origemId,
    required this.destino,
    required this.dados,
  });

  final String origemId;
  final Local destino;
  final ShoppingData dados;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final prefs = PreferencesScope.of(context).prefs;
    final resultado = dados.motor.calcular(
      origemId,
      destino.pontoId,
      criteriosDe(prefs),
    );
    final pontoDestino = dados.ponto(destino.pontoId);

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
          const SizedBox(height: AcessaSpacing.xs),
          Entrance(
            index: i++,
            child: Text(
              'Saindo de ${dados.ponto(origemId).nome}',
              style: text.bodyLarge?.copyWith(color: c.inkMuted),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          switch (resultado) {
            Rota() => _ComRota(
              rota: resultado,
              destino: destino,
              pontoDestino: pontoDestino,
              primeiroIndice: i,
            ),
            SemRota() => Entrance(
              index: i,
              child: _SemRotaCard(resultado: resultado),
            ),
          },
        ],
      ),
    );
  }
}

class _ComRota extends StatelessWidget {
  const _ComRota({
    required this.rota,
    required this.destino,
    required this.pontoDestino,
    required this.primeiroIndice,
  });

  final Rota rota;
  final Local destino;
  final PontoReferencia pontoDestino;
  final int primeiroIndice;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    var i = primeiroIndice;

    if (rota.etapas.isEmpty) {
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
      if (rota.criterios.semEscadas)
        (Icons.accessible_forward, 'Sem escadas')
      else if (rota.usaEscada)
        (Icons.stairs_outlined, 'Tem degraus'),
      if (rota.usaElevador) (Icons.elevator_outlined, 'Usa elevador'),
      if (rota.criterios.caminhoTranquilo)
        (Icons.spa_outlined, 'Evita movimento'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          index: i++,
          child: _ResumoNeon(rota: rota, badges: badges),
        ),
        if (!rota.criterios.semEscadas && rota.usaEscada) ...[
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
          child: Semantics(
            header: true,
            child: Text('Passo a passo', style: text.titleLarge),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        for (final (n, e) in rota.etapas.indexed)
          Entrance(
            index: (i + n).clamp(0, 14),
            child: _Etapa(
              numero: n + 1,
              etapa: e,
              ultima: n == rota.etapas.length - 1,
            ),
          ),
        const SizedBox(height: AcessaSpacing.lg),
        Entrance(
          index: i++,
          child: StickerButton(
            label: 'Iniciar navegação',
            icon: Icons.navigation_outlined,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A navegação com bússola e mapa chega na Etapa 3b.',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.lg),
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
  const _ResumoNeon({required this.rota, required this.badges});
  final Rota rota;
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
          '${rota.distanciaM} metros, cerca de ${rota.minutos} minutos. '
          'Pisos: ${rota.pisos.join(' para ')}. ${badges.map((b) => b.$2).join('. ')}.',
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
                      text: '${(rota.distanciaM * v).round()}',
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
              'cerca de ${rota.minutos} min a pé',
              style: text.titleMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (n, p) in rota.pisos.indexed) ...[
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
  const _SemRotaCard({required this.resultado});
  final SemRota resultado;

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
