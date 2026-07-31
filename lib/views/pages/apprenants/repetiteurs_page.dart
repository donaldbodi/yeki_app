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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/repositories/repetiteur_repository.dart';

class RepetiteursPage extends StatefulWidget {
  const RepetiteursPage({super.key});

  @override
  State<RepetiteursPage> createState() => _RepetiteursPageState();
}

class _RepetiteursPageState extends State<RepetiteursPage> {
  final _repetiteurRepo = RepetiteurRepository();
  final _paiementRepo = PaiementRepository();

  final _searchCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  final List<String> _matieresPopulaires = const [
    'Mathématiques', 'Physique', 'Chimie', 'SVT',
    'Informatique', 'Français', 'Anglais', 'Histoire-Géo',
  ];

  List<Map<String, dynamic>> _repetiteurs = [];
  bool _loading = false;
  bool _chargementInitial = true;
  String? _matiereSelectionnee;
  String? _erreur;
  String? _whatsappServiceClient;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _niveauCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialiser() async {
    try {
      final profil = await AuthRepository().getCurrentUser();
      final parametres = await _paiementRepo.parametresPublics();
      if (mounted) {
        setState(() {
          if (profil.niveau?.isNotEmpty ?? false) _niveauCtrl.text = profil.niveau!;
          if (profil.ville?.isNotEmpty ?? false) _villeCtrl.text = profil.ville!;
          _whatsappServiceClient = parametres.whatsappServiceClient;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementInitial = false);
    }
  }

  Future<void> _rechercher(String matiere) async {
    if (matiere.trim().isEmpty) {
      YkSnack.error(context, 'Veuillez entrer une matière.');
      return;
    }
    setState(() {
      _loading = true;
      _erreur = null;
      _matiereSelectionnee = matiere;
    });
    try {
      final resultats = await _repetiteurRepo.search({
        'matiere': matiere,
        if (_villeCtrl.text.trim().isNotEmpty) 'ville': _villeCtrl.text.trim(),
        if (_niveauCtrl.text.trim().isNotEmpty) 'niveau': _niveauCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _repetiteurs = resultats;
          _loading = false;
        });
        if (resultats.isEmpty) YkSnack.info(context, 'Aucun répétiteur trouvé pour "$matiere".');
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
    final niveau = _niveauCtrl.text.trim().isNotEmpty ? _niveauCtrl.text.trim() : 'mon niveau';
    final ville = _villeCtrl.text.trim().isNotEmpty ? _villeCtrl.text.trim() : 'ma ville';
    final tarifLabel = tarif != null ? '$tarif FCFA/mois' : 'à confirmer';
    final message = Uri.encodeComponent(
      'Bonjour,\n\n'
      'Je souhaite prendre des cours particuliers en $matiere avec $nomEnseignant via Yéki.\n'
      'Niveau : $niveau\n'
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
      appBar: AppBar(title: const Text('Trouver un répétiteur')),
      body: _chargementInitial
          ? Center(child: YkProgress(shape: YkProgressShape.circular))
          : Column(
              children: [
                _formulaire(context),
                _matieresPopulairesWidget(context),
                Expanded(
                  child: _loading
                      ? Center(child: YkProgress(shape: YkProgressShape.circular))
                      : _erreur != null && _repetiteurs.isEmpty
                          ? _etatErreur(context)
                          : _repetiteurs.isEmpty && _matiereSelectionnee != null
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rechercher un répétiteur', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(flex: 2, child: YkTextField(controller: _searchCtrl, type: YkTextFieldType.search, hint: 'Matière…', onSubmitted: _rechercher)),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: YkTextField(controller: _niveauCtrl, hint: 'Niveau…')),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(child: YkTextField(controller: _villeCtrl, hint: 'Ville…')),
              SizedBox(width: YkSpacing.sm),
              YkButton(label: 'Rechercher', onPressed: () => _rechercher(_searchCtrl.text)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matieresPopulairesWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.sm, YkSpacing.md, YkSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matières populaires', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
          SizedBox(height: YkSpacing.xs),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xs,
            children: [
              for (final matiere in _matieresPopulaires)
                YkChip(
                  label: matiere,
                  variant: YkChipVariant.filter,
                  selected: _matiereSelectionnee == matiere,
                  onPressed: () {
                    _searchCtrl.text = matiere;
                    _rechercher(matiere);
                  },
                ),
            ],
          ),
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
        message: 'Essayez une autre matière ou vérifiez votre connexion.',
      );

  Widget _etatErreur(BuildContext context) => YkEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erreur',
        message: _erreur ?? '',
        actionLabel: 'Réessayer',
        onAction: () => _rechercher(_searchCtrl.text),
      );
}
