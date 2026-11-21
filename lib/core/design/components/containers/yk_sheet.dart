import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

/// Feuille modale adaptative — CDC_DESIGN §5.3.3. Remplace tous les
/// `showModalBottomSheet` faits main : plein écran en `compact` (via
/// `YkBreakpoints`), dialog centré au-delà.
class YkSheet {
  YkSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder bodyBuilder,
    List<Widget> Function(BuildContext context)? actionsBuilder,
  }) {
    final compact = YkBreakpoints.of(context) == YkBreakpoint.compact;
    if (compact) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _YkSheetContent(
          title: title,
          bodyBuilder: bodyBuilder,
          actionsBuilder: actionsBuilder,
          fullScreen: true,
        ),
      );
    }
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: _YkSheetContent(
            title: title,
            bodyBuilder: bodyBuilder,
            actionsBuilder: actionsBuilder,
            fullScreen: false,
          ),
        ),
      ),
    );
  }
}

class _YkSheetContent extends StatelessWidget {
  const _YkSheetContent({
    required this.title,
    required this.bodyBuilder,
    required this.actionsBuilder,
    required this.fullScreen,
  });

  final String title;
  final WidgetBuilder bodyBuilder;
  final List<Widget> Function(BuildContext context)? actionsBuilder;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final actions = actionsBuilder?.call(context);
    return Container(
      height: fullScreen ? MediaQuery.sizeOf(context).height * 0.9 : null,
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        borderRadius: fullScreen
            ? BorderRadius.vertical(top: Radius.circular(YkRadius.xl))
            : BorderRadius.circular(YkRadius.xl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (fullScreen)
              Padding(
                padding: EdgeInsets.only(top: YkSpacing.sm),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YkColors.border(context),
                    borderRadius: BorderRadius.circular(YkRadius.full),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.sm, YkSpacing.sm, YkSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                  ),
                  YkIconButton(
                    icon: Icons.close,
                    label: 'Fermer',
                    variant: YkIconButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: YkColors.border(context)),
            if (fullScreen)
              Expanded(child: SingleChildScrollView(child: bodyBuilder(context)))
            else
              Flexible(child: SingleChildScrollView(child: bodyBuilder(context))),
            if (actions != null && actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(YkSpacing.md),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}
