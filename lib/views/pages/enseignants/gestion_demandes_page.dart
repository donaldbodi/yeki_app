// lib/views/pages/enseignants/gestion_demandes_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `FormationRepository`
// (plus de `http`/`SharedPreferences` bruts) et les tokens/composants
// `Yk*` — `YkTabs` remplace le `TabBar` fait main.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/formation_repository.dart';

const _statuts = ['en_attente', 'acceptee', 'refusee'];

class GestionDemandesPage extends StatefulWidget {
  final int departementId;
  final String departementNom;

  const GestionDemandesPage({super.key, required this.departementId, required this.departementNom});

  @override
  State<GestionDemandesPage> createState() => _GestionDemandesPageState();
}

class _GestionDemandesPageState extends State<GestionDemandesPage> with SingleTickerProviderStateMixin {
  final _repo = FormationRepository();
  late final _tabController = TabController(length: 3, vsync: this)..addListener(_onTabChanged);

  bool _loading = true;
  List<Map<String, dynamic>> _demandes = [];
  String get _statutFiltre => _statuts[_tabController.index];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final demandes = await _repo.demandesAcces(widget.departementId, _statutFiltre);
      if (mounted) setState(() => _demandes = demandes);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _traiterDemande(int demandeId, String action) async {
    final reponseCtrl = TextEditingController();
    final confirme = await YkSheet.show<bool>(
      context: context,
      title: action == 'accepter' ? 'Accepter la demande' : 'Refuser la demande',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action == 'accepter' ? "Confirmez l'accès à la formation pour cet apprenant." : "Confirmez le refus d'accès pour cet apprenant.",
            style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textSecondary(ctx)),
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: reponseCtrl,
            type: YkTextFieldType.multiline,
            maxLines: 3,
            hint: action == 'accepter' ? "Message optionnel pour l'apprenant…" : 'Motif du refus…',
          ),
        ],
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: action == 'accepter' ? 'Accepter' : 'Refuser',
          variant: action == 'accepter' ? YkButtonVariant.primary : YkButtonVariant.destructive,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    );

    if (confirme != true) return;

    try {
      await _repo.traiterDemandeAcces(widget.departementId, demandeId, action: action, reponse: reponseCtrl.text.trim());
      if (mounted) {
        YkSnack.success(context, action == 'accepter' ? 'Demande acceptée avec succès !' : 'Demande refusée.');
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
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Text("Demandes d'accès - ${widget.departementNom}"),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _charger)],
      ),
      body: Column(
        children: [
          Container(
            color: YkColors.surface(context),
            padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
            child: YkTabs(
              controller: _tabController,
              tabs: const [YkTabItem(label: 'En attente'), YkTabItem(label: 'Acceptées'), YkTabItem(label: 'Refusées')],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: YkProgress(shape: YkProgressShape.circular))
                : _demandes.isEmpty
                    ? _etatVide(context)
                    : ListView.separated(
                        padding: EdgeInsets.all(YkSpacing.md),
                        itemCount: _demandes.length,
                        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
                        itemBuilder: (_, i) => _carteDemande(context, _demandes[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _etatVide(BuildContext context) {
    final message = switch (_statutFiltre) {
      'en_attente' => 'Aucune demande en attente',
      'acceptee' => 'Aucune demande acceptée',
      'refusee' => 'Aucune demande refusée',
      _ => 'Aucune demande',
    };
    final icone = switch (_statutFiltre) {
      'en_attente' => Icons.hourglass_empty_rounded,
      'acceptee' => Icons.check_circle_outline_rounded,
      _ => Icons.cancel_outlined,
    };
    return YkEmptyState(icon: icone, title: message, message: '');
  }

  Widget _carteDemande(BuildContext context, Map<String, dynamic> demande) {
    final enAttente = demande['statut'] == 'en_attente';
    final estAcceptee = demande['statut'] == 'acceptee';
    final apprenantNom = demande['apprenant_nom'] ?? demande['apprenant_username'] ?? '';
    final apprenantEmail = demande['apprenant_email'] ?? '';
    final message = demande['message'] as String? ?? '';
    final reponse = demande['reponse_cadre'] as String? ?? '';
    final creeLe = demande['cree_le'] as String? ?? '';
    final couleurStatut = enAttente ? YkColors.warning : (estAcceptee ? YkColors.success : YkColors.error);

    return YkCard(
      accentColor: enAttente ? YkColors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              YkAvatar(fallbackText: apprenantNom.isNotEmpty ? apprenantNom : '?', size: YkAvatarSize.md),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(apprenantNom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text(apprenantEmail, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: enAttente ? 'En attente' : (demande['statut'] as String? ?? ''), color: couleurStatut),
            ],
          ),
          if (message.isNotEmpty) ...[
            SizedBox(height: YkSpacing.sm),
            YkCard(
              variant: YkCardVariant.filled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message du demandeur :', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context), fontWeight: FontWeight.w600)),
                  Text(message, style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
                ],
              ),
            ),
          ],
          if (reponse.isNotEmpty) ...[
            SizedBox(height: YkSpacing.sm),
            YkCard(
              variant: YkCardVariant.outlined,
              accentColor: couleurStatut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(estAcceptee ? 'Réponse positive :' : 'Motif du refus :', style: YkTypography.caption(context).copyWith(color: couleurStatut, fontWeight: FontWeight.w600)),
                  Text(reponse, style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
                ],
              ),
            ),
          ],
          if (creeLe.length >= 10) ...[
            SizedBox(height: YkSpacing.xs),
            Text('Demande du ${creeLe.substring(0, 10)}', style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context))),
          ],
          if (enAttente) ...[
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Expanded(child: YkButton(label: 'Accepter', icon: Icons.check_rounded, onPressed: () => _traiterDemande(demande['id'] as int, 'accepter'))),
                SizedBox(width: YkSpacing.sm),
                Expanded(child: YkButton(label: 'Refuser', icon: Icons.close_rounded, variant: YkButtonVariant.destructive, onPressed: () => _traiterDemande(demande['id'] as int, 'refuser'))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
