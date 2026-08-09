// lib/views/pages/enseignants/olympiades_a_valider_tab.dart
//
// Onglet "Olympiades" du dashboard Coordonnateur (`enseignant_admin_
// dashboard_page.dart`) — validation admin rétablie (demande explicite de
// l'utilisateur, qui revient sur une décision produit antérieure). Même
// patron que `gestion_demandes_page.dart` (déjà établi pour ce type exact
// de flux : liste + carte + boutons Valider/Refuser + sheet de motif) —
// pas une nouvelle recette UI, juste appliquée aux olympiades.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

class OlympiadesAValiderTab extends StatefulWidget {
  const OlympiadesAValiderTab({super.key, this.onChanged});

  /// Appelé après une validation/un refus réussi — permet au dashboard
  /// parent de rafraîchir son propre badge de compteur si besoin.
  final VoidCallback? onChanged;

  @override
  State<OlympiadesAValiderTab> createState() => _OlympiadesAValiderTabState();
}

class _OlympiadesAValiderTabState extends State<OlympiadesAValiderTab> {
  final _repo = OlympiadeRepository();

  bool _loading = true;
  String? _erreur;
  List<Map<String, dynamic>> _olympiades = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final olympiades = await _repo.aValiderAdmin();
      if (mounted) setState(() => _olympiades = olympiades);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Impossible de charger les olympiades.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _valider(int id) async {
    try {
      await _repo.validerAdmin(id);
      if (mounted) {
        YkSnack.success(context, 'Olympiade validée et publiée !');
        widget.onChanged?.call();
        _charger();
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  Future<void> _refuser(int id) async {
    final motifCtrl = TextEditingController();
    final confirme = await YkSheet.show<bool>(
      context: context,
      title: 'Refuser cette olympiade',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmez le refus de cette olympiade — le cadre pourra la corriger et la soumettre à nouveau.',
            style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textSecondary(ctx)),
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: motifCtrl, type: YkTextFieldType.multiline, maxLines: 3, hint: 'Motif du refus…'),
        ],
      ),
      actionsBuilder: (ctx) => [
        YkButton(label: 'Refuser', variant: YkButtonVariant.destructive, onPressed: () => Navigator.pop(ctx, true)),
      ],
    );
    if (confirme != true) return;

    try {
      await _repo.refuserAdmin(id, motifCtrl.text.trim());
      if (mounted) {
        YkSnack.success(context, 'Olympiade refusée.');
        widget.onChanged?.call();
        _charger();
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4));
    }
    if (_erreur != null) {
      return YkErrorState(message: _erreur!, onRetry: _charger);
    }
    if (_olympiades.isEmpty) {
      return YkEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Aucune olympiade à valider',
        message: 'Les olympiades créées par vos cadres apparaîtront ici.',
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _olympiades.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _carte(context, _olympiades[i]),
      ),
    );
  }

  Widget _carte(BuildContext context, Map<String, dynamic> o) {
    final enAttente = o['statut_validation'] == 'attente';
    final couleurStatut = enAttente ? YkColors.warning : YkColors.error;
    final cadre = Map<String, dynamic>.from(o['cadre'] as Map? ?? {});
    final motif = o['motif_refus'] as String? ?? '';

    return YkCard(
      accentColor: enAttente ? YkColors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o['titre'] as String? ?? '', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text('Par ${cadre['nom'] ?? '—'}', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: enAttente ? 'En attente' : 'Refusée', color: couleurStatut),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xs,
            children: [
              YkBadge(variant: YkBadgeVariant.label, label: '${o['prix_participation'] ?? 0} FCFA', color: YkColors.accent(context)),
              if (o['edition'] != null && (o['edition'] as String).isNotEmpty)
                YkBadge(variant: YkBadgeVariant.label, label: o['edition'] as String, color: YkColors.info),
            ],
          ),
          if (motif.isNotEmpty) ...[
            SizedBox(height: YkSpacing.sm),
            YkCard(
              variant: YkCardVariant.outlined,
              accentColor: YkColors.error,
              child: Text('Motif du refus : $motif', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
            ),
          ],
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(child: YkButton(label: 'Valider', icon: Icons.check_rounded, onPressed: () => _valider(o['id'] as int))),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: YkButton(label: 'Refuser', icon: Icons.close_rounded, variant: YkButtonVariant.destructive, onPressed: () => _refuser(o['id'] as int))),
            ],
          ),
        ],
      ),
    );
  }
}
