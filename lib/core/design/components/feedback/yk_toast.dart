import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Notification transitoire en haut d'écran — CDC_DESIGN §5.3.6, pour
/// web/desktop (contrairement à `YkSnack`, ancré en bas).
class YkToast {
  YkToast._();

  static OverlayEntry? _current;

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    _current?.remove();
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: YkSpacing.md,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
                decoration: BoxDecoration(
                  color: YkColors.surface(ctx),
                  borderRadius: BorderRadius.circular(YkRadius.md),
                  boxShadow: YkElevation.e3,
                ),
                child: Text(
                  message,
                  style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textPrimary(ctx)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
    Future.delayed(duration, () {
      // Un toast plus récent a pu préempter celui-ci entre-temps (voir
      // `_current?.remove()` ci-dessus) : dans ce cas cette entrée est déjà
      // retirée de l'overlay, un second `remove()` lèverait une assertion.
      if (identical(_current, entry)) {
        entry.remove();
        _current = null;
      }
    });
  }
}
