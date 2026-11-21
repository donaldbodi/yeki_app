import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../tokens/tokens.dart';
import 'yk_rich_shared.dart';

/// Rendu en lecture seule d'un contenu HTML — CDC_DESIGN §5.4.2 : « un
/// seul composant de rendu pour l'apprenant, partout ». Jumeau de
/// [YkRichEditor] — même convention `yk-formula`/`yk-image` pour les
/// formules et le texte alternatif d'image.
class YkRichViewer extends StatelessWidget {
  const YkRichViewer({super.key, required this.html, this.textStyle});

  final String html;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) return const SizedBox.shrink();
    final baseStyle =
        textStyle ?? YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context));

    return HtmlWidget(
      html,
      textStyle: baseStyle,
      customWidgetBuilder: (element) {
        if (element.localName == 'span' && element.classes.contains(YkRichFormula.htmlClass)) {
          final latex = element.attributes[YkRichFormula.htmlAttribute] ?? element.text;
          return Math.tex(latex, onErrorFallback: (_) => Text(latex, style: baseStyle));
        }
        if (element.localName == 'img' && element.classes.contains(YkRichImage.htmlClass)) {
          final alt = element.attributes['alt'] ?? '';
          final src = element.attributes['src'] ?? '';
          return Semantics(
            label: alt.isEmpty ? 'Image' : alt,
            image: true,
            child: Image.network(
              src,
              errorBuilder: (context, error, stack) => Container(
                padding: EdgeInsets.all(YkSpacing.sm),
                color: YkColors.surfaceVariant(context),
                child: Icon(Icons.broken_image_outlined, color: YkColors.textSecondary(context)),
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}
