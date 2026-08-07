// lib/views/pages/enseignants/departement_form_sheet.dart
//
// Formulaire création/modification de département, extrait de
// `enseignant_admin_dashboard_page.dart` (P11.5, rituel P5.0) : les deux
// anciennes méthodes `_creerDepartement`/`_modifierDepartement`
// dupliquaient ~90% des mêmes champs conditionnels par type de parcours
// (prépa concours / formation métier / formation classique) — unifiées
// ici en un seul formulaire piloté par [existant] (`null` = création).

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/repositories/formation_repository.dart';

void ouvrirDepartementForm({
  required BuildContext context,
  required String typeParcours,
  required int idParcours,
  required String nomParcours,
  Map<String, dynamic>? existant,
  required VoidCallback onSuccess,
}) {
  final repo = DashboardRepository();
  final estModification = existant != null;
  final d = existant ?? const <String, dynamic>{};

  final nomCtrl = TextEditingController(text: d['nom'] ?? '');
  final descCtrl = TextEditingController(text: d['description'] ?? '');
  final prixCtrl = TextEditingController(text: (d['prix'] ?? 0).toString());
  final prixPresentielCtrl = TextEditingController(text: (d['prix_presentiel'] ?? 0).toString());
  final nomConcoursCtrl = TextEditingController(text: d['nom_concours'] ?? '');
  final organismeCtrl = TextEditingController(text: d['organisme_concours'] ?? '');
  final dateLimiteCtrl = TextEditingController(text: d['date_limite_inscription']?.toString() ?? '');
  final dateExamenCtrl = TextEditingController(text: d['date_examen']?.toString() ?? '');
  final arreteCtrl = TextEditingController(text: d['arrete_ministeriel'] ?? '');
  final placesCtrl = TextEditingController(text: (d['places_disponibles'] ?? '').toString());
  final debouchesCtrl = TextEditingController(text: d['debouches'] ?? '');
  final dureeCtrl = TextEditingController(text: d['duree_formation'] ?? '');
  final certificatCtrl = TextEditingController(text: d['certificat_delivre'] ?? '');
  final prerequisCtrl = TextEditingController(text: d['prerequis'] ?? '');
  final objectifsCtrl = TextEditingController(text: d['objectifs'] ?? '');
  final domaineCtrl = TextEditingController(text: d['domaine'] ?? '');
  final villeCtrl = TextEditingController(text: d['ville'] ?? '');

  List<String> niveauxSelectionnes = () {
    final niveaux = d['niveaux_accessibles'];
    if (niveaux is List) return List<String>.from(niveaux);
    if (niveaux is String) return niveaux.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    return <String>[];
  }();
  var estFormationMetier = d['est_formation_metier'] as bool? ?? false;
  var estFormationClassique = d['est_formation_classique'] as bool? ?? false;
  var accesRestreint = d['acces_restreint'] as bool? ?? false;
  var estCertifiante = d['est_certifiante'] as bool? ?? false;
  var mode = d['mode'] as String? ?? 'hybride';
  // Bug corrigé : `periode` (CDC §6.4/§7.4) est exigé sans exception par
  // `CreerDepartementView` — absent de ce formulaire jusqu'ici, la création
  // échouait TOUJOURS avec « La période de classement (periode) est
  // obligatoire ». 6 mois = pré-sélection pratique (pas un défaut caché
  // côté serveur, l'admin peut la changer avant de soumettre).
  var periode = d['periode'] as int? ?? 6;
  var niveauFormation = d['niveau_formation'] as String? ?? 'debutant';
  var niveauxDisponibles = <String>[];
  var niveauxFormationDisponibles = <NiveauFormation>[];
  var envoi = false;

  final titre = estModification
      ? 'Modifier le département'
      : (typeParcours == 'prepa' ? 'Créer un concours' : (typeParcours == 'formation' ? 'Créer une formation' : 'Créer un département'));

  FormationRepository().niveaux().then((n) => niveauxDisponibles = n).catchError((_) => <String>[]);
  FormationRepository().niveauxFormation().then((n) => niveauxFormationDisponibles = n).catchError((_) => <NiveauFormation>[]);

  Future<void> soumettre(BuildContext ctx, StateSetter setS) async {
    if (nomCtrl.text.trim().isEmpty) {
      YkSnack.error(context, 'Le nom est obligatoire.');
      return;
    }
    setS(() => envoi = true);

    final donnees = <String, dynamic>{
      'nom': nomCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'prix': int.tryParse(prixCtrl.text.trim()) ?? 0,
      'prix_presentiel': int.tryParse(prixPresentielCtrl.text.trim()) ?? 0,
      'niveaux_accessibles': niveauxSelectionnes,
      'acces_restreint': accesRestreint,
      'mode': mode,
      'periode': periode,
      if (!estModification) 'parcours_id': idParcours,
      if (!estModification) 'est_prepa_concours': typeParcours == 'prepa',
    };

    if (typeParcours == 'prepa') {
      donnees['nom_concours'] = nomConcoursCtrl.text.trim();
      donnees['organisme_concours'] = organismeCtrl.text.trim();
      if (dateLimiteCtrl.text.trim().isNotEmpty) donnees['date_limite_inscription'] = dateLimiteCtrl.text.trim();
      if (dateExamenCtrl.text.trim().isNotEmpty) donnees['date_examen'] = dateExamenCtrl.text.trim();
      donnees['arrete_ministeriel'] = arreteCtrl.text.trim();
      donnees['places_disponibles'] = int.tryParse(placesCtrl.text.trim()) ?? 0;
      donnees['debouches'] = debouchesCtrl.text.trim();
    }

    if (typeParcours == 'formation') {
      donnees['est_formation_metier'] = estFormationMetier;
      donnees['est_formation_classique'] = estFormationClassique;
      if (estFormationMetier) donnees['niveau_formation'] = niveauFormation;
      donnees['duree_formation'] = dureeCtrl.text.trim();
      donnees['domaine'] = domaineCtrl.text.trim();
      donnees['ville'] = villeCtrl.text.trim();
      donnees['certificat_delivre'] = certificatCtrl.text.trim();
      donnees['objectifs'] = objectifsCtrl.text.trim();
      donnees['prerequis'] = prerequisCtrl.text.trim();
      donnees['est_certifiante'] = estCertifiante;
    }

    try {
      if (estModification) {
        await repo.modifierDepartement(d['id'] as int, donnees);
      } else {
        await repo.creerDepartement(donnees);
      }
      if (ctx.mounted) {
        Navigator.pop(ctx);
        YkSnack.success(context, estModification ? 'Département modifié !' : 'Département créé avec succès !');
        onSuccess();
      }
    } on ApiException catch (e) {
      if (context.mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (context.mounted) YkSnack.error(context, 'Erreur réseau.');
    } finally {
      if (ctx.mounted) setS(() => envoi = false);
    }
  }

  Widget selecteurNiveaux(BuildContext ctx, StateSetter setS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Niveaux accessibles', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
        SizedBox(height: YkSpacing.xs),
        YkDropdown<String>(
          label: 'Ajouter un niveau',
          value: null,
          items: [for (final n in niveauxDisponibles.where((n) => !niveauxSelectionnes.contains(n))) YkDropdownItem(value: n, label: n)],
          onChanged: (v) {
            if (v != null) setS(() => niveauxSelectionnes.add(v));
          },
        ),
        if (niveauxSelectionnes.isNotEmpty) ...[
          SizedBox(height: YkSpacing.xs),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xs,
            children: [
              for (final n in niveauxSelectionnes)
                YkChip(label: n, variant: YkChipVariant.input, onDeleted: () => setS(() => niveauxSelectionnes.remove(n))),
            ],
          ),
        ] else
          Padding(
            padding: EdgeInsets.only(top: YkSpacing.xxs),
            child: Text(
              'Aucun niveau sélectionné → accessible à tous les niveaux.',
              style: YkTypography.caption(ctx).copyWith(color: YkColors.textTertiary(ctx)),
            ),
          ),
      ],
    );
  }

  List<Widget> champsPrepa(BuildContext ctx) => [
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: nomConcoursCtrl, label: 'Nom du concours', hint: 'Ex : ENS, Polytechnique…'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: organismeCtrl, label: 'Organisme', hint: 'Ex : MINESUP, ENS…'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: dateLimiteCtrl, label: 'Date limite inscription', hint: 'AAAA-MM-JJ'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: dateExamenCtrl, label: "Date de l'examen", hint: 'AAAA-MM-JJ'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: arreteCtrl, label: 'Arrêté ministériel', hint: 'Référence'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: placesCtrl, label: 'Places disponibles', type: YkTextFieldType.number, hint: '0 = illimité'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: debouchesCtrl, label: 'Débouchés', type: YkTextFieldType.multiline, maxLines: 2),
  ];

  List<Widget> champsFormation(BuildContext ctx, StateSetter setS) => [
    SizedBox(height: YkSpacing.sm),
    Text('Type de formation', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
    SizedBox(height: YkSpacing.xs),
    Row(
      children: [
        Expanded(
          child: YkChip(label: 'Métier', variant: YkChipVariant.filter, selected: estFormationMetier, onPressed: () => setS(() => estFormationMetier = !estFormationMetier)),
        ),
        SizedBox(width: YkSpacing.xs),
        Expanded(
          child: YkChip(label: 'Classique', variant: YkChipVariant.filter, selected: estFormationClassique, onPressed: () => setS(() => estFormationClassique = !estFormationClassique)),
        ),
      ],
    ),
    if (estFormationMetier) ...[
      SizedBox(height: YkSpacing.sm),
      Text('Niveau de la formation', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
      SizedBox(height: YkSpacing.xs),
      Wrap(
        spacing: YkSpacing.xs,
        children: [
          for (final n in niveauxFormationDisponibles)
            YkChip(label: n.label, variant: YkChipVariant.filter, selected: niveauFormation == n.code, onPressed: () => setS(() => niveauFormation = n.code)),
        ],
      ),
    ],
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: dureeCtrl, label: 'Durée', hint: 'Ex : 6 mois, 200 heures…'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: domaineCtrl, label: 'Domaine', hint: 'Ex : Informatique, Finance…'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: villeCtrl, label: 'Ville', hint: 'Ex : Yaoundé, Douala…'),
    SizedBox(height: YkSpacing.sm),
    Text('Mode', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
    SizedBox(height: YkSpacing.xs),
    Wrap(
      spacing: YkSpacing.xs,
      children: [
        for (final m in const {'hybride': 'Hybride', 'presentiel': 'Présentiel', 'distance': 'À distance'}.entries)
          YkChip(label: m.value, variant: YkChipVariant.filter, selected: mode == m.key, onPressed: () => setS(() => mode = m.key)),
      ],
    ),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: certificatCtrl, label: 'Certificat délivré', hint: 'Ex : Certificat Python…'),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: objectifsCtrl, label: 'Objectifs pédagogiques', type: YkTextFieldType.multiline, maxLines: 3),
    SizedBox(height: YkSpacing.sm),
    YkTextField(controller: prerequisCtrl, label: 'Prérequis', type: YkTextFieldType.multiline, maxLines: 2),
    SizedBox(height: YkSpacing.sm),
    SwitchListTile(
      value: estCertifiante,
      onChanged: (v) => setS(() => estCertifiante = v),
      title: const Text('Formation certifiante'),
      subtitle: const Text('Délivre un certificat reconnu à la fin'),
      contentPadding: EdgeInsets.zero,
    ),
  ];

  YkSheet.show<void>(
    context: context,
    title: titre,
    bodyBuilder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parcours : $nomParcours', style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textSecondary(ctx))),
          SizedBox(height: YkSpacing.md),
          YkTextField(controller: nomCtrl, label: 'Nom *', hint: typeParcours == 'prepa' ? 'Ex : Concours ENS' : 'Ex : Formation Développement Web'),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: descCtrl, label: 'Description', type: YkTextFieldType.multiline, maxLines: 3),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: prixCtrl, label: 'Prix (FCFA)', type: YkTextFieldType.number, hint: '0 = gratuit'),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: prixPresentielCtrl, label: 'Prix présentiel (FCFA)', type: YkTextFieldType.number, hint: '0 = absent'),
          SizedBox(height: YkSpacing.sm),
          selecteurNiveaux(ctx, setS),
          SizedBox(height: YkSpacing.sm),
          SwitchListTile(
            value: accesRestreint,
            onChanged: (v) => setS(() => accesRestreint = v),
            title: const Text('Accès restreint'),
            subtitle: const Text("Les apprenants doivent demander l'accès"),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: YkSpacing.sm),
          YkDropdown<int>(
            // Tous les mois (1-12), pas seulement 1/3/6/12 — demande
            // explicite de l'utilisateur : une durée de période est une
            // vraie donnée métier par département, pas un choix à limiter.
            items: [for (var m = 1; m <= 12; m++) YkDropdownItem(value: m, label: m == 1 ? '1 mois' : '$m mois')],
            value: periode,
            label: 'Période de classement *',
            onChanged: (v) => setS(() => periode = v ?? periode),
          ),
          if (typeParcours == 'prepa') ...champsPrepa(ctx),
          if (typeParcours == 'formation') ...champsFormation(ctx, setS),
        ],
      ),
    ),
    actionsBuilder: (ctx) => [
      StatefulBuilder(
        builder: (ctx, setS) => YkButton(
          label: estModification ? 'Mettre à jour' : 'Créer',
          isLoading: envoi,
          onPressed: envoi ? null : () => soumettre(ctx, setS),
        ),
      ),
    ],
  );
}
