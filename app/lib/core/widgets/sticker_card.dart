import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

/// Cartão "adesivo" com borda forte e sombra deslocada.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AcessaSpacing.md),
    this.borderColor,
    this.borderWidth = AcessaSticker.borderWidth,
    this.shadow = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(AcessaRadius.card),
        border: Border.all(color: borderColor ?? c.border, width: borderWidth),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: c.shadow,
                  offset: AcessaSticker.shadowOffset,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Selo que identifica conteúdo simulado (RNF10).
class SimulationNotice extends StatelessWidget {
  const SimulationNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AcessaSpacing.md,
        vertical: AcessaSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AcessaRadius.button),
        border: Border.all(color: c.simulation, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: c.simulation, size: 20),
          const SizedBox(width: AcessaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
