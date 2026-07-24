import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// Mise en avant contextuelle d'une fonctionnalité au premier lancement
/// — CDC_DESIGN §5.3.7. Aucun coachmark/spotlight n'existait dans le
/// projet avant ce ticket (`onboarding.dart` est un carrousel classique,
/// sans rapport).
class YkOnboardingSpot {
  YkOnboardingSpot._();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    void dismiss() {
      entry.remove();
      onDismiss?.call();
    }

    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: dismiss,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          Positioned(
            left: position.dx - 8,
            top: position.dy - 8,
            child: IgnorePointer(
              child: Container(
                width: size.width + 16,
                height: size.height + 16,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(YkRadius.md),
                ),
              ),
            ),
          ),
          Positioned(
            left: YkSpacing.md,
            right: YkSpacing.md,
            top: position.dy + size.height + YkSpacing.md,
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: EdgeInsets.all(YkSpacing.md),
                  decoration: BoxDecoration(
                    color: YkColors.surface(ctx),
                    borderRadius: BorderRadius.circular(YkRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: YkTypography.h4(ctx).copyWith(color: YkColors.textPrimary(ctx)),
                      ),
                      SizedBox(height: YkSpacing.xs),
                      Text(
                        message,
                        style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textSecondary(ctx)),
                      ),
                      SizedBox(height: YkSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: YkButton(label: 'Compris', size: YkButtonSize.sm, onPressed: dismiss),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
  }
}
