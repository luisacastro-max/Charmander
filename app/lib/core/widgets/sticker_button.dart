import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';

enum StickerButtonKind { primary, secondary }

/// Botão "adesivo": ao pressionar, afunda na própria sombra.
/// O retorno tátil visual é reforçado pelo texto do botão — nenhuma
/// informação depende só da animação.
class StickerButton extends StatefulWidget {
  const StickerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = StickerButtonKind.primary,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final StickerButtonKind kind;
  final String? semanticHint;

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton> {
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final primary = widget.kind == StickerButtonKind.primary;
    final bg = primary ? c.primary : c.surface;
    final fg = primary ? c.onPrimary : c.ink;
    final offset = _down ? Offset.zero : AcessaSticker.shadowOffset;

    final ativo = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: ativo,
      hint: widget.semanticHint,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onPressed?.call(),
          ),
        },
        // Desabilitado: esmaecido (o leitor de tela recebe "desativado").
        child: Opacity(
          opacity: ativo ? 1 : .45,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: motion.d(Motion.quick),
              curve: Motion.enter,
              transform: Matrix4.translationValues(
                AcessaSticker.shadowOffset.dx - offset.dx,
                AcessaSticker.shadowOffset.dy - offset.dy,
                0,
              ),
              constraints: const BoxConstraints(
                minHeight: AcessaSpacing.minTouch + 8,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AcessaSpacing.lg,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AcessaRadius.button),
                border: Border.all(
                  color: _focused
                      ? c.focus
                      : (primary ? c.onPrimary : c.border),
                  width: _focused ? 4 : AcessaSticker.borderWidth,
                ),
                boxShadow: [
                  // Botão principal ganha sombra neon rosa; o secundário, sombra escura.
                  BoxShadow(
                    color: primary ? c.marker : c.shadow,
                    offset: offset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: 24),
                    const SizedBox(width: AcessaSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
