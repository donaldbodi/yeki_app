import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

/// Affiche `1` plutôt que `1.00`, mais garde les décimales utiles
/// (`0.25`, `1.75`) — les points d'une question sont un multiple de 0.25
/// (règle métier backend), jamais une valeur arbitraire à formater au cas
/// par cas dans chaque écran. Même utilitaire que `QuestionCard`
/// (`lib/features/exercice/presentation/widgets/question_card.dart`).
String _formatPoints(double points) {
  final entier = points.truncateToDouble() == points;
  return entier ? points.toStringAsFixed(0) : points.toStringAsFixed(2);
}

/// Une question du devoir — QCM (choix à sélectionner) ou texte libre.
/// Rendu EXHAUSTIF des deux types (P7.5 : le bug signalé — « l'apprenant
/// ne voit pas le formulaire pour les questions texte libre » — n'était
/// pas reproductible dans l'ancien fichier, mais cette réécriture, testée
/// avec un devoir mixte qcm+texte, élimine structurellement toute
/// régression de ce type).
///
/// `StatefulWidget` uniquement pour porter un `TextEditingController`
/// stable entre les reconstructions du parent (déclenchées par le
/// `ChangeNotifier` de la page, jamais par un `setState` ici — interdit
/// sous `lib/features/`, règle 7). Nécessite une `key` stable
/// (`ValueKey(question.id)`) côté appelant, même patron que `QuestionCard`
/// (exercice, P6.4).
class QuestionDevoirComposerCard extends StatefulWidget {
  const QuestionDevoirComposerCard({
    super.key,
    required this.question,
    required this.index,
    required this.reponseActuelle,
    required this.onChanged,
  });

  final QuestionDevoirComposer question;
  final int index;
  final String? reponseActuelle;
  final ValueChanged<String> onChanged;

  @override
  State<QuestionDevoirComposerCard> createState() => _QuestionDevoirComposerCardState();
}

class _QuestionDevoirComposerCardState extends State<QuestionDevoirComposerCard> {
  late final TextEditingController _texteController = TextEditingController(
    text: widget.reponseActuelle ?? '',
  );

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: YkColors.accent(context),
                  child: Text(
                    '${widget.index}',
                    style: YkTypography.label(context).copyWith(color: YkColors.onAccent(context)),
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(child: YkRichViewer(html: widget.question.enonce)),
                SizedBox(width: YkSpacing.xs),
                YkChip(label: '${_formatPoints(widget.question.points)} pt', variant: YkChipVariant.assist),
              ],
            ),
            SizedBox(height: YkSpacing.md),
            if (widget.question.estQcm)
              ...widget.question.choix.map((c) => _buildOption(context, c))
            else
              YkTextField(
                controller: _texteController,
                type: YkTextFieldType.multiline,
                maxLines: 5,
                label: 'Votre réponse',
                hint: 'Rédigez votre réponse ici…',
                onChanged: widget.onChanged,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, ChoixDevoirComposer choix) {
    final selectionne = widget.reponseActuelle == choix.texte;
    final accent = YkColors.accent(context);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        variant: selectionne ? YkCardVariant.filled : YkCardVariant.outlined,
        accentColor: selectionne ? accent : null,
        onTap: () => widget.onChanged(choix.texte),
        semanticLabel: choix.texte,
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
        child: Row(
          children: [
            Icon(
              selectionne ? Icons.check_circle : Icons.circle_outlined,
              color: selectionne ? accent : YkColors.textTertiary(context),
              size: 20,
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Text(
                choix.texte,
                style: YkTypography.bodyMd(context).copyWith(
                  color: selectionne ? accent : YkColors.textPrimary(context),
                  fontWeight: selectionne ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
