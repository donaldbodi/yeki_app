import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_link.dart';

/// En-tête de section — CDC_DESIGN §5.3.3 : titre, sous-titre, action
/// « Voir tout ». Uniformise les dizaines de titres faits main du
/// projet.
class YkSection extends StatelessWidget {
  const YkSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) YkLink(label: actionLabel!, onTap: onAction!),
          ],
        ),
        SizedBox(height: YkSpacing.sm),
        child,
      ],
    );
  }
}
