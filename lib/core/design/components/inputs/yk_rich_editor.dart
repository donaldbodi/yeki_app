import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../feedback/yk_snack.dart';
import 'yk_file_upload.dart';
import 'yk_rich_html_converter.dart';
import 'yk_rich_shared.dart';
import 'yk_text_field.dart';

/// Éditeur de texte riche — CDC_DESIGN §5.4, le composant le plus demandé
/// du projet (l'exigence revient six fois dans les consignes).
///
/// Le backend stocke du HTML (voir `yk_rich_html_converter.dart`), pas du
/// Delta — la conversion se fait entièrement dans ce composant.
///
/// [onUploadImage] est fourni par l'appelant plutôt qu'appelé en dur :
/// aucun endpoint backend générique de téléversement (renvoyant une URL
/// seule, indépendant d'un objet métier complet) n'existe encore dans le
/// projet — constat P4.5, signalé, hors périmètre d'un ticket de
/// composant frontend. Le jour où cet endpoint existe, l'écran appelant
/// passe le callback correspondant ; ce composant n'a pas à le savoir.
class YkRichEditor extends StatefulWidget {
  const YkRichEditor({
    super.key,
    required this.initialHtml,
    required this.onChanged,
    required this.onUploadImage,
    required this.imageConstraint,
    required this.label,
    this.autofocus = false,
    this.showEmoji = true,
  });

  /// Contenu initial, HTML assaini (chaîne vide = document neuf).
  final String initialHtml;

  /// Appelé (débattu ~300 ms) à chaque modification, avec le HTML à jour.
  final ValueChanged<String> onChanged;

  /// Téléversement immédiat à l'insertion (pas à la soumission du
  /// formulaire englobant) — reçoit les octets, jamais un `File`.
  final Future<String> Function(YkPickedFile file) onUploadImage;

  /// Contraintes affichées avant sélection — requis, aucune valeur par
  /// défaut (règle 3 : ce n'est pas à ce composant de fixer une taille
  /// maximale, c'est une décision de l'écran appelant).
  final YkFileConstraint imageConstraint;

  /// Libellé Semantics contextuel (ex. « Énoncé de l'exercice »).
  final String label;
  final bool autofocus;

  /// P7.4 : masque le bouton emoji — ex. énoncé d'un devoir en
  /// correction automatique, où « avec emoji si correction manuelle »
  /// est une exigence explicite (l'écran appelant décide, pas ce
  /// composant — règle 3).
  final bool showEmoji;

  @override
  State<YkRichEditor> createState() => _YkRichEditorState();
}

class _YkRichEditorState extends State<YkRichEditor> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<DocChange>? _changesSub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: _buildInitialDocument(widget.initialHtml),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _changesSub = _controller.document.changes.listen((_) => _scheduleChange());
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Document _buildInitialDocument(String html) {
    if (html.trim().isEmpty) return Document();
    try {
      final delta = htmlToDelta(html);
      return delta.isEmpty ? Document() : Document.fromDelta(delta);
    } catch (_) {
      // Contenu existant malformé : on ne bloque jamais l'ouverture de
      // l'éditeur (règle 5 — ne rien perdre n'implique pas planter ;
      // l'ancien contenu reste récupérable côté serveur).
      return Document();
    }
  }

  void _scheduleChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final html = deltaToHtml(_controller.document.toDelta());
      widget.onChanged(html);
    });
  }

  void _insertEmbed(Object embeddable) {
    final index = _controller.selection.baseOffset.clamp(0, _controller.document.length);
    _controller.replaceText(index, 0, embeddable, TextSelection.collapsed(offset: index + 1));
  }

  Future<void> _openImagePicker(BuildContext context) async {
    final picked = await showModalBottomSheet<_PickedImageResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ImageInsertSheet(constraint: widget.imageConstraint),
    );
    if (picked == null || !context.mounted) return;
    try {
      final url = await widget.onUploadImage(picked.file);
      _insertEmbed(
        BlockEmbed.custom(
          CustomBlockEmbed(YkRichImage.embedType, YkRichImage.encode(url: url, alt: picked.alt)),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        YkSnack.error(context, "Échec du téléversement de l'image. Réessayez.");
      }
    }
  }

  Future<void> _openFormulaPicker(BuildContext context) async {
    final latex = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormulaInsertSheet(),
    );
    if (latex == null || latex.trim().isEmpty) return;
    _insertEmbed(BlockEmbed.formula(latex));
  }

  Future<void> _openEmojiPicker(BuildContext context) async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _EmojiPickerSheet(),
    );
    if (emoji == null) return;
    final index = _controller.selection.baseOffset.clamp(0, _controller.document.length);
    _controller.replaceText(index, 0, emoji, TextSelection.collapsed(offset: index + emoji.length));
  }

  QuillToolbarCustomButtonOptions _imageButton(BuildContext context) => QuillToolbarCustomButtonOptions(
    icon: const Icon(Icons.image_outlined),
    tooltip: 'Insérer une image',
    onPressed: () => _openImagePicker(context),
  );

  QuillToolbarCustomButtonOptions _formulaButton(BuildContext context) => QuillToolbarCustomButtonOptions(
    icon: const Icon(Icons.functions),
    tooltip: 'Insérer une formule',
    onPressed: () => _openFormulaPicker(context),
  );

  QuillToolbarCustomButtonOptions _emojiButton(BuildContext context) => QuillToolbarCustomButtonOptions(
    icon: const Icon(Icons.emoji_emotions_outlined),
    tooltip: 'Insérer un emoji',
    onPressed: () => _openEmojiPicker(context),
  );

  Future<void> _openOverflowSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(YkSpacing.md),
          child: QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              multiRowsDisplay: true,
              showFontFamily: false,
              showFontSize: false,
              showBoldButton: false,
              showItalicButton: false,
              showUnderLineButton: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: false,
              showAlignmentButtons: true,
              showHeaderStyle: true,
              showListNumbers: true,
              showListBullets: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: true,
              showUndo: false,
              showRedo: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showDividers: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context) {
    return QuillSimpleToolbar(
      controller: _controller,
      config: QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showUnderLineButton: true,
        showStrikeThrough: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: false,
        showHeaderStyle: false,
        showListNumbers: false,
        showListBullets: true,
        showListCheck: false,
        showCodeBlock: false,
        showQuote: false,
        showIndent: false,
        showLink: false,
        showUndo: false,
        showRedo: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showDividers: false,
        customButtons: [
          _imageButton(context),
          _formulaButton(context),
          if (widget.showEmoji) _emojiButton(context),
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Plus de mise en forme (titres, alignement, lien)',
            onPressed: () => _openOverflowSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeToolbar(BuildContext context) {
    return QuillSimpleToolbar(
      controller: _controller,
      config: QuillSimpleToolbarConfig(
        showFontFamily: false,
        showFontSize: false,
        showSmallButton: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showLineHeightButton: false,
        showAlignmentButtons: true,
        showListCheck: false,
        showCodeBlock: false,
        showQuote: false,
        showIndent: false,
        showDirection: false,
        showSearchButton: false,
        customButtons: [
          _imageButton(context),
          _formulaButton(context),
          if (widget.showEmoji) _emojiButton(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = YkBreakpoints.of(context) == YkBreakpoint.compact;
    return Semantics(
      label: widget.label,
      textField: true,
      multiline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            _buildLargeToolbar(context),
            SizedBox(height: YkSpacing.xs),
          ],
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            padding: EdgeInsets.all(YkSpacing.sm),
            decoration: BoxDecoration(
              color: YkColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(YkRadius.sm),
              border: Border.all(color: YkColors.border(context)),
            ),
            child: QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                autoFocus: widget.autofocus,
                placeholder: widget.label,
                expands: false,
                scrollable: true,
                padding: EdgeInsets.zero,
                embedBuilders: [const _FormulaEmbedBuilder(), const _ImageEmbedBuilder()],
              ),
            ),
          ),
          if (compact) ...[
            SizedBox(height: YkSpacing.xs),
            _buildCompactToolbar(context),
          ],
        ],
      ),
    );
  }
}

class _PickedImageResult {
  const _PickedImageResult(this.file, this.alt);
  final YkPickedFile file;
  final String alt;
}

class _ImageInsertSheet extends StatefulWidget {
  const _ImageInsertSheet({required this.constraint});
  final YkFileConstraint constraint;

  @override
  State<_ImageInsertSheet> createState() => _ImageInsertSheetState();
}

class _ImageInsertSheetState extends State<_ImageInsertSheet> {
  YkPickedFile? _picked;
  final TextEditingController _altCtrl = TextEditingController();

  @override
  void dispose() {
    _altCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          YkSpacing.lg,
          YkSpacing.lg,
          YkSpacing.lg,
          YkSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insérer une image',
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.sm),
            YkFileUpload(
              constraint: widget.constraint,
              picked: _picked,
              onChanged: (file) => setState(() => _picked = file),
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: _altCtrl,
              label: 'Texte alternatif (optionnel)',
              hint: 'Décrit brièvement l\'image pour les lecteurs d\'écran',
            ),
            SizedBox(height: YkSpacing.md),
            YkButton(
              label: 'Insérer',
              onPressed: _picked != null
                  ? () => Navigator.of(
                      context,
                    ).pop(_PickedImageResult(_picked!, _altCtrl.text.trim()))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaInsertSheet extends StatefulWidget {
  const _FormulaInsertSheet();

  @override
  State<_FormulaInsertSheet> createState() => _FormulaInsertSheetState();
}

class _FormulaInsertSheetState extends State<_FormulaInsertSheet> {
  final TextEditingController _latexCtrl = TextEditingController();

  @override
  void dispose() {
    _latexCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(YkFormulaTemplate template) {
    _latexCtrl.text = template.latex.replaceFirst('■', '').replaceAll('■', '');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          YkSpacing.lg,
          YkSpacing.lg,
          YkSpacing.lg,
          YkSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insérer une formule',
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              'Choisissez un gabarit courant, ou saisissez directement du LaTeX.',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.sm),
            Wrap(
              spacing: YkSpacing.xs,
              runSpacing: YkSpacing.xs,
              children: [
                for (final template in YkFormulaTemplate.common)
                  ActionChip(label: Text(template.label), onPressed: () => _applyTemplate(template)),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: _latexCtrl, label: 'LaTeX', hint: r'ex. \frac{1}{2}'),
            SizedBox(height: YkSpacing.sm),
            if (_latexCtrl.text.trim().isNotEmpty)
              Center(
                child: Math.tex(
                  _latexCtrl.text,
                  onErrorFallback: (_) => Text(
                    'Aperçu indisponible',
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                ),
              ),
            SizedBox(height: YkSpacing.md),
            YkButton(
              label: 'Insérer',
              onPressed: () => Navigator.of(context).pop(_latexCtrl.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Wrap(
          spacing: YkSpacing.xs,
          runSpacing: YkSpacing.xs,
          children: [
            for (final emoji in YkRichEmoji.common)
              InkWell(
                onTap: () => Navigator.of(context).pop(emoji),
                borderRadius: BorderRadius.circular(YkRadius.xs),
                child: Padding(
                  padding: EdgeInsets.all(YkSpacing.xs),
                  child: Semantics(
                    label: 'Insérer $emoji',
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormulaEmbedBuilder extends EmbedBuilder {
  const _FormulaEmbedBuilder();

  @override
  String get key => BlockEmbed.formulaType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final latex = embedContext.node.value.data as String;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.xxs),
      child: Math.tex(latex, onErrorFallback: (_) => Text(latex)),
    );
  }
}

class _ImageEmbedBuilder extends EmbedBuilder {
  const _ImageEmbedBuilder();

  @override
  String get key => YkRichImage.embedType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data as String;
    final image = YkRichImage.decode(data);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xxs),
      child: Semantics(
        label: image.alt.isEmpty ? 'Image' : image.alt,
        image: true,
        child: Image.network(
          image.url,
          errorBuilder: (context, error, stack) => Container(
            padding: EdgeInsets.all(YkSpacing.sm),
            color: YkColors.surfaceVariant(context),
            child: Icon(Icons.broken_image_outlined, color: YkColors.textSecondary(context)),
          ),
        ),
      ),
    );
  }
}
