// lib/views/pages/enseignants/departement_form_sheet.dart
//
// Formulaire création/modification de département, extrait de
// `enseignant_admin_dashboard_page.dart` (P11.5, rituel P5.0) : les deux
// anciennes méthodes `_creerDepartement`/`_modifierDepartement`
// dupliquaient ~90% des mêmes champs conditionnels par type de parcours
// (prépa concours / formation métier / formation classique) — unifiées
// ici en un seul formulaire piloté par [existant] (`null` = création).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/utils/cycles_departement.dart';
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
  // `prix`/`prix_presentiel` (legacy, accès one-shot au catalogue) ne sont
  // PLUS modifiables depuis ce formulaire — analyse confirmée : ils ne
  // pilotent ni le Premium ni l'accès réel une fois `prix_mensuel`/
  // `prix_annuel` renseignés, ne servent plus qu'à l'étiquette catalogue
  // (voir `formations_pages.dart`/`concours_pages.dart`), et leur
  // présence ici laissait croire à tort qu'ils fixaient l'accès Premium.
  // Champs backend/API/données INCHANGÉS (aucune perte, règle 5) — retrait
  // du formulaire uniquement.
  // Rectification modèle économique : l'abonnement Premium est désormais
  // PROPRE À CE DÉPARTEMENT — ces 2 champs existaient déjà côté backend
  // (P9.1) mais n'avaient jusqu'ici AUCUN formulaire pour les fixer, donc
  // toujours à 0 en pratique. Tant qu'ils restent à 0, aucun apprenant ne
  // peut s'abonner à ce département (`StatutAbonnementView.disponible`).
  final prixMensuelCtrl = TextEditingController(text: (d['prix_mensuel'] ?? 0).toString());
  final prixAnnuelCtrl = TextEditingController(text: (d['prix_annuel'] ?? 0).toString());
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
  // Cycles (abonnement et classement) : date de début, période du cycle en
  // mois, nombre de cycles par an (au plus 12 ÷ période) et placement. Les
  // dates de chaque cycle sont calculées (aperçu ici, référence côté
  // serveur : apps/formation/cycles.py). Le classement suit les cycles.
  final aujourdhui = DateTime.now();
  DateTime? cycleDebut = DateTime.tryParse(d['cycle_date_debut']?.toString() ?? '') ??
      (estModification ? null : DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day));
  var cycleDuree = (d['cycle_duree_mois'] as int?) ?? (d['periode'] as int?)?.clamp(1, 12).toInt() ?? 12;
  var cycleNombre = ((d['cycle_nombre'] as int?) ?? 1).clamp(1, nombreMaxCycles(cycleDuree)).toInt();
  var cyclePlacement = d['cycle_placement'] as String? ?? kPlacementSuite;
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
    final manquants = [
      if (nomCtrl.text.trim().isEmpty) 'le nom',
      if (cycleDebut == null) 'la date de début du cycle',
      if (prixAnnuelCtrl.text.trim().isEmpty) "le prix de l'abonnement sur le cycle",
      if (prixMensuelCtrl.text.trim().isEmpty) "le prix de l'abonnement mensuel",
      if (typeParcours == 'formation' && !estFormationMetier && !estFormationClassique) 'le type de formation',
    ];
    if (manquants.isNotEmpty) {
      YkSnack.error(context, 'Champs obligatoires manquants : ${manquants.join(', ')}.');
      return;
    }
    setS(() => envoi = true);

    final donnees = <String, dynamic>{
      'nom': nomCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'prix_mensuel': int.tryParse(prixMensuelCtrl.text.trim()) ?? 0,
      'prix_annuel': int.tryParse(prixAnnuelCtrl.text.trim()) ?? 0,
      'niveaux_accessibles': niveauxSelectionnes,
      'acces_restreint': accesRestreint,
      'mode': mode,
      'cycle_date_debut': DateFormat('yyyy-MM-dd').format(cycleDebut!),
      'cycle_duree_mois': cycleDuree,
      'cycle_nombre': cycleNombre,
      'cycle_placement': cycleNombre > 1 ? cyclePlacement : kPlacementSuite,
      // Compatibilité avec un serveur pas encore à jour.
      'periode': cycleDuree,
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

  Widget titreSection(BuildContext ctx, String texte) => Padding(
    padding: EdgeInsets.only(top: YkSpacing.md, bottom: YkSpacing.xs),
    child: Text(texte, style: YkTypography.h4(ctx).copyWith(color: YkColors.textPrimary(ctx))),
  );

  // ── Cycles et abonnement ────────────────────────────────────────────
  List<Widget> champsCycles(BuildContext ctx, StateSetter setS) {
    final maximum = nombreMaxCycles(cycleDuree);
    final placement = cycleNombre > 1 ? cyclePlacement : kPlacementSuite;
    final cycles = cycleDebut == null
        ? const <CycleDepartement>[]
        : calculerCycles(debut: cycleDebut!, dureeMois: cycleDuree, nombre: cycleNombre, placement: placement);
    final libelle = libelleAbonnementCycle(nomDepartement: nomCtrl.text, dureeMois: cycleDuree, nombre: cycleNombre);
    final format = DateFormat('d MMM yyyy', 'fr_FR');

    return [
      titreSection(ctx, 'Cycles et abonnement'),
      Text(
        "Le classement est remis à zéro à la fin de chaque cycle, et les cycles recommencent chaque année.",
        style: YkTypography.caption(ctx).copyWith(color: YkColors.textSecondary(ctx)),
      ),
      SizedBox(height: YkSpacing.sm),
      YkDateTimePicker(
        mode: YkDateTimePickerMode.date,
        label: 'Date de début du cycle *',
        value: cycleDebut,
        firstDate: DateTime(aujourdhui.year - 1),
        lastDate: DateTime(aujourdhui.year + 2, 12, 31),
        onChanged: (v) => setS(() => cycleDebut = DateTime(v.year, v.month, v.day)),
      ),
      SizedBox(height: YkSpacing.sm),
      YkDropdown<int>(
        label: 'Période du cycle *',
        value: cycleDuree,
        items: [for (var m = 1; m <= 12; m++) YkDropdownItem(value: m, label: m == 1 ? '1 mois' : '$m mois')],
        onChanged: (v) => setS(() {
          cycleDuree = v ?? cycleDuree;
          // Le nombre de cycles ne peut jamais dépasser 12 ÷ période.
          cycleNombre = cycleNombre.clamp(1, nombreMaxCycles(cycleDuree)).toInt();
        }),
      ),
      SizedBox(height: YkSpacing.sm),
      YkDropdown<int>(
        label: 'Nombre de cycles par an * (maximum $maximum)',
        value: cycleNombre,
        items: [for (var n = 1; n <= maximum; n++) YkDropdownItem(value: n, label: n == 1 ? '1 cycle' : '$n cycles')],
        onChanged: (v) => setS(() => cycleNombre = v ?? cycleNombre),
      ),
      if (cycleNombre > 1) ...[
        SizedBox(height: YkSpacing.sm),
        Text('Placement des cycles *', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
        SizedBox(height: YkSpacing.xs),
        Row(
          children: [
            Expanded(
              child: YkChip(
                label: 'À la suite',
                variant: YkChipVariant.filter,
                selected: cyclePlacement == kPlacementSuite,
                onPressed: () => setS(() => cyclePlacement = kPlacementSuite),
              ),
            ),
            SizedBox(width: YkSpacing.xs),
            Expanded(
              child: YkChip(
                label: "Répartis sur l'année",
                variant: YkChipVariant.filter,
                selected: cyclePlacement == kPlacementRepartis,
                onPressed: () => setS(() => cyclePlacement = kPlacementRepartis),
              ),
            ),
          ],
        ),
      ],
      if (cycles.isNotEmpty) ...[
        SizedBox(height: YkSpacing.sm),
        YkCard(
          variant: YkCardVariant.filled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dates calculées', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
              SizedBox(height: YkSpacing.xs),
              for (final c in cycles)
                Padding(
                  padding: EdgeInsets.only(top: YkSpacing.xxs),
                  child: Text(
                    'Cycle ${c.numero} : du ${format.format(c.debut)} au ${format.format(c.dernierJour)}',
                    style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textSecondary(ctx)),
                  ),
                ),
            ],
          ),
        ),
      ],
      SizedBox(height: YkSpacing.sm),
      YkTextField(
        controller: prixAnnuelCtrl,
        label: '$libelle (FCFA) *',
        type: YkTextFieldType.number,
        hint: "Valable jusqu'à la fin du cycle en cours · 0 = indisponible",
      ),
      SizedBox(height: YkSpacing.sm),
      YkTextField(
        controller: prixMensuelCtrl,
        label: 'Abonnement mensuel (FCFA) *',
        type: YkTextFieldType.number,
        hint: 'Valable 30 jours · 0 = indisponible',
      ),
    ];
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
    Text('Type de formation *', style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
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
          Text(
            'Les champs marqués d’une étoile (*) sont obligatoires.',
            style: YkTypography.caption(ctx).copyWith(color: YkColors.textTertiary(ctx)),
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: nomCtrl,
            label: 'Nom *',
            hint: typeParcours == 'prepa' ? 'Ex : Concours ENS' : 'Ex : Formation Développement Web',
            // Le libellé de l'abonnement reprend le nom du département.
            onChanged: (_) => setS(() {}),
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: descCtrl, label: 'Description', type: YkTextFieldType.multiline, maxLines: 3),
          ...champsCycles(ctx, setS),
          titreSection(ctx, 'Accès'),
          selecteurNiveaux(ctx, setS),
          SizedBox(height: YkSpacing.sm),
          SwitchListTile(
            value: accesRestreint,
            onChanged: (v) => setS(() => accesRestreint = v),
            title: const Text('Accès restreint'),
            subtitle: const Text("Les apprenants doivent demander l'accès"),
            contentPadding: EdgeInsets.zero,
          ),
          if (typeParcours == 'prepa') ...[titreSection(ctx, 'Concours'), ...champsPrepa(ctx)],
          if (typeParcours == 'formation') ...[titreSection(ctx, 'Formation'), ...champsFormation(ctx, setS)],
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
