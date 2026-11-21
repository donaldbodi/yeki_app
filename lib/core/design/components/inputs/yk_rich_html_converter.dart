import 'package:flutter_quill/flutter_quill.dart' show BlockEmbed;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html/dom.dart' as dom;

import 'yk_rich_shared.dart';

/// Convertit un [Delta] Quill en HTML — CDC_DESIGN §5.4.2 : « le backend
/// stocke du HTML assaini, pas du Delta » — le HTML est lisible par tous
/// les autres consommateurs (facture PDF, export, e-mail de notification,
/// indexation, futur back-office), un Delta n'est lisible que par Quill.
///
/// Périmètre volontairement limité aux fonctions listées par le CDC §5.4
/// (titres, gras/italique/souligné, alignement, listes, liens, images,
/// formule) — ce n'est pas un convertisseur Quill→HTML généraliste.
String deltaToHtml(Delta delta) {
  final lines = <_Line>[];
  final inlineBuffer = StringBuffer();

  void flush(Map<String, dynamic>? blockAttrs) {
    final header = blockAttrs?['header'];
    final list = blockAttrs?['list'];
    final align = blockAttrs?['align'] as String?;
    final String blockType;
    if (header != null) {
      blockType = 'h$header';
    } else if (list == 'bullet') {
      blockType = 'li-bullet';
    } else if (list == 'ordered') {
      blockType = 'li-ordered';
    } else {
      blockType = 'p';
    }
    lines.add(_Line(inlineBuffer.toString(), blockType, align));
    inlineBuffer.clear();
  }

  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    final attrs = op.attributes ?? const <String, dynamic>{};
    if (data is String) {
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          inlineBuffer.write(_renderInlineText(parts[i], attrs));
        }
        final isLastPart = i == parts.length - 1;
        if (!isLastPart) flush(attrs);
      }
    } else if (data is Map) {
      inlineBuffer.write(_renderEmbed(data));
    }
  }
  if (inlineBuffer.isNotEmpty) flush(null);

  return _renderLines(lines);
}

/// Convertit du HTML en [Delta] Quill, pour recharger un contenu existant
/// dans l'éditeur. Délègue à `flutter_quill_delta_from_html` (déjà
/// résolue en dépendance transitive de `flutter_quill` — promue en
/// directe, règle 1) pour l'essentiel du balisage standard, avec un
/// [CustomHtmlPart] dédié pour reconnaître la convention `yk-formula` (le
/// paquet ne la connaît pas, propre à ce projet).
Delta htmlToDelta(String html) {
  final converter = HtmlToDelta(customBlocks: [_FormulaHtmlPart(), _ImageHtmlPart()]);
  return converter.convert(html);
}

String _escapeHtml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _renderInlineText(String text, Map<String, dynamic> attrs) {
  var html = _escapeHtml(text);
  if (attrs['bold'] == true) html = '<strong>$html</strong>';
  if (attrs['italic'] == true) html = '<em>$html</em>';
  if (attrs['underline'] == true) html = '<u>$html</u>';
  final link = attrs['link'];
  if (link is String && link.isNotEmpty) {
    html = '<a href="${_escapeHtml(link)}">$html</a>';
  }
  return html;
}

String _renderEmbed(Map data) {
  if (data.containsKey(YkRichImage.embedType)) {
    return YkRichImage.toHtml(data[YkRichImage.embedType] as String);
  }
  if (data.containsKey(BlockEmbed.formulaType)) {
    final latex = data[BlockEmbed.formulaType] as String;
    return YkRichFormula.toHtml(latex);
  }
  return '';
}

class _Line {
  _Line(this.innerHtml, this.blockType, this.align);

  final String innerHtml;
  final String blockType;
  final String? align;
}

String _renderLines(List<_Line> lines) {
  final buf = StringBuffer();
  String? openList;

  void closeList() {
    if (openList != null) {
      buf.write('</$openList>');
      openList = null;
    }
  }

  for (final line in lines) {
    final content = line.innerHtml.isEmpty ? '<br>' : line.innerHtml;
    final isBullet = line.blockType == 'li-bullet';
    final isOrdered = line.blockType == 'li-ordered';
    if (isBullet || isOrdered) {
      final want = isBullet ? 'ul' : 'ol';
      if (openList != want) {
        closeList();
        buf.write('<$want>');
        openList = want;
      }
      buf.write('<li>$content</li>');
    } else {
      closeList();
      final styleAttr = line.align != null ? ' style="text-align: ${line.align};"' : '';
      if (line.blockType.startsWith('h')) {
        buf.write('<${line.blockType}$styleAttr>$content</${line.blockType}>');
      } else {
        buf.write('<p$styleAttr>$content</p>');
      }
    }
  }
  closeList();
  return buf.toString();
}

class _FormulaHtmlPart implements CustomHtmlPart {
  @override
  bool matches(dom.Element element) =>
      element.localName == 'span' && element.classes.contains(YkRichFormula.htmlClass);

  @override
  List<Operation> convert(dom.Element element, {Map<String, dynamic>? currentAttributes}) {
    final latex = element.attributes[YkRichFormula.htmlAttribute] ?? element.text;
    return [Operation.insert({BlockEmbed.formulaType: latex})];
  }
}

class _ImageHtmlPart implements CustomHtmlPart {
  @override
  bool matches(dom.Element element) => element.localName == 'img';

  @override
  List<Operation> convert(dom.Element element, {Map<String, dynamic>? currentAttributes}) {
    final url = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';
    if (url.isEmpty) return const [];
    return [
      Operation.insert({YkRichImage.embedType: YkRichImage.encode(url: url, alt: alt)}),
    ];
  }
}
