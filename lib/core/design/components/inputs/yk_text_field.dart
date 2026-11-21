import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/tokens.dart';
import 'yk_form.dart';

/// Type de saisie — CDC_DESIGN §5.3.2.
enum YkTextFieldType { text, multiline, password, search, number }

/// Champ de saisie unique — CDC_DESIGN §5.3.2.
///
/// Remplace les dizaines de `InputDecoration` recopiées à la main dans le
/// projet (bordures/couleurs de focus incohérentes selon l'écran).
///
/// Intégration [YkForm] (P4.4) : si [name] est fourni, le champ s'enregistre
/// auprès du [YkFormScope] ambiant — astérisque automatique si [required],
/// remontée de l'état rempli/vide pour activer le bouton de soumission,
/// affichage de l'erreur serveur mappée par [YkFormController], focus
/// automatique en cas d'erreur. Sans [name], le champ fonctionne en usage
/// libre exactement comme en P4.3 (ex. barre de recherche hors formulaire).
class YkTextField extends StatefulWidget {
  const YkTextField({
    super.key,
    this.controller,
    this.type = YkTextFieldType.text,
    this.name,
    this.required = false,
    this.validator,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.maxLength,
    this.maxLines,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(
         label != null || hint != null || semanticLabel != null,
         'YkTextField exige un label, un hint ou un semanticLabel pour '
         "l'accessibilité (§6 — libellé contextuel obligatoire).",
       );

  final TextEditingController? controller;
  final YkTextFieldType type;

  /// Clé d'enregistrement auprès du [YkFormScope] ambiant. `null` = champ
  /// libre, sans intégration formulaire.
  final String? name;

  /// Génère l'astérisque automatiquement dans le libellé — impossible à
  /// oublier (CDC §5.5.1).
  final bool required;

  /// Validation locale additionnelle (longueur, format). Évaluée après la
  /// vérification "requis" et après l'éventuelle erreur serveur.
  final FormFieldValidator<String>? validator;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final int? maxLength;

  /// Nombre de lignes pour [YkTextFieldType.multiline] (défaut 4).
  final int? maxLines;
  final IconData? prefixIcon;

  /// Ignoré pour [YkTextFieldType.password] (bascule de visibilité
  /// gérée en interne) et [YkTextFieldType.search] (bouton d'effacement
  /// géré en interne).
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  /// Libellé Semantics si différent de [label]/[hint].
  final String? semanticLabel;

  @override
  State<YkTextField> createState() => _YkTextFieldState();
}

class _YkTextFieldState extends State<YkTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  late final FocusNode _focusNode = FocusNode();
  YkFormController? _formController;
  bool _obscure = true;

  bool get _isPassword => widget.type == YkTextFieldType.password;
  bool get _isSearch => widget.type == YkTextFieldType.search;
  bool get _isMultiline => widget.type == YkTextFieldType.multiline;
  bool get _isNumber => widget.type == YkTextFieldType.number;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    if (_isSearch) _controller.addListener(_onSearchTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.name != null) {
      _formController = YkFormScope.maybeOf(context);
      // État initial transmis directement à `registerField` (P8.2) — un
      // `updateFieldFilled` séparé juste après notifierait pendant la
      // construction de l'arbre pour tout champ PRÉ-REMPLI (valeur par
      // défaut, mode édition), provoquant un `setState() called during
      // build` (voir le commentaire de `registerField`).
      _formController?.registerField(
        widget.name!,
        required: widget.required,
        focusNode: _focusNode,
        initiallyFilled: _controller.text.trim().isNotEmpty,
      );
    }
  }

  @override
  void dispose() {
    if (widget.name != null) _formController?.unregisterField(widget.name!);
    _focusNode.dispose();
    if (_isSearch) _controller.removeListener(_onSearchTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() => setState(() {});

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    if (widget.name != null) {
      _formController?.updateFieldFilled(widget.name!, value.trim().isNotEmpty);
      _formController?.clearFieldError(widget.name!);
    }
  }

  String? _validate(String? value) {
    if (widget.name != null) {
      final serverError = _formController?.errorFor(widget.name!);
      if (serverError != null) return serverError;
    }
    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'Ce champ est requis.';
    }
    return widget.validator?.call(value);
  }

  String? get _effectiveLabel {
    if (widget.label == null) return null;
    return widget.required ? '${widget.label} *' : widget.label;
  }

  @override
  Widget build(BuildContext context) {
    // Pilule + fond blanc + ombre douce pour le type `search` (maquette :
    // barre de recherche toujours en `--surface`, rayon plein, `shadow-sm`)
    // — les autres types restent rectangulaires (`YkRadius.sm`, fond
    // `surfaceVariant`), c'est le standard pour un champ de formulaire.
    final radius = BorderRadius.circular(_isSearch ? YkRadius.full : YkRadius.sm);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: YkColors.border(context)),
    );

    Widget? prefix = widget.prefixIcon != null
        ? Icon(widget.prefixIcon, color: YkColors.textSecondary(context))
        : (_isSearch ? Icon(Icons.search, color: YkColors.textSecondary(context)) : null);

    Widget? suffix;
    if (_isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: YkColors.textSecondary(context),
        ),
        tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (_isSearch && _controller.text.isNotEmpty) {
      suffix = IconButton(
        icon: Icon(Icons.close, color: YkColors.textSecondary(context)),
        tooltip: 'Effacer',
        onPressed: () {
          _controller.clear();
          _handleChanged('');
        },
      );
    } else if (widget.suffixIcon != null) {
      suffix = Icon(widget.suffixIcon, color: YkColors.textSecondary(context));
    }

    final field = Semantics(
      label: widget.semanticLabel ?? widget.label ?? widget.hint,
      textField: true,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        obscureText: _isPassword && _obscure,
        keyboardType: _isNumber
            ? TextInputType.number
            : _isMultiline
            ? TextInputType.multiline
            : TextInputType.text,
        inputFormatters: _isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        maxLines: _isMultiline ? (widget.maxLines ?? 4) : 1,
        maxLength: widget.maxLength,
        onChanged: _handleChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: _validate,
        style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
        decoration: InputDecoration(
          labelText: _effectiveLabel,
          hintText: widget.hint,
          helperText: widget.helper,
          errorText: widget.errorText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: _isSearch ? YkColors.surface(context) : YkColors.surfaceVariant(context),
          border: border,
          enabledBorder: border,
          disabledBorder: border.copyWith(
            borderSide: BorderSide(color: YkColors.border(context).withValues(alpha: 0.5)),
          ),
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: YkColors.accent(context), width: 2),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: YkColors.error, width: 1.5),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: YkColors.error, width: 2),
          ),
        ),
      ),
    );

    if (!_isSearch) return field;

    // Ombre douce portée par un conteneur transparent autour du champ —
    // `InputDecoration` ne supporte pas nativement `boxShadow` pour son
    // fond `filled`.
    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: YkElevation.e1),
      child: field,
    );
  }
}
