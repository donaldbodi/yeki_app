// lib/views/pages/apprenants/repetiteurs_page.dart
//
// Refondu en P11.7 (rituel P5.0) : bascule vers `RepetiteurRepository`/
// `AuthRepository`/`PaiementRepository` (plus de `http`/`SharedPreferences`
// bruts) et les tokens/composants `Yk*`.
//
// **Bug WhatsApp corrigé** : le bouton contactait `r['whatsapp']` (le
// numéro PROPRE de l'enseignant répétiteur) au lieu du numéro unique du
// Service Client — confirmé exactement comme décrit par le ticket. Utilise
// désormais `ParametresPublics.whatsappServiceClient` (`GET
// /parametres/publics/`, déjà consommé ailleurs par le flux de paiement
// manuel — même source, pas une nouvelle). Le message envoyé précise
// toujours le nom de l'enseignant visé, pour que le Service Client sache
// qui orienter.
//
// Le tarif "5000 FCFA/mois" était aussi figé en dur dans le message
// WhatsApp (règle 3), indépendamment du vrai tarif du répétiteur — corrigé
// pour utiliser `r['tarif']` (déjà lu par l'API, déjà affiché dans la
// carte) au lieu d'un texte fixe.
//
// Simplification des filtres (demande explicite) : "Matière" (texte
// libre), "Niveau" et "Matières populaires" retirés — la matière est
// désormais celle du COURS d'où l'écran est ouvert (`coursId`, transmis
// en paramètre de route depuis `lecons_cours.dart`), le niveau celui du
// PROFIL de l'apprenant connecté — les deux résolus côté backend
// (`RepetiteursSearchView`), jamais saisis ici. Seul le filtre "Ville"
// reste, sur une VRAIE liste fermée des villes du Cameroun
// (`villes_cameroun.dart`, nouvelle — n'existait nulle part avant).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/constants/villes_cameroun.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/repositories/repetiteur_repository.dart';

class RepetiteursPage extends StatefulWidget {
  const RepetiteursPage({super.key, this.coursId});

  /// Cours d'où l'écran est ouvert — détermine la matière recherchée
  /// côté backend. `null` = recherche sans contexte de cours (aucun
  /// résultat tant qu'aucune ville n'affine, le backend exige `matiere`
  /// ou `cours_id`).
  final String? coursId;

  @override
  State<RepetiteursPage> createState() => _RepetiteursPageState();
}

class _RepetiteursPageState extends State<RepetiteursPage> {
  final _repetiteurRepo = RepetiteurRepository();
  final _paiementRepo = PaiementRepository();

  String? _ville;

  List<Map<String, dynamic>> _repetiteurs = [];
  bool _loading = false;
  bool _chargementInitial = true;
  bool _aRecherche = false;
  String? _erreur;
  String? _whatsappServiceClient;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    try {
      final parametres = await _paiementRepo.parametresPublics();
      if (mounted) setState(() => _whatsappServiceClient = parametres.whatsappServiceClient);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementInitial = false);
    }
    // Sans `coursId` (ouverture hors contexte d'un cours), le backend exige
    // `matiere`/`cours_id` — rien à chercher tant que l'apprenant n'a pas au
    // moins choisi une ville.
    if (widget.coursId != null) await _rechercher();
  }

  Future<void> _rechercher() async {
    // La matière recherchée est dérivée de `coursId` côté backend — sans
    // lui, rien à chercher (le backend exige `matiere` ou `cours_id`).
    if (widget.coursId == null) return;
    setState(() {
      _loading = true;
      _erreur = null;
      _aRecherche = true;
    });
    try {
      final resultats = await _repetiteurRepo.search({
        if (widget.coursId != null) 'cours_id': widget.coursId!,
        if (_ville != null) 'ville': _ville!,
      });
      if (mounted) {
        setState(() {
          _repetiteurs = resultats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erreur = 'Erreur de connexion.';
        });
      }
    }
  }

  Future<void> _contacterServiceClient(String nomEnseignant, String matiere, dynamic tarif) async {
    final numero = (_whatsappServiceClient ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (numero.isEmpty) {
      YkSnack.error(context, 'Numéro du service client indisponible pour le moment.');
      return;
    }
    final ville = _ville ?? 'ma ville';
    final tarifLabel = tarif != null ? '$tarif FCFA/mois' : 'à confirmer';
    final message = Uri.encodeComponent(
      'Bonjour,\n\n'
      'Je souhaite prendre des cours particuliers en $matiere avec $nomEnseignant via Yéki.\n'
      'Ville : $ville\n'
      'Tarif affiché : $tarifLabel.\n\n'
      'Pouvez-vous m\'aider à organiser ces cours ?\n\n'
      'Cordialement.',
    );
    final url = Uri.parse('https://wa.me/$numero?text=$message');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) YkSnack.error(context, "Impossible d'ouvrir WhatsApp. Vérifiez que l'application est installée.");
      }
    } catch (_) {
      if (mounted) YkSnack.error(context, "Impossible d'ouvrir WhatsApp.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: const YkGradientAppBar(title: 'Trouver un répétiteur'),
      body: _chargementInitial
          ? Center(child: YkProgress(shape: YkProgressShape.circular))
          : Column(
              children: [
                _formulaire(context),
                Expanded(
                  child: _loading
                      ? Center(child: YkProgress(shape: YkProgressShape.circular))
                      : _erreur != null && _repetiteurs.isEmpty
                          ? _etatErreur(context)
                          : _repetiteurs.isEmpty && _aRecherche
                              ? _etatVide(context)
                              : _listeResultats(context),
                ),
              ],
            ),
    );
  }

  Widget _formulaire(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.md),
      decoration: BoxDecoration(color: YkColors.surface(context), border: Border(bottom: BorderSide(color: YkColors.border(context)))),
      child: Row(
        children: [
          Expanded(
            child: YkDropdown<String>(
              label: 'Ville',
              value: _ville,
              items: [for (final v in villesCameroun) YkDropdownItem(value: v, label: v)],
              onChanged: (v) {
                setState(() => _ville = v);
                _rechercher();
              },
            ),
          ),
          SizedBox(width: YkSpacing.sm),
          YkButton(label: 'Rechercher', onPressed: _rechercher),
        ],
      ),
    );
  }

  Widget _listeResultats(BuildContext context) {
    if (_repetiteurs.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      padding: EdgeInsets.all(YkSpacing.md),
      itemCount: _repetiteurs.length,
      separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
      itemBuilder: (context, index) => _carteRepetiteur(context, _repetiteurs[index]),
    );
  }

  Widget _carteRepetiteur(BuildContext context, Map<String, dynamic> r) {
    final nom = r['nom'] as String? ?? 'Enseignant';
    final matiere = r['matiere'] as String? ?? '';
    final tarif = r['tarif'];
    final aWhatsapp = (_whatsappServiceClient ?? '').isNotEmpty;

    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              YkAvatar(imageUrl: r['avatar'] as String?, fallbackText: nom, size: YkAvatarSize.md),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    if (r['username'] != null) Text('@${r['username']}', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                    if ((r['ville'] as String?)?.isNotEmpty ?? false)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: YkColors.textTertiary(context)),
                          Text(r['ville'] as String, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                        ],
                      ),
                  ],
                ),
              ),
              if (tarif != null) YkBadge(variant: YkBadgeVariant.label, label: '$tarif F/mois', color: YkColors.warning),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.xs,
            children: [
              YkBadge(variant: YkBadgeVariant.label, label: matiere, color: YkColors.accent(context)),
              YkBadge(variant: YkBadgeVariant.label, label: 'Disponible', color: YkColors.success),
            ],
          ),
          SizedBox(height: YkSpacing.md),
          YkButton(
            label: aWhatsapp ? 'Contacter le service client' : 'Numéro indisponible',
            icon: Icons.chat_rounded,
            onPressed: aWhatsapp ? () => _contacterServiceClient(nom, matiere, tarif) : null,
          ),
        ],
      ),
    );
  }

  Widget _etatVide(BuildContext context) => YkEmptyState(
        icon: Icons.person_search_rounded,
        title: 'Aucun répétiteur trouvé',
        message: 'Essayez une autre ville ou vérifiez votre connexion.',
      );

  Widget _etatErreur(BuildContext context) => YkEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erreur',
        message: _erreur ?? '',
        actionLabel: 'Réessayer',
        onAction: _rechercher,
      );
}
