import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Texte cliquable — CDC_DESIGN §5.3.1 : souligné au survol/focus,
/// ouverture externe signalée par icône.
class YkLink extends StatefulWidget {
  const YkLink({super.key, required this.label, required this.onTap, this.external = false});

  final String label;
  final VoidCallback onTap;
  final bool external;

  @override
  State<YkLink> createState() => _YkLinkState();
}

class _YkLinkState extends State<YkLink> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final underline = _hovering || _focused;
    final color = YkColors.accent(context);

    return Semantics(
      link: true,
      label: widget.external ? '${widget.label} (ouvre un lien externe)' : widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: YkTypography.bodyMd(context).copyWith(
                    color: color,
                    decoration: underline ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: color,
                  ),
                ),
                if (widget.external) ...[
                  SizedBox(width: YkSpacing.xxs),
                  Icon(Icons.open_in_new, size: 14, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
