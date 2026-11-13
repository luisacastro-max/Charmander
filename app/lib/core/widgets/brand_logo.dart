import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'entrance.dart';

/// Logotipo "Acessa+" com o "+" que gira e encaixa na abertura.
/// Usa Hero para "voar" entre telas.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 26, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontSize: size, color: c.ink, height: 1);
    final plus = Text('+', style: style?.copyWith(color: c.marker));

    return Hero(
      tag: 'acessa-logo',
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          header: true,
          label: 'Acessa mais',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Acessa', style: style),
              animate
                  ? Entrance(
                      index: 0,
                      style: EntranceStyle.spin,
                      delay: const Duration(milliseconds: 200),
                      child: plus,
                    )
                  : plus,
            ],
          ),
        ),
      ),
    );
  }
}
