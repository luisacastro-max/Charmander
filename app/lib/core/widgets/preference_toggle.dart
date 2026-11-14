import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import 'burst.dart';
import 'theme_reveal.dart';

/// Cartão de preferência: ícone, título, explicação do efeito e interruptor.
///
/// O estado é dito em texto ("Ativado"/"Desativado"), além da cor e da
/// posição do interruptor (RNF04 — não depender de um único sentido).
/// Leitores de tela recebem um único elemento com papel de interruptor.
///
/// Ao ativar, uma pequena explosão de pontos confirma a escolha.
/// Com [revealsTheme], a troca de tema se espalha em círculo a partir
/// do interruptor.
class PreferenceToggle extends StatefulWidget {
  const PreferenceToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.accent,
    this.revealsTheme = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;
  final bool revealsTheme;

  @override
  State<PreferenceToggle> createState() => _PreferenceToggleState();
}

class _PreferenceToggleState extends State<PreferenceToggle> {
  final _knobKey = GlobalKey();
  final _burstKey = GlobalKey<BurstState>();

  void _toggle() {
    final next = !widget.value;
    if (widget.revealsTheme) {
      final box = _knobKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box?.localToGlobal(box.size.center(Offset.zero));
      ThemeReveal.run(context, origin, () => widget.onChanged(next));
    } else {
      widget.onChanged(next);
    }
    if (next) _burstKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final value = widget.value;
    final accent = widget.accent ?? c.navigation;
    final activeBg = t.highContrast ? c.surface : accent;
    // Sobre as cores neon do pilar, o texto fica escuro (contraste ≥ 5,9:1).
    final fg = value && !t.highContrast ? c.onAccent : c.ink;
    final fgMuted = value && !t.highContrast ? c.onAccent : c.inkMuted;

    return Semantics(
      toggled: value,
      label: widget.title,
      hint: widget.description,
      excludeSemantics: true,
      onTap: _toggle,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AcessaRadius.card),
          onTap: _toggle,
          child: AnimatedContainer(
            duration: motion.d(Motion.base),
            curve: Motion.enter,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(AcessaSpacing.md),
            decoration: BoxDecoration(
              color: value ? activeBg : c.surface,
              borderRadius: BorderRadius.circular(AcessaRadius.card),
              border: Border.all(
                color: value
                    ? (t.highContrast ? c.ink : c.shadow)
                    : c.border.withValues(alpha: t.highContrast ? .7 : .35),
                width: value ? 2.5 : 1.5,
              ),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: t.highContrast ? c.ink : c.shadow,
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: value ? 1.12 : 1,
                  duration: motion.d(Motion.base),
                  curve: Motion.pop,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: value ? c.onAccent : c.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value ? c.onAccent : c.inkMuted,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: value ? (t.highContrast ? c.ink : accent) : c.ink,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: AcessaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: text.titleMedium?.copyWith(color: fg),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.description,
                        style: text.bodyMedium?.copyWith(color: fgMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(context, value ? 'Ativado' : 'Desativado'),
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AcessaSpacing.sm),
                Burst(
                  key: _burstKey,
                  color: t.highContrast ? c.primary : c.onAccent,
                  child: _Knob(key: _knobKey, value: value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final on = t.highContrast ? c.primary : c.onAccent;
    return AnimatedContainer(
      duration: motion.d(Motion.base),
      curve: Motion.enter,
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? on : c.background,
        borderRadius: BorderRadius.circular(AcessaRadius.pill),
        border: Border.all(color: value ? on : c.inkMuted, width: 2),
      ),
      child: AnimatedAlign(
        duration: motion.d(Motion.base),
        curve: Motion.pop,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? (t.highContrast ? c.onPrimary : c.ink) : c.inkMuted,
            shape: BoxShape.circle,
          ),
          child: value
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: t.highContrast ? c.primary : c.onAccent,
                )
              : null,
        ),
      ),
    );
  }
}
