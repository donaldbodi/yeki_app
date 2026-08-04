// lib/views/pages/apprenants/lecons_cours.dart
//
// Refondu en P11.4 (rituel P5.0) : bascule vers `CoursRepository`
// (modules/leçons, plus de `http`/`SharedPreferences` bruts) et les
// tokens/composants `Yk*` (`YkFileUpload` remplace le sélecteur de
// fichier fait main, `YkSheet` les `showModalBottomSheet` manuels).
// Ajout du bouton "Chercher un répétiteur" (P11.4, texte explicite du
// ticket) — bascule sur `YkRepetiteurButton` (P11.7).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/views/pages/apprenants/lecon_models.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

const _pdfConstraint = YkFileConstraint(allowedExtensions: ['pdf'], maxSizeBytes: 10 * 1024 * 1024);
const _videoConstraint = YkFileConstraint(
  allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
  maxSizeBytes: 200 * 1024 * 1024,
);

class LeconsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final RoleEnseignant? role;
  final TabController tabController;
  final void Function(int questionId)? onNaviguerForum;

  /// Bascule le parent (`CoursDetailTabs` ou `DetailCoursEnseignantPage`)
  /// vers son propre onglet Exercices, avec le filtre demandé — remplace
  /// un ancien `Navigator.push` vers `CoursDetailTabs` (P3.3) qui, côté
  /// enseignant, poussait par erreur l'écran apprenant plein écran par-
  /// dessus l'écran enseignant. Même patron que [onNaviguerForum] : géré
  /// en interne par le parent (bascule de `TabController`), jamais une
  /// navigation vers une autre route.
  final void Function({int? moduleId, int? leconId})? onNaviguerExercices;

  /// Accès réel au contenu premium (vidéo) du cours — dérivé de
  /// `DepartementItem.estAccessible` par l'appelant, jamais recalculé ici.
  /// `true` pour un enseignant (toujours plein accès à son propre cours).
  final bool isPremium;
  final Color courseColor;

  /// Nom complet de l'enseignant principal — `null` si non chargé/absent
  /// (voir `CoursDetailInfo`, `cours_detail_page.dart._chargerProgression`).
  /// Utilisé uniquement côté apprenant (carte enseignant, bas de l'onglet).
  final String? enseignantNom;

  const LeconsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    required this.tabController,
    this.onNaviguerForum,
    this.onNaviguerExercices,
    this.isPremium = false,
    required this.courseColor,
    this.enseignantNom,
  });

  @override
  State<LeconsCoursPage> createState() => _LeconsCoursPageState();
}

class _LeconsCoursPageState extends State<LeconsCoursPage> {
  final _repo = CoursRepository();
  bool _loading = true;
  List<ModuleAvecLecons> _modules = [];

  /// Un seul module ouvert à la fois (accordéon, maquette « 09 · Détail
  /// cours »). Ouvert par défaut : le module de la leçon « en cours »
  /// (voir [_leconCouranteId]).
  int? _moduleOuvertId;

  bool get _canEdit => widget.role == RoleEnseignant.enseignantCadre || widget.role == RoleEnseignant.enseignantPrincipal;

  /// Id de la 1ʳᵉ leçon non terminée, tous modules confondus, dans l'ordre
  /// d'affichage — sert à distinguer « en cours » de « à venir » sur la
  /// puce de statut (aucun verrou réel n'existe au niveau de la leçon
  /// entière dans ce projet, voir `_buildLeconTile`).
  int? get _leconCouranteId {
    for (final module in _modules) {
      for (final lecon in module.lecons) {
        if (!lecon.estTerminee) return lecon.id;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final modules = await _repo.modules(int.parse(widget.coursId));
      if (mounted) {
        setState(() {
          _modules = modules;
          _moduleOuvertId ??= _moduleDeLaLeconCouranteOuPremier(modules);
        });
      }
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _moduleDeLaLeconCouranteOuPremier(List<ModuleAvecLecons> modules) {
    for (final module in modules) {
      if (module.lecons.any((l) => !l.estTerminee)) return module.id;
    }
    return modules.isEmpty ? null : modules.first.id;
  }

  void _ouvrirLecon(LeconItem lecon) {
    context.pushNamed(
      AppRoute.leconDetail,
      pathParameters: {'leconId': lecon.id.toString(), 'coursId': widget.coursId},
      queryParameters: {
        'coursTitre': widget.coursTitre,
        'coursColor': widget.courseColor.toARGB32().toString(),
        'isPremium': widget.isPremium.toString(),
      },
    );
  }

  Future<void> _creerModule(String titre, String description, int ordre) async {
    try {
      await _repo.creerModule(int.parse(widget.coursId), titre: titre, description: description, ordre: ordre);
      if (mounted) YkSnack.success(context, 'Module créé !');
      _charger();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur lors de la création.');
    }
  }

  Future<void> _modifierModule(int id, String titre, String description, int ordre) async {
    try {
      await _repo.modifierModule(id, titre: titre, description: description, ordre: ordre);
      if (mounted) YkSnack.success(context, 'Module modifié !');
      _charger();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur lors de la modification.');
    }
  }

  Future<void> _supprimerModule(int id) async {
    final confirme = await _confirmer('Supprimer ce module ?', 'Toutes les leçons liées seront supprimées.');
    if (confirme != true) return;
    try {
      await _repo.supprimerModule(id);
      if (mounted) YkSnack.success(context, 'Module supprimé.');
      _charger();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur lors de la suppression.');
    }
  }

  Future<void> _supprimerLecon(int id) async {
    final confirme = await _confirmer('Supprimer cette leçon ?', 'Action irréversible.');
    if (confirme != true) return;
    try {
      await _repo.supprimerLecon(id);
      if (mounted) YkSnack.success(context, 'Leçon supprimée.');
      _charger();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur lors de la suppression.');
    }
  }

  Future<bool?> _confirmer(String titre, String message) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        YkButton(label: 'Supprimer', variant: YkButtonVariant.destructive, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );

  void _showModuleSheet({ModuleAvecLecons? existant}) {
    final titreCtrl = TextEditingController(text: existant?.titre ?? '');
    final descCtrl = TextEditingController(text: existant?.description ?? '');
    final ordreCtrl = TextEditingController(text: (existant?.ordre ?? _modules.length + 1).toString());

    YkSheet.show<void>(
      context: context,
      title: existant != null ? 'Modifier le module' : 'Nouveau module',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkTextField(controller: titreCtrl, label: 'Titre du module', hint: 'Ex : Algèbre linéaire'),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: descCtrl,
            label: 'Description',
            hint: 'Objectifs du module',
            type: YkTextFieldType.multiline,
            maxLines: 2,
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: ordreCtrl, label: 'Position (ordre)', type: YkTextFieldType.number),
        ],
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: existant != null ? 'Enregistrer' : 'Créer le module',
          onPressed: () {
            if (titreCtrl.text.trim().isEmpty) {
              YkSnack.error(context, 'Le titre est requis.');
              return;
            }
            final ordre = int.tryParse(ordreCtrl.text.trim()) ?? 1;
            Navigator.pop(ctx);
            if (existant != null) {
              _modifierModule(existant.id, titreCtrl.text.trim(), descCtrl.text.trim(), ordre);
            } else {
              _creerModule(titreCtrl.text.trim(), descCtrl.text.trim(), ordre);
            }
          },
        ),
      ],
    );
  }

  void _showLeconSheet({required int moduleId, LeconItem? existante}) {
    final titreCtrl = TextEditingController(text: existante?.titre ?? '');
    final descCtrl = TextEditingController(text: existante?.description ?? '');
    var moduleSelectionne = existante?.moduleId ?? moduleId;
    YkPickedFile? pdf;
    YkPickedFile? video;

    YkSheet.show<void>(
      context: context,
      title: existante != null ? 'Modifier la leçon' : 'Ajouter une leçon',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YkTextField(controller: titreCtrl, label: 'Titre de la leçon', hint: 'Ex : Chapitre 1 — Introduction'),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: descCtrl,
              label: 'Résumé / Description',
              hint: 'De quoi parle cette leçon ?',
              type: YkTextFieldType.multiline,
              maxLines: 3,
            ),
            SizedBox(height: YkSpacing.sm),
            if (_modules.length > 1)
              YkDropdown<int>(
                label: 'Module',
                value: moduleSelectionne,
                items: [for (final m in _modules) YkDropdownItem(value: m.id, label: m.titre)],
                onChanged: (v) => setS(() => moduleSelectionne = v ?? moduleSelectionne),
              ),
            SizedBox(height: YkSpacing.sm),
            YkFileUpload(
              label: 'Fichier PDF',
              constraint: _pdfConstraint,
              picked: pdf,
              onChanged: (f) => setS(() => pdf = f),
            ),
            SizedBox(height: YkSpacing.sm),
            YkFileUpload(
              label: 'Vidéo (optionnel)',
              constraint: _videoConstraint,
              picked: video,
              onChanged: (f) => setS(() => video = f),
            ),
          ],
        ),
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: existante != null ? 'Enregistrer' : 'Publier la leçon',
          onPressed: () async {
            if (titreCtrl.text.trim().isEmpty) {
              YkSnack.error(context, 'Le titre est requis.');
              return;
            }
            Navigator.pop(ctx);
            try {
              if (existante != null) {
                await _repo.modifierLecon(
                  existante.id,
                  titre: titreCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  nouveauModuleId: moduleSelectionne,
                  nouveauPdf: pdf,
                  nouvelleVideo: video,
                );
                if (mounted) YkSnack.success(context, 'Leçon modifiée !');
              } else {
                await _repo.creerLecon(
                  int.parse(widget.coursId),
                  titre: titreCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  moduleId: moduleId,
                  pdf: pdf,
                  video: video,
                );
                if (mounted) YkSnack.success(context, 'Leçon publiée !');
              }
              _charger();
            } catch (_) {
              if (mounted) YkSnack.error(context, 'Erreur lors de la publication.');
            }
          },
        ),
      ],
    );
  }

  /// Gestion des suppléments (P11.9) — réservée à l'enseignant PRINCIPAL
  /// du cours (vérifié côté backend, 403 sinon) ; visible ici à tout
  /// `_canEdit` (cadre inclus) pour rester cohérent avec le reste du menu
  /// — l'erreur 403 est affichée si le vérificateur backend refuse.
  Future<void> _gererSupplements(LeconItem lecon) async {
    List<SupplementCoursItem> supplements;
    try {
      supplements = await _repo.supplements(int.parse(widget.coursId), leconId: lecon.id);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
      return;
    }
    if (!mounted) return;

    await YkSheet.show<void>(
      context: context,
      title: 'Suppléments — ${lecon.titre}',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in supplements)
              YkCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.titre, style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
                          YkBadge(variant: YkBadgeVariant.label, label: s.leconId == null ? 'Tout le cours' : 'Cette leçon', color: YkColors.accent(ctx)),
                        ],
                      ),
                    ),
                    YkIconButton(
                      icon: Icons.delete_outline,
                      label: 'Retirer',
                      onPressed: () async {
                        try {
                          await _repo.supprimerSupplement(s.id);
                          setS(() => supplements.removeWhere((e) => e.id == s.id));
                          if (mounted) YkSnack.success(context, 'Supplément retiré.');
                        } catch (_) {
                          if (mounted) YkSnack.error(context, 'Erreur lors du retrait.');
                        }
                      },
                    ),
                  ],
                ),
              ),
            SizedBox(height: YkSpacing.sm),
            YkButton(
              label: 'Ajouter un supplément',
              icon: Icons.add,
              variant: YkButtonVariant.secondary,
              onPressed: () => _ouvrirCreationSupplement(lecon, onCree: (nouveau) => setS(() => supplements.add(nouveau))),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirCreationSupplement(LeconItem lecon, {required void Function(SupplementCoursItem) onCree}) {
    final titreCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    var type = 'lien';
    var porteeCours = false;

    YkSheet.show<void>(
      context: context,
      title: 'Nouveau supplément',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YkTextField(controller: titreCtrl, label: 'Titre'),
            SizedBox(height: YkSpacing.sm),
            YkDropdown<String>(
              label: 'Type',
              value: type,
              items: const [
                YkDropdownItem(value: 'lien', label: 'Lien'),
                YkDropdownItem(value: 'pdf', label: 'PDF'),
                YkDropdownItem(value: 'ppt', label: 'PowerPoint'),
                YkDropdownItem(value: 'autre', label: 'Autre'),
              ],
              onChanged: (v) => setS(() => type = v ?? type),
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: urlCtrl, label: 'URL', hint: 'https://…'),
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Checkbox(value: porteeCours, onChanged: (v) => setS(() => porteeCours = v ?? false)),
                Expanded(child: Text('Visible sur tout le cours (pas seulement cette leçon)', style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textSecondary(ctx)))),
              ],
            ),
          ],
        ),
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: 'Ajouter',
          onPressed: () async {
            if (titreCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) {
              YkSnack.error(context, 'Titre et URL sont requis.');
              return;
            }
            Navigator.pop(ctx);
            try {
              await _repo.creerSupplement(
                int.parse(widget.coursId),
                titre: titreCtrl.text.trim(),
                typeContenu: type,
                url: urlCtrl.text.trim(),
                leconId: porteeCours ? null : lecon.id,
              );
              final ajoutes = await _repo.supplements(int.parse(widget.coursId), leconId: lecon.id);
              final nouveau = ajoutes.firstWhere((s) => s.titre == titreCtrl.text.trim(), orElse: () => ajoutes.last);
              onCree(nouveau);
              if (mounted) YkSnack.success(context, 'Supplément ajouté !');
            } on ApiException catch (e) {
              if (mounted) YkSnack.error(context, e.message);
            } catch (_) {
              if (mounted) YkSnack.error(context, 'Erreur réseau.');
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: YkProgress(shape: YkProgressShape.circular, color: widget.courseColor));
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sommaire du cours', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
              if (_canEdit)
                YkButton(
                  label: 'Module',
                  icon: Icons.add,
                  size: YkButtonSize.sm,
                  onPressed: () => _showModuleSheet(),
                ),
            ],
          ),
          SizedBox(height: YkSpacing.md),
          if (_modules.isEmpty)
            YkEmptyState(
              icon: Icons.folder_open,
              title: 'Aucun module disponible',
              message: _canEdit ? 'Créez votre premier module pour commencer.' : 'Le contenu de ce cours arrive bientôt.',
              actionLabel: _canEdit ? 'Créer le premier module' : null,
              onAction: _canEdit ? () => _showModuleSheet() : null,
            )
          else
            for (final module in _modules) _buildModuleBlock(module),
          if (!_canEdit) ..._buildBasDePageApprenant(context),
        ],
      ),
    );
  }

  /// Suppléments/enseignant/répétiteur — maquette « 09 · Détail cours »,
  /// bas de l'onglet Leçons. Apprenant uniquement : l'enseignant gère déjà
  /// les suppléments par leçon avec droits d'édition (menu existant), et
  /// une carte « contactez-moi »/un CTA répétiteur n'a pas de sens pour
  /// l'enseignant qui gère son propre cours.
  List<Widget> _buildBasDePageApprenant(BuildContext context) {
    return [
      SizedBox(height: YkSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: YkButton(
          label: 'Suppléments de cours',
          icon: Icons.attach_file_rounded,
          variant: YkButtonVariant.secondary,
          onPressed: _voirSupplementsCours,
        ),
      ),
      if (widget.enseignantNom != null) ...[
        SizedBox(height: YkSpacing.sm),
        _buildCarteEnseignant(context, widget.enseignantNom!),
      ],
      SizedBox(height: YkSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: YkRepetiteurButton(onPressed: () => context.pushNamed(AppRoute.repetiteurs)),
      ),
    ];
  }

  Widget _buildCarteEnseignant(BuildContext context, String nomComplet) {
    final initiales = nomComplet
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return YkCard(
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: YkGradientBackground(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [YkColors.primary700, YkColors.primary500],
                ),
                child: Center(
                  child: Text(initiales, style: YkTypography.label(context).copyWith(color: YkColors.textOnPrimary)),
                ),
              ),
            ),
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomComplet, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                Text(
                  'Enseignant principal',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          // Aucune messagerie directe n'existe dans ce projet (seul le
          // Forum) — bascule sur l'onglet Forum plutôt que d'inventer un
          // bouton mort.
          YkIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Poser une question sur le forum',
            variant: YkIconButtonVariant.tonal,
            onPressed: () => widget.tabController.animateTo(3),
          ),
        ],
      ),
    );
  }

  /// Suppléments de PORTÉE COURS ENTIÈRE, en lecture seule — apprenant.
  /// Distinct de `_gererSupplements` (édition, enseignant, par leçon).
  Future<void> _voirSupplementsCours() async {
    List<SupplementCoursItem> supplements;
    try {
      supplements = await _repo.supplements(int.parse(widget.coursId));
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
      return;
    }
    if (!mounted) return;

    await YkSheet.show<void>(
      context: context,
      title: 'Suppléments de cours',
      bodyBuilder: (ctx) => supplements.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: YkSpacing.lg),
              child: Text(
                'Aucun supplément disponible pour ce cours.',
                style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textSecondary(ctx)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final s in supplements) _supplementTile(ctx, s)],
            ),
    );
  }

  Widget _supplementTile(BuildContext ctx, SupplementCoursItem s, {VoidCallback? onDelete}) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.titre, style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
                  YkBadge(
                    variant: YkBadgeVariant.label,
                    label: s.leconId == null ? 'Tout le cours' : 'Cette leçon',
                    color: YkColors.accent(ctx),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              YkIconButton(icon: Icons.delete_outline, label: 'Retirer', onPressed: onDelete)
            else
              YkIconButton(
                icon: Icons.open_in_new_rounded,
                label: 'Ouvrir',
                onPressed: () {
                  final lien = s.lienAOuvrir;
                  if (lien != null) launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleBlock(ModuleAvecLecons module) {
    final ouvert = module.id == _moduleOuvertId;
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        accentColor: widget.courseColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(YkRadius.md),
              onTap: () => setState(() => _moduleOuvertId = ouvert ? null : module.id),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(YkRadius.md),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: ouvert ? widget.courseColor : YkColors.surfaceVariant(context),
                      alignment: Alignment.center,
                      child: Text(
                        module.ordre.toString().padLeft(2, '0'),
                        style: YkTypography.caption(
                          context,
                        ).copyWith(color: ouvert ? YkColors.textOnPrimary : YkColors.textSecondary(context), fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(module.titre, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                        if (module.description.isNotEmpty)
                          Text(
                            module.description,
                            style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  YkBadge(
                    variant: YkBadgeVariant.label,
                    label: '${module.lecons.length} leçon${module.lecons.length > 1 ? 's' : ''}',
                    color: widget.courseColor,
                  ),
                  if (_canEdit) ...[
                    YkIconButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier le module',
                      variant: YkIconButtonVariant.ghost,
                      onPressed: () => _showModuleSheet(existant: module),
                    ),
                    YkIconButton(
                      icon: Icons.add_circle_outline,
                      label: 'Ajouter une leçon',
                      variant: YkIconButtonVariant.ghost,
                      onPressed: () => _showLeconSheet(moduleId: module.id),
                    ),
                    YkIconButton(
                      icon: Icons.delete_outline,
                      label: 'Supprimer le module',
                      variant: YkIconButtonVariant.ghost,
                      onPressed: () => _supprimerModule(module.id),
                    ),
                  ],
                  AnimatedRotation(
                    turns: ouvert ? 0.5 : 0,
                    duration: YkMotion.normal,
                    curve: YkMotion.brandCurve,
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: YkColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: YkMotion.normal,
              curve: YkMotion.brandCurve,
              child: !ouvert
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(top: YkSpacing.xxs),
                      child: module.lecons.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: YkSpacing.md),
                              child: Text(
                                'Aucune leçon dans ce module.',
                                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                              ),
                            )
                          : Column(
                              children: [for (final lecon in module.lecons) _buildLeconTile(lecon, module.id)],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeconTile(LeconItem lecon, int moduleId) {
    final estCourante = !lecon.estTerminee && lecon.id == _leconCouranteId;
    final Color dotBg;
    final Color dotFg;
    final Widget dotChild;
    if (lecon.estTerminee) {
      dotBg = YkColors.success.withValues(alpha: 0.12);
      dotFg = YkColors.success;
      dotChild = Icon(Icons.check_rounded, color: dotFg, size: 16);
    } else if (estCourante) {
      dotBg = YkColors.accent(context);
      dotFg = YkColors.textOnPrimary;
      dotChild = Icon(Icons.play_arrow_rounded, color: dotFg, size: 16);
    } else {
      dotBg = YkColors.surfaceVariant(context);
      dotFg = YkColors.textTertiary(context);
      dotChild = Text('${lecon.numero}', style: TextStyle(color: dotFg, fontWeight: FontWeight.bold, fontSize: 12));
    }

    return InkWell(
      onTap: () => _ouvrirLecon(lecon),
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: YkSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 13, backgroundColor: dotBg, child: dotChild),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lecon.titre, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
                  if (lecon.description.isNotEmpty)
                    Text(
                      lecon.description,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: YkSpacing.xxs),
                  Wrap(
                    spacing: YkSpacing.xxs,
                    children: [
                      if (lecon.hasPdf) YkBadge(variant: YkBadgeVariant.label, label: 'PDF', color: YkColors.error),
                      if (lecon.hasVideo) YkBadge(variant: YkBadgeVariant.label, label: '▶ VIDÉO', color: YkColors.info),
                    ],
                  ),
                ],
              ),
            ),
            if (_canEdit)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: YkColors.textSecondary(context)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showLeconSheet(moduleId: moduleId, existante: lecon);
                  } else if (val == 'delete') {
                    _supprimerLecon(lecon.id);
                  } else if (val == 'exercices') {
                    widget.onNaviguerExercices?.call(leconId: lecon.id);
                  } else if (val == 'supplements') {
                    _gererSupplements(lecon);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'exercices', child: Text('Exercices')),
                  PopupMenuItem(value: 'supplements', child: Text('Suppléments')),
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              )
            else
              Icon(Icons.chevron_right_rounded, color: YkColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }
}
