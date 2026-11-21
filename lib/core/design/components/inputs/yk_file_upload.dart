import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

/// Contraintes affichées **avant** sélection — CDC §5.5.2. Reçues en
/// paramètre (règle 3 : aucune valeur métier codée en dur ici — c'est
/// l'écran appelant qui les fournit, potentiellement depuis
/// `ParametreSysteme`).
class YkFileConstraint {
  const YkFileConstraint({required this.allowedExtensions, required this.maxSizeBytes});

  /// Extensions sans le point, ex. `['jpg', 'jpeg', 'png']`.
  final List<String> allowedExtensions;
  final int maxSizeBytes;

  String get extensionsLabel => allowedExtensions.map((e) => e.toUpperCase()).join(', ');

  String get maxSizeLabel {
    final mo = maxSizeBytes / (1024 * 1024);
    return '${mo == mo.roundToDouble() ? mo.toStringAsFixed(0) : mo.toStringAsFixed(1)} Mo';
  }

  String? validate(String name, int size) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final allowed = allowedExtensions.map((e) => e.toLowerCase()).toSet();
    if (!allowed.contains(ext)) {
      return 'Format non autorisé. Formats acceptés : $extensionsLabel.';
    }
    if (size > maxSizeBytes) {
      return 'Fichier trop volumineux. Taille maximale : $maxSizeLabel.';
    }
    return null;
  }
}

/// Fichier sélectionné — CDC §5.5.2 : **jamais** de `File` (dart:io), pour
/// rester portable sur toutes les plateformes, y compris le web (voir
/// commentaire de tête de la classe [YkFileUpload]).
class YkPickedFile {
  const YkPickedFile({
    required this.bytes,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final Uint8List bytes;
  final String name;
  final String mimeType;
  final int size;
}

/// Téléversement de fichier portable — CDC_DESIGN §5.3.2/§5.5.2.
///
/// Corrige à la racine le bug `Unsupported operation: _Namespace` : ce
/// composant ne lit **jamais** un fichier via `File(path)` (dart:io),
/// signature exacte de ce crash sur le web où `PlatformFile.path` est nul
/// et où `File(...)` lève cette exception dès sa construction. Toujours
/// `FilePicker.platform.pickFiles(withData: true)` → `.bytes`, jamais
/// `.path`.
///
/// Glisser-déposer (web/desktop, via `desktop_drop`) + sélecteur (toutes
/// plateformes, via `file_picker`) ; masqué en breakpoint `compact`
/// (mobile n'a pas de glisser-déposer OS pertinent).
///
/// Le composant ne fait aucun appel réseau lui-même : [onChanged] remonte
/// le fichier choisi, l'écran appelant pilote l'upload réel et renseigne
/// [progress]/[errorText]/[onCancel] en retour (cohérent avec
/// `YkForm.onValidSubmit`).
class YkFileUpload extends StatefulWidget {
  const YkFileUpload({
    super.key,
    required this.constraint,
    required this.onChanged,
    this.picked,
    this.progress,
    this.errorText,
    this.onCancel,
    this.label,
  });

  final YkFileConstraint constraint;
  final ValueChanged<YkPickedFile?> onChanged;

  /// Fichier actuellement sélectionné (contrôlé par l'appelant, pour
  /// permettre un « supprimer » externe et un état d'upload persistant).
  final YkPickedFile? picked;

  /// 0..1 pendant un upload piloté par l'appelant ; `null` = pas d'upload
  /// en cours.
  final double? progress;

  /// Erreur serveur/réseau (distincte de l'erreur de validation locale).
  final String? errorText;
  final VoidCallback? onCancel;
  final String? label;

  @override
  State<YkFileUpload> createState() => _YkFileUploadState();
}

class _YkFileUploadState extends State<YkFileUpload> {
  String? _localError;
  bool _dragging = false;

  Future<void> _pick() async {
    setState(() => _localError = null);
    // Bug corrigé : la fenêtre système montrait TOUJOURS tous les
    // fichiers, quelle que soit `widget.constraint` — un seul point à
    // corriger (composant partagé) plutôt qu'un correctif par appelant.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.constraint.allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _localError = 'Impossible de lire ce fichier.');
      return;
    }
    _accept(bytes: bytes, name: file.name, size: file.size, providedMimeType: null);
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final dropped = details.files.first;
    try {
      final bytes = await dropped.readAsBytes();
      _accept(
        bytes: bytes,
        name: dropped.name,
        size: bytes.length,
        providedMimeType: dropped.mimeType,
      );
    } catch (_) {
      setState(() => _localError = 'Impossible de lire ce fichier.');
    }
  }

  void _accept({
    required Uint8List bytes,
    required String name,
    required int size,
    String? providedMimeType,
  }) {
    final error = widget.constraint.validate(name, size);
    if (error != null) {
      setState(() => _localError = error);
      return;
    }
    final mimeType = providedMimeType ?? lookupMimeType(name) ?? 'application/octet-stream';
    setState(() => _localError = null);
    widget.onChanged(YkPickedFile(bytes: bytes, name: name, mimeType: mimeType, size: size));
  }

  void _remove() {
    setState(() => _localError = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final compact = YkBreakpoints.of(context) == YkBreakpoint.compact;
    final error = widget.errorText ?? _localError;

    Widget zone = GestureDetector(
      onTap: widget.picked == null ? _pick : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(YkSpacing.md),
        decoration: BoxDecoration(
          color: _dragging
              ? YkColors.accent(context).withValues(alpha: 0.06)
              : YkColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(YkRadius.md),
          border: Border.all(
            color: error != null
                ? YkColors.error
                : (_dragging ? YkColors.accent(context) : YkColors.border(context)),
            width: _dragging ? 2 : 1,
          ),
        ),
        child: widget.picked != null
            ? _buildPickedPreview(context, widget.picked!)
            : _buildEmptyZone(context, compact),
      ),
    );

    if (!compact) {
      zone = DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) {
          setState(() => _dragging = false);
          _handleDrop(details);
        },
        child: zone,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
        ],
        zone,
        if (error != null) ...[
          SizedBox(height: YkSpacing.xxs),
          Text(error, style: YkTypography.bodySm(context).copyWith(color: YkColors.error)),
        ],
      ],
    );
  }

  Widget _buildEmptyZone(BuildContext context, bool compact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_file_outlined, size: 32, color: YkColors.textSecondary(context)),
        SizedBox(height: YkSpacing.xs),
        Text(
          compact ? 'Toucher pour choisir un fichier' : 'Glissez un fichier ici ou cliquez pour parcourir',
          textAlign: TextAlign.center,
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.xxs),
        Text(
          'Formats acceptés : ${widget.constraint.extensionsLabel} — ${widget.constraint.maxSizeLabel} max',
          textAlign: TextAlign.center,
          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      ],
    );
  }

  Widget _buildPickedPreview(BuildContext context, YkPickedFile file) {
    final isImage = file.mimeType.startsWith('image/');
    return Row(
      children: [
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(YkRadius.xs),
            child: Image.memory(file.bytes, width: 48, height: 48, fit: BoxFit.cover),
          )
        else
          Icon(Icons.insert_drive_file_outlined, size: 32, color: YkColors.textSecondary(context)),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              Text(
                '${(file.size / 1024).toStringAsFixed(0)} Ko',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              if (widget.progress != null) ...[
                SizedBox(height: YkSpacing.xxs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(YkRadius.xs),
                  child: LinearProgressIndicator(value: widget.progress, minHeight: 4),
                ),
              ],
            ],
          ),
        ),
        if (widget.progress != null && widget.onCancel != null)
          YkIconButton(
            icon: Icons.close,
            label: 'Annuler le téléversement',
            onPressed: widget.onCancel,
            variant: YkIconButtonVariant.ghost,
          )
        else
          YkIconButton(
            icon: Icons.delete_outline,
            label: 'Supprimer le fichier',
            onPressed: _remove,
            variant: YkIconButtonVariant.ghost,
          ),
      ],
    );
  }
}
