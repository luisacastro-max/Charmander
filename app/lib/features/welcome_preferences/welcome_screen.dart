import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/living_map.dart';
import '../../core/widgets/marker_highlight.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import 'next_step_screen.dart';
import 'preferences_screen.dart';

/// T01 — Boas-vindas (RF01). Seleção de idioma (RF02) fica na T02 nesta etapa.
///
/// Roteiro da abertura (movimento reduzido mostra tudo pronto):
/// 1. "+" do logo gira e encaixa.
/// 2. Mapa vivo conta o problema: escada bloqueia, elevador resolve.
/// 3. Título entra linha a linha; o marca-texto atravessa "conecta".
/// 4. Os três pilares entram em leque, como cartas.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;

    final pillars = [
      (
        Icons.forum_outlined,
        'Comunicação Universal',
        'Texto, voz, cartões e frases em 3 idiomas.',
        c.communication,
      ),
      (
        Icons.explore_outlined,
        'Navegação Viva',
        'Rotas que respeitam o seu jeito de se locomover.',
        c.navigation,
      ),
      (
        Icons.volunteer_activism_outlined,
        'Ajuda+',
        'Peça apoio só quando quiser, do seu jeito.',
        c.help,
      ),
    ];

    const titleDelay = Duration(milliseconds: 500);
    const pillarsDelay = Duration(milliseconds: 1100);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AcessaSpacing.lg,
            AcessaSpacing.lg,
            AcessaSpacing.lg,
            AcessaSpacing.xl,
          ),
          children: [
            const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
            const SizedBox(height: AcessaSpacing.md),
            const Entrance(index: 0, child: LivingMap()),
            const SizedBox(height: AcessaSpacing.lg),
            Semantics(
              header: true,
              label: 'Acessibilidade que conecta pessoas.',
              excludeSemantics: true,
              // Em telas estreitas (ex.: 360 dp) o título encolhe por inteiro
              // em vez de quebrar "Acessibilidade" no meio da palavra.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Entrance(
                      index: 0,
                      delay: titleDelay,
                      child: Text('Acessibilidade', style: text.displayLarge),
                    ),
                    Entrance(
                      index: 2,
                      delay: titleDelay,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('que ', style: text.displayLarge),
                          MarkerHighlight(
                            text: 'conecta',
                            style: text.displayLarge,
                            delay: const Duration(milliseconds: 900),
                          ),
                        ],
                      ),
                    ),
                    Entrance(
                      index: 4,
                      delay: titleDelay,
                      child: Text('pessoas.', style: text.displayLarge),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: 6,
              delay: titleDelay,
              child: Text(
                'Comunique-se do seu jeito, encontre caminhos que fazem '
                'sentido para você e peça apoio quando quiser. '
                'Sem cadastro e sem precisar explicar nada.',
                style: text.bodyLarge?.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(height: AcessaSpacing.lg),
            for (final (n, p) in pillars.indexed) ...[
              Entrance(
                index: n * 2,
                delay: pillarsDelay,
                style: EntranceStyle.fan,
                child: _PillarCard(
                  icon: p.$1,
                  title: p.$2,
                  body: p.$3,
                  color: p.$4,
                ),
              ),
              const SizedBox(height: AcessaSpacing.md),
            ],
            const SizedBox(height: AcessaSpacing.sm),
            Entrance(
              index: 8,
              delay: pillarsDelay,
              child: StickerButton(
                label: 'Começar',
                icon: Icons.arrow_forward,
                semanticHint: 'Abre as preferências de acessibilidade',
                onPressed: () =>
                    Navigator.of(context)
                        .push(acessaRoute(const PreferencesScreen())),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: 9,
              delay: pillarsDelay,
              child: StickerButton(
                label: 'Configurar depois',
                kind: StickerButtonKind.secondary,
                onPressed: () =>
                    Navigator.of(context)
                        .push(acessaRoute(const NextStepScreen())),
              ),
            ),
            const SizedBox(height: AcessaSpacing.lg),
            Entrance(
              index: 10,
              delay: pillarsDelay,
              child: const SimulationNotice(
                text:
                    'Protótipo de demonstração: shopping, beacons e '
                    'atendimentos são simulados, com dados fictícios.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final fg = t.highContrast ? c.ink : c.onAccent;
    return MergeSemantics(
      child: StickerCard(
        color: t.highContrast ? c.surface : color,
        borderColor: t.highContrast ? c.ink : c.shadow,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: t.highContrast ? c.surface : c.onAccent,
                shape: BoxShape.circle,
                border: Border.all(color: fg, width: 2),
              ),
              child: Icon(
                icon,
                color: t.highContrast ? c.ink : color,
                size: 28,
              ),
            ),
            const SizedBox(width: AcessaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleLarge?.copyWith(fontSize: 20, color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: text.bodyMedium?.copyWith(color: fg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
