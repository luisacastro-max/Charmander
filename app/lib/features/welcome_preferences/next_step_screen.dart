import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import 'preferences_scope.dart';

/// Tela provisória da Etapa 1: confirma as escolhas e indica que a Home
/// (T03) chega numa próxima etapa. Não faz parte das 13 telas.
class NextStepScreen extends StatelessWidget {
  const NextStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PreferencesScope.of(context).prefs;
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;

    final active = <String>[
      if (p.largeText) 'Texto ampliado',
      if (p.highContrast) 'Alto contraste',
      if (p.audioGuidance) 'Orientações por áudio',
      if (p.textCommunication) 'Comunicação por texto',
      if (p.quickMessages) 'Mensagens rápidas em destaque',
      if (p.avoidStairs) 'Rotas sem escadas',
      if (p.preferElevators) 'Preferência por elevadores',
      if (p.calm) 'Redução de estímulos',
      if (p.simplified) 'Navegação simplificada',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AcessaSpacing.lg),
          children: [
            Entrance(
              index: 0,
              child: Semantics(
                header: true,
                child: Text('Tudo pronto!', style: text.displayMedium),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: 1,
              child: StickerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suas escolhas', style: text.titleLarge),
                    const SizedBox(height: AcessaSpacing.sm),
                    if (active.isEmpty)
                      Text(
                        'Nenhum recurso ativo. Você pode ativar quando '
                        'quiser em Perfil.',
                        style: text.bodyLarge,
                      )
                    else
                      for (final a in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: c.primary),
                              const SizedBox(width: AcessaSpacing.sm),
                              Expanded(child: Text(a, style: text.bodyLarge)),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.lg),
            Entrance(
              index: 2,
              child: const SimulationNotice(
                text:
                    'Amostra da Etapa 1. A Home (T03) será construída na '
                    'Etapa 3. As preferências ainda não são salvas no '
                    'aparelho (Etapa 2).',
              ),
            ),
            const SizedBox(height: AcessaSpacing.lg),
            Entrance(
              index: 3,
              child: StickerButton(
                label: 'Voltar ao início',
                kind: StickerButtonKind.secondary,
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
