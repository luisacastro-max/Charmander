import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/preference_toggle.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import 'next_step_screen.dart';
import 'preferences.dart';
import 'preferences_scope.dart';

/// T02 — Preferências de acessibilidade (RF03, RF04, RF14, RN01, RN02).
///
/// Organizada por necessidade, não por diagnóstico. Texto ampliado,
/// alto contraste e redução de estímulos mudam a tela na hora.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = PreferencesScope.of(context);
    final p = ctrl.prefs;
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;

    void set(Preferences Function(Preferences) f) => ctrl.update(f);

    var i = 0;
    Widget group(String title, Color accent, List<Widget> items) {
      return Entrance(
        index: i++,
        child: Padding(
          padding: const EdgeInsets.only(top: AcessaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: text.titleLarge),
              ),
              const SizedBox(height: AcessaSpacing.sm),
              for (final it in items) ...[
                it,
                const SizedBox(height: AcessaSpacing.sm),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AcessaSpacing.lg,
            0,
            AcessaSpacing.lg,
            AcessaSpacing.xl,
          ),
          children: [
            Entrance(
              index: i++,
              child: Semantics(
                header: true,
                child: Text('Minha acessibilidade', style: text.displayMedium),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Entrance(
              index: i++,
              child: Text(
                'Combine o que ajuda você. Não é preciso declarar nenhuma '
                'deficiência. Dá para mudar quando quiser.',
                style: text.bodyLarge?.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: _ActiveCounter(count: p.activeCount),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: _LivePreview(prefs: p),
            ),
            group('Ver e ouvir', c.navigation, [
              PreferenceToggle(
                icon: Icons.text_increase,
                title: 'Texto ampliado',
                description: 'Letras maiores em todo o app.',
                value: p.largeText,
                accent: c.navigation,
                onChanged: (v) => set((p) => p.copyWith(largeText: v)),
              ),
              PreferenceToggle(
                icon: Icons.contrast,
                title: 'Alto contraste',
                description: 'Fundo preto, texto branco e destaques amarelos.',
                value: p.highContrast,
                accent: c.navigation,
                revealsTheme: true,
                onChanged: (v) => set((p) => p.copyWith(highContrast: v)),
              ),
              PreferenceToggle(
                icon: Icons.volume_up_outlined,
                title: 'Orientações por áudio',
                description: 'Instruções faladas durante a navegação.',
                value: p.audioGuidance,
                accent: c.navigation,
                onChanged: (v) => set((p) => p.copyWith(audioGuidance: v)),
              ),
            ]),
            group('Comunicar', c.communication, [
              PreferenceToggle(
                icon: Icons.chat_outlined,
                title: 'Comunicação por texto',
                description: 'A Central abre direto na conversa escrita.',
                value: p.textCommunication,
                accent: c.communication,
                onChanged: (v) => set((p) => p.copyWith(textCommunication: v)),
              ),
              PreferenceToggle(
                icon: Icons.bolt_outlined,
                title: 'Mensagens rápidas em destaque',
                description: 'Frases prontas aparecem primeiro.',
                value: p.quickMessages,
                accent: c.communication,
                onChanged: (v) => set((p) => p.copyWith(quickMessages: v)),
              ),
            ]),
            group('Locomover-se', c.help, [
              PreferenceToggle(
                icon: Icons.accessible_forward,
                title: 'Rotas sem escadas',
                description: 'Nenhuma rota passará por degraus.',
                value: p.avoidStairs,
                accent: c.help,
                onChanged: (v) => set((p) => p.copyWith(avoidStairs: v)),
              ),
              PreferenceToggle(
                icon: Icons.elevator_outlined,
                title: 'Preferência por elevadores',
                description: 'Elevadores têm prioridade nas trocas de piso.',
                value: p.preferElevators,
                accent: c.help,
                onChanged: (v) => set((p) => p.copyWith(preferElevators: v)),
              ),
            ]),
            group('Conforto e clareza', c.marker, [
              PreferenceToggle(
                icon: Icons.spa_outlined,
                title: 'Redução de estímulos',
                description: 'Sem animações e com cores mais suaves.',
                value: p.calm,
                accent: c.marker,
                onChanged: (v) => set((p) => p.copyWith(calm: v)),
              ),
              PreferenceToggle(
                icon: Icons.view_agenda_outlined,
                title: 'Navegação simplificada',
                description: 'Menos informações em cada tela.',
                value: p.simplified,
                accent: c.marker,
                onChanged: (v) => set((p) => p.copyWith(simplified: v)),
              ),
            ]),
            Entrance(
              index: i++,
              child: Padding(
                padding: const EdgeInsets.only(top: AcessaSpacing.lg),
                child: _LanguagePicker(
                  value: p.language,
                  onChanged: (l) => set((p) => p.copyWith(language: l)),
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.xl),
            Entrance(
              index: i++,
              child: StickerButton(
                label: 'Continuar',
                icon: Icons.arrow_forward,
                onPressed: () =>
                    Navigator.of(context)
                        .push(acessaRoute(const NextStepScreen())),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: StickerButton(
                label: 'Desativar todas',
                kind: StickerButtonKind.secondary,
                icon: Icons.restart_alt,
                onPressed: p.activeCount == 0 ? null : ctrl.reset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contador vivo: o número "salta" quando muda e é anunciado por leitores
/// de tela (liveRegion).
class _ActiveCounter extends StatelessWidget {
  const _ActiveCounter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final label = count == 0
        ? 'Nenhum recurso ativo'
        : count == 1
        ? '1 recurso ativo'
        : '$count recursos ativos';

    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AcessaSpacing.md,
            vertical: AcessaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: c.marker,
            borderRadius: BorderRadius.circular(AcessaRadius.pill),
            border: Border.all(color: c.ink, width: 2),
          ),
          child: AnimatedSwitcher(
            duration: motion.d(Motion.base),
            transitionBuilder: (child, a) => ScaleTransition(
              scale: CurvedAnimation(parent: a, curve: Motion.pop),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Text(
              label,
              key: ValueKey(count),
              style: text.titleMedium?.copyWith(color: c.onMarker),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    const options = [
      (AppLanguage.pt, 'Português'),
      (AppLanguage.en, 'English'),
      (AppLanguage.es, 'Español'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Idioma', style: text.titleLarge)),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          'Define a voz e as frases traduzidas. Nesta versão, os textos '
          'do app seguem em português.',
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          children: [
            for (final o in options)
              Semantics(
                selected: value == o.$1,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: ChoiceChip(
                  label: Text(o.$2),
                  selected: value == o.$1,
                  showCheckmark: true,
                  checkmarkColor: c.onPrimary,
                  labelStyle: text.labelLarge?.copyWith(
                    color: value == o.$1 ? c.onPrimary : c.ink,
                  ),
                  selectedColor: c.primary,
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.ink, width: 2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AcessaSpacing.sm,
                    vertical: AcessaSpacing.sm,
                  ),
                  onSelected: (_) => onChanged(o.$1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Prévia ao vivo: mostra, em miniatura, como o app fica com as escolhas
/// atuais. Muda na hora a cada interruptor (com transição suave).
class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.prefs});
  final Preferences prefs;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final p = prefs;

    final chips = <(IconData, String, Color)>[
      if (p.avoidStairs)
        (Icons.accessible_forward, 'Sem escadas', c.help)
      else
        (Icons.route_outlined, 'Rota mais curta', c.navigation),
      if (p.preferElevators) (Icons.elevator_outlined, 'Elevador', c.help),
      if (p.audioGuidance)
        (Icons.volume_up_outlined, 'Áudio ligado', c.navigation),
      if (p.quickMessages)
        (Icons.bolt_outlined, 'Frases rápidas', c.communication),
      if (p.calm) (Icons.spa_outlined, 'Sem animações', c.marker),
    ];

    final summary = [
      'Prévia ao vivo.',
      p.textCommunication
          ? 'A Central abre na conversa escrita.'
          : 'A Central abre nos cartões de comunicação.',
      ...chips.map((e) => '${e.$2}.'),
    ].join(' ');

    return Semantics(
      container: true,
      liveRegion: false,
      label: summary,
      excludeSemantics: true,
      child: StickerCard(
        color: c.surface,
        borderColor: c.border.withValues(alpha: t.highContrast ? 1 : .3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: c.focus, size: 20),
                const SizedBox(width: AcessaSpacing.sm),
                Text(
                  'Prévia ao vivo',
                  style: text.titleMedium?.copyWith(color: c.focus),
                ),
              ],
            ),
            const SizedBox(height: AcessaSpacing.sm),
            AnimatedSwitcher(
              duration: motion.d(Motion.base),
              switchInCurve: Motion.enter,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .08),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: Align(
                key: ValueKey(p.textCommunication),
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AcessaSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.highContrast ? c.surface : c.communication,
                    border: t.highContrast
                        ? Border.all(color: c.ink, width: 2)
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.textCommunication
                            ? Icons.keyboard_outlined
                            : Icons.style_outlined,
                        size: 20,
                        color: t.highContrast ? c.ink : c.onAccent,
                      ),
                      const SizedBox(width: AcessaSpacing.sm),
                      Flexible(
                        child: Text(
                          'Onde fica o banheiro?',
                          style: text.bodyLarge?.copyWith(
                            color: t.highContrast ? c.ink : c.onAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            AnimatedSize(
              duration: motion.d(Motion.base),
              curve: Motion.enter,
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: AcessaSpacing.sm,
                runSpacing: AcessaSpacing.sm,
                children: [
                  for (final ch in chips)
                    Entrance(
                      key: ValueKey(ch.$2),
                      index: 0,
                      style: EntranceStyle.spin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: t.highContrast ? c.surface : ch.$3,
                          borderRadius: BorderRadius.circular(
                            AcessaRadius.pill,
                          ),
                          border: t.highContrast
                              ? Border.all(color: c.ink, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ch.$1,
                              size: 18,
                              color: t.highContrast ? c.ink : c.onAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ch.$2,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: t.highContrast ? c.ink : c.onAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
