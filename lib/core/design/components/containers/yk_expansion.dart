import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Panneau dépliable — CDC_DESIGN §5.3.3 (modules d'un cours, FAQ).
/// Construit sur `ExpansionTile` (Material natif — anime déjà la
/// rotation de l'icône et l'apparition du contenu), tokenisé.
class YkExpansion extends StatelessWidget {
  const YkExpansion({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)))
            : null,
        initiallyExpanded: initiallyExpanded,
        iconColor: YkColors.accent(context),
        collapsedIconColor: YkColors.textSecondary(context),
        backgroundColor: YkColors.surface(context),
        collapsedBackgroundColor: YkColors.surface(context),
        childrenPadding: EdgeInsets.fromLTRB(YkSpacing.md, 0, YkSpacing.md, YkSpacing.sm),
        children: [child],
      ),
    );
  }
}
