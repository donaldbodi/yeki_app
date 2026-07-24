import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

/// Gestion des soumissions d'un devoir — reprend l'ancien
/// `_GestionSoumissionsSheet` (filtre Tous/À corriger/Corrigés +
/// correction note/commentaire), enrichi du lien vers le PDF de
/// référence (`fichier_correction`, absent de l'ancien écran malgré son
/// existence côté backend depuis P7.2/P7.3).
class SoumissionsSheet extends StatefulWidget {
  const SoumissionsSheet({
    super.key,
    required this.soumissions,
    required this.noteSur,
    this.fichierCorrectionUrl,
    required this.onCorriger,
  });

  final List<SoumissionDevoirItem> soumissions;
  final double noteSur;
  final String? fichierCorrectionUrl;
  final Future<bool> Function(int soumissionId, double note, String commentaire) onCorriger;

  @override
  State<SoumissionsSheet> createState() => _SoumissionsSheetState();
}

class _SoumissionsSheetState extends State<SoumissionsSheet> {
  // `ValueNotifier` plutôt que `setState` (interdit sous `lib/features/`,
  // règle 7) — même patron que `TentativeCard` (P6.5).
  final ValueNotifier<String> _filtre = ValueNotifier('tous');

  @override
  void dispose() {
    _filtre.dispose();
    super.dispose();
  }

  List<SoumissionDevoirItem> _filtrees(String filtre) {
    switch (filtre) {
      case 'a_corriger':
        return widget.soumissions.where((s) => s.statut == 'soumis' || s.statut == 'en_retard').toList();
      case 'corriges':
        return widget.soumissions.where((s) => s.statut == 'corrige').toList();
      default:
        return widget.soumissions;
    }
  }

  Future<void> _ouvrirCorrection(BuildContext context, SoumissionDevoirItem s) async {
    var note = s.note ?? 0.0;
    final commentaireCtrl = TextEditingController(text: s.commentaire);
    await YkSheet.show(
      context: context,
      title: 'Corriger — ${s.apprenantNom.isNotEmpty ? s.apprenantNom : s.apprenantUsername}',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YkStepper(
              label: 'Note',
              value: note,
              min: 0,
              max: widget.noteSur,
              step: 0.5,
              onChanged: (v) => setS(() => note = v),
              valueFormatter: (v) => '${v.toStringAsFixed(1)} / ${widget.noteSur.toStringAsFixed(0)}',
            ),
            SizedBox(height: YkSpacing.md),
            YkTextField(
              controller: commentaireCtrl,
              type: YkTextFieldType.multiline,
              maxLines: 3,
              label: 'Mot justificatif (optionnel)',
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(
              label: 'Enregistrer la correction',
              onPressed: () async {
                final ok = await widget.onCorriger(s.id, note, commentaireCtrl.text.trim());
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.of(ctx).pop();
                  YkSnack.success(ctx, 'Correction enregistrée.');
                } else {
                  YkSnack.error(ctx, "Échec de l'enregistrement.");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fichierCorrectionUrl != null)
          Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.sm),
            child: YkCard(
              variant: YkCardVariant.filled,
              onTap: () => launchUrl(Uri.parse(widget.fichierCorrectionUrl!)),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: YkColors.accent(context)),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Text(
                      'Voir le PDF de correction de référence',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16, color: YkColors.textSecondary(context)),
                ],
              ),
            ),
          ),
        ValueListenableBuilder<String>(
          valueListenable: _filtre,
          builder: (context, filtre, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YkSegmented<String>(
                segments: const [
                  YkSegment(value: 'tous', label: 'Tous'),
                  YkSegment(value: 'a_corriger', label: 'À corriger'),
                  YkSegment(value: 'corriges', label: 'Corrigés'),
                ],
                selected: filtre,
                onChanged: (v) => _filtre.value = v,
              ),
              SizedBox(height: YkSpacing.sm),
              if (_filtrees(filtre).isEmpty)
                const YkEmptyState(title: 'Aucune soumission', message: "Aucune soumission pour ce filtre.")
              else
                for (final s in _filtrees(filtre)) _buildTuile(context, s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTuile(BuildContext context, SoumissionDevoirItem s) {
    final estCorrige = s.statut == 'corrige';
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xs),
      child: YkCard(
        variant: YkCardVariant.outlined,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.apprenantNom.isNotEmpty ? s.apprenantNom : s.apprenantUsername,
                    style: YkTypography.bodyMd(
                      context,
                    ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w700),
                  ),
                  Text(
                    s.soumisLe != null
                        ? 'Soumis le ${DateFormat('dd/MM/yyyy HH:mm').format(s.soumisLe!)}'
                        : s.statut,
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                  if (s.estSuspecte)
                    Text(
                      '⚠ Soumission suspecte (${s.nbFocusPerdu} pertes de focus)',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.warning),
                    ),
                ],
              ),
            ),
            if (estCorrige)
              YkChip(
                label: '${s.note?.toStringAsFixed(1) ?? "-"}/${widget.noteSur.toStringAsFixed(0)}',
                variant: YkChipVariant.assist,
                accentColor: YkColors.success,
              )
            else
              YkButton(
                label: 'Corriger',
                size: YkButtonSize.sm,
                onPressed: () => _ouvrirCorrection(context, s),
              ),
          ],
        ),
      ),
    );
  }
}
