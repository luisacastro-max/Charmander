import 'package:flutter/material.dart';

import 'theme/motion.dart';

/// Transição entre telas: desliza levemente e ganha opacidade.
/// Com movimento reduzido, a troca é instantânea.
Route<T> acessaRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, _, _) => page,
    transitionDuration: Motion.base,
    reverseTransitionDuration: Motion.quick,
    transitionsBuilder: (context, animation, _, child) {
      if (!Motion.of(context).enabled) return child;
      final a = CurvedAnimation(parent: animation, curve: Motion.enter);
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      );
    },
  );
}
