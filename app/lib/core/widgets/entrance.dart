import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';

/// Estilos de entrada disponíveis.
enum EntranceStyle {
  /// Sobe 16 px e aparece (padrão).
  rise,

  /// Entra como carta de baralho: girada, menor, e encaixa com leve "pulo".
  fan,

  /// Cresce girando (usado no "+" do logo).
  spin,
}

/// Entrada em cascata (stagger): cada item começa [Motion.stagger] × [index]
/// depois do anterior. Com movimento reduzido, aparece imediatamente.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.index,
    required this.child,
    this.style = EntranceStyle.rise,
    this.delay = Duration.zero,
  });

  final int index;
  final Widget child;
  final EntranceStyle style;
  final Duration delay;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.style == EntranceStyle.rise
        ? Motion.base
        : const Duration(milliseconds: 650),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.of(context).enabled) {
      _c.value = 1;
      return;
    }
    Future.delayed(widget.delay + Motion.stagger * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se o visitante ativar a redução de estímulos no meio da animação,
    // ela termina na hora.
    if (!Motion.of(context).enabled && _c.value < 1) _c.value = 1;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        switch (widget.style) {
          case EntranceStyle.rise:
            final e = Motion.enter.transform(v);
            return Opacity(
              opacity: e,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - e)),
                child: child,
              ),
            );
          case EntranceStyle.fan:
            final e = Curves.easeOutBack.transform(v);
            final side = widget.index.isEven ? -1.0 : 1.0;
            return Opacity(
              opacity: Curves.easeOut.transform(v),
              child: Transform.translate(
                offset: Offset(side * 40 * (1 - e), 60 * (1 - e)),
                child: Transform.rotate(
                  angle: side * .22 * (1 - e),
                  child: Transform.scale(scale: .85 + .15 * e, child: child),
                ),
              ),
            );
          case EntranceStyle.spin:
            final e = Curves.elasticOut.transform(v);
            return Transform.rotate(
              angle: -3.1416 * (1 - Curves.easeOutCubic.transform(v)),
              child: Transform.scale(scale: e, child: child),
            );
        }
      },
      child: widget.child,
    );
  }
}
