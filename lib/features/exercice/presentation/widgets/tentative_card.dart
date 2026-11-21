import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

import 'detail_reponse_tile.dart';

/// Une tentative complète — date, score, et le détail RÉPONSES +
/// CORRECTIONS de chacune de ses questions (snapshots P6.2). Repliée par
/// défaut (liste potentiellement longue), dépliable au tap — réutilisée
/// à la fois pour « dernière tentative » (page principale) et pour
/// l'historique complet (feuille modale), règle 1 : un seul widget pour
/// ce concept.
class TentativeCard extends StatefulWidget {
  const TentativeCard({super.key, required this.tentative, this.initiallyExpanded = false});

  final TentativeHistorique tentative;
  final bool initiallyExpanded;

  @override
  State<TentativeCard> createState() => _TentativeCardState();
}

class _TentativeCardState extends State<TentativeCard> {
  late final ValueNotifier<bool> _expanded = ValueNotifier(widget.initiallyExpanded);

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tentative;
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: ValueListenableBuilder<bool>(
        valueListenable: _expanded,
        builder: (context, expanded, _) => YkCard(
          onTap: () => _expanded.value = !expanded,
          semanticLabel: 'Tentative ${t.tentativeNumero}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tentative ${t.tentativeNumero}',
                          style: YkTypography.label(
                            context,
                          ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w700),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                          style: YkTypography.bodySm(
                            context,
                          ).copyWith(color: YkColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${t.score.toStringAsFixed(t.score.truncateToDouble() == t.score ? 0 : 2)} / '
                        '${t.total.toStringAsFixed(t.total.truncateToDouble() == t.total ? 0 : 2)}',
                        style: YkTypography.bodyMd(
                          context,
                        ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${t.noteSur20.toStringAsFixed(1)}/20',
                        style: YkTypography.bodySm(
                          context,
                        ).copyWith(color: YkColors.textSecondary(context)),
                      ),
                    ],
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: YkColors.textSecondary(context),
                  ),
                ],
              ),
              if (expanded && t.reponses.isNotEmpty) ...[
                SizedBox(height: YkSpacing.sm),
                const Divider(height: 1),
                SizedBox(height: YkSpacing.sm),
                ...t.reponses.asMap().entries.map(
                  (e) => DetailReponseTile(detail: e.value, index: e.key + 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
