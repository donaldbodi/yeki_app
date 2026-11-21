import 'dart:convert';

/// Conventions partagées entre `YkRichEditor` et `YkRichViewer` —
/// CDC_DESIGN §5.4.
///
/// Le backend stocke du HTML assaini (pas du Delta Quill, voir
/// `yk_rich_html_converter.dart`). Les formules mathématiques n'ont pas
/// d'équivalent HTML standard : elles sont encodées dans une balise
/// `<span>` reconnaissable par sa classe, avec le LaTeX en attribut — la
/// MÊME convention est utilisée à l'écriture (éditeur → HTML) et à la
/// lecture (HTML → rendu), pour que ce que l'un produit, l'autre le
/// comprenne toujours.
class YkRichFormula {
  YkRichFormula._();

  static const String htmlClass = 'yk-formula';
  static const String htmlAttribute = 'data-latex';

  /// Représentation HTML d'une formule — un `<span>` autoportant, lisible
  /// (dégrade en texte brut) par tout consommateur qui ignore la classe
  /// `yk-formula` (facture PDF, e-mail, indexation — voir CDC §5.4.2).
  static String toHtml(String latex) {
    final escaped = latex
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    return '<span class="$htmlClass" $htmlAttribute="$escaped">$escaped</span>';
  }
}

/// Image insérée dans l'éditeur — CDC §5.4.2/§6 : type d'embed
/// personnalisé (pas le type `image` natif de flutter_quill, qui ne
/// porte pas de texte alternatif) pour transporter l'invite
/// d'accessibilité de bout en bout (édition → HTML → lecture).
class YkRichImage {
  YkRichImage._();

  static const String embedType = 'yk-image';
  static const String htmlClass = 'yk-image';

  static String encode({required String url, required String alt}) =>
      jsonEncode({'url': url, 'alt': alt});

  static ({String url, String alt}) decode(String data) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    return (url: map['url'] as String? ?? '', alt: map['alt'] as String? ?? '');
  }

  static String toHtml(String embedData) {
    final img = decode(embedData);
    final url = _escapeAttr(img.url);
    final alt = _escapeAttr(img.alt);
    return '<img class="$htmlClass" src="$url" alt="$alt">';
  }

  static String _escapeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Gabarits LaTeX courants pour la palette de formules — un enseignant ne
/// doit pas avoir à connaître LaTeX pour écrire ½ (CDC §5.4.2). Chaque
/// gabarit s'insère avec le curseur positionné sur le premier `■` à
/// compléter (remplacé avant insertion).
class YkFormulaTemplate {
  const YkFormulaTemplate({required this.label, required this.latex});

  final String label;
  final String latex;

  static const List<YkFormulaTemplate> common = [
    YkFormulaTemplate(label: 'Fraction', latex: r'\frac{■}{■}'),
    YkFormulaTemplate(label: 'Racine carrée', latex: r'\sqrt{■}'),
    YkFormulaTemplate(label: 'Exposant', latex: r'■^{■}'),
    YkFormulaTemplate(label: 'Indice', latex: r'■_{■}'),
    YkFormulaTemplate(label: 'Intégrale', latex: r'\int_{■}^{■} ■\,dx'),
    YkFormulaTemplate(label: 'Somme', latex: r'\sum_{■}^{■} ■'),
    YkFormulaTemplate(label: 'Matrice 2×2', latex: r'\begin{pmatrix}■&■\\■&■\end{pmatrix}'),
  ];
}

/// Emoji courants pour la barre d'outils — CDC §5.4 (« emoji »). Un choix
/// restreint, codé en dur volontairement : ce n'est pas une valeur
/// métier (rien ne « casse » si la liste change sans redéploiement
/// immédiat), juste un jeu de données d'interface, à la différence d'un
/// taux ou d'un seuil (règle 3).
class YkRichEmoji {
  YkRichEmoji._();

  static const List<String> common = [
    '😀', '😂', '🙂', '😉', '😍', '🤔', '😮', '😢', '😡', '👍',
    '👎', '👏', '🙌', '💪', '🎉', '✅', '❌', '⭐', '🔥', '💡',
    '📚', '✏️', '🎯', '🏆', '⏰', '📌', '❤️', '👀', '🤝', '🙏',
  ];
}
