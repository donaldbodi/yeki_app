import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Popover ancré à un widget déclencheur — CDC_DESIGN §5.3.7. Contenu
/// libre (contrairement à [YkMenu], limité à une liste d'items).
class YkPopover {
  YkPopover._();

  static OverlayEntry? _current;

  static void show({required BuildContext context, required WidgetBuilder contentBuilder}) {
    hide();
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: hide,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            left: offset.dx,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: EdgeInsets.all(YkSpacing.sm),
                decoration: BoxDecoration(
                  color: YkColors.surface(ctx),
                  borderRadius: BorderRadius.circular(YkRadius.md),
                  boxShadow: YkElevation.e2,
                ),
                child: contentBuilder(ctx),
              ),
            ),
          ),
        ],
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _current?.remove();
    _current = null;
  }
}
