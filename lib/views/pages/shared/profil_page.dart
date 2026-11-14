// lib/views/pages/shared/profil_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `AuthRepository`/
// `ClassementRepository` (plus de `http`/`SharedPreferences` bruts) et
// les tokens/composants `Yk*`. Les 2 couleurs en dur (dégradés d'en-tête
// enseignant/apprenant) remplacées par des teintes dérivées du token
// `YkColors.accent`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_guard_metadata.dart' show kEnseignantRoles;
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/classement_repository.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _profil = {};
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _classement = {};
  String _userType = '';

  late final _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final profil = await AuthRepository().getCurrentUserRaw();
      final userType = profil['user_type']?.toString() ?? '';
      // Bug corrigé : le test ad hoc `contains('enseignant') || == 'admin'`
      // ne connaissait pas 'service_client' — cette page l'appelait donc
      // comme un apprenant (mon-score/statut abonnement), un endpoint qui
      // rejette explicitement tout non-apprenant (403), avalé en silence
      // ci-dessous. `kEnseignantRoles` est déjà la table de vérité unique.
      final estEnseignant = kEnseignantRoles.contains(userType);

      final resultats = await Future.wait([
        AuthRepository().profilStats(),
        if (!estEnseignant) ClassementRepository().monScore() else Future.value(<String, dynamic>{}),
      ]);

      if (!mounted) return;
      setState(() {
        _profil = profil;
        _userType = userType;
        _stats = resultats[0];
        _classement = resultats[1];
      });
      _animCtrl.forward();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isEnseignant => kEnseignantRoles.contains(_userType);

  String get _nomComplet {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return _profil['username']?.toString() ?? 'Utilisateur';
  }

  String get _roleLabel {
    switch (_userType) {
      case 'apprenant':
        return 'Apprenant';
      case 'enseignant':
        return 'Enseignant';
      case 'enseignant_principal':
        return 'Enseignant Principal';
      case 'enseignant_cadre':
        return 'Enseignant Cadre';
      case 'enseignant_admin':
        return 'Coordonnateur';
      case 'admin':
        return 'Administrateur';
      case 'service_client':
        return 'Service Client';
      default:
        return 'Utilisateur';
    }
  }

  String get _initials {
    final parts = _nomComplet.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: _loading
          ? _squelette(context)
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [_sliverAppBar(context), SliverToBoxAdapter(child: _corps(context))],
              ),
            ),
    );
  }

  Widget _sliverAppBar(BuildContext context) {
    final avatarUrl = _profil['avatar']?.toString();
    final accent = YkColors.accent(context);

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: accent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _charger)],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.85), accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YkAvatar(imageUrl: avatarUrl, fallbackText: _initials.isEmpty ? '?' : _initials, size: YkAvatarSize.lg),
                    SizedBox(height: YkSpacing.sm),
                    Text(_nomComplet, style: YkTypography.h2(context).copyWith(color: Colors.white)),
                    if ((_profil['email']?.toString() ?? '').isNotEmpty)
                      Text(_profil['email'].toString(), style: YkTypography.bodySm(context).copyWith(color: Colors.white)),
                    SizedBox(height: YkSpacing.xs),
                    YkBadge(
                      variant: YkBadgeVariant.label,
                      label: _roleLabel,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corps(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xl),
      child: Column(
        children: [
          SizedBox(height: YkSpacing.lg),
          _stats_(context),
          if (!_isEnseignant) ...[
            SizedBox(height: YkSpacing.md),
            _bannierePremium(context),
          ],
          SizedBox(height: YkSpacing.lg),
          _infosPerso(context),
          SizedBox(height: YkSpacing.md),
          if (_isEnseignant) _sectionEnseignant(context) else _sectionApprenant(context),
          SizedBox(height: YkSpacing.md),
          if (!_isEnseignant && _classement.isNotEmpty) _classementCard(context),
          SizedBox(height: YkSpacing.md),
          if ((_profil['bio']?.toString() ?? '').isNotEmpty) _bio(context),
          SizedBox(height: YkSpacing.lg),
          _actions(context),
        ],
      ),
    );
  }

  Widget _stats_(BuildContext context) {
    final items = _isEnseignant
        ? [
            (Icons.book_rounded, 'Cours', '${_stats['nb_cours'] ?? 0}'),
            (Icons.article_rounded, 'Leçons', '${_stats['nb_lecons'] ?? 0}'),
            if (_userType == 'enseignant_cadre') (Icons.domain_rounded, 'Dépts', '${_stats['nb_departements'] ?? 0}'),
            (Icons.assignment_rounded, 'Devoirs', '${_stats['nb_devoirs'] ?? 0}'),
          ]
        : [
            (Icons.school_rounded, 'Cours', '${_stats['nb_cours'] ?? 0}'),
            (Icons.assignment_rounded, 'Devoirs', '${_stats['nb_devoirs'] ?? 0}'),
            (Icons.stars_rounded, 'Moyenne', '${(_stats['moyenne'] as num? ?? 0).toStringAsFixed(1)}/20'),
          ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: YkSpacing.sm),
            Expanded(child: YkStatCard(icon: items[i].$1, label: items[i].$2, value: items[i].$3)),
          ],
        ],
      ),
    );
  }

  /// Bannière « Devenir Premium » — bug corrigé (modèle économique non
  /// opérationnel) : aucun point de découverte proactif n'existait hors
  /// des écrans réactifs déjà verrouillés (Devoirs/Forum). Rectification
  /// (Premium désormais PROPRE À CHAQUE DÉPARTEMENT) : cet écran générique
  /// ne connaît aucun département précis pour proposer un achat direct —
  /// renvoie vers le catalogue Cursus, où chaque cours ouvre l'abonnement
  /// de SON département (`ouvrirAbonnementPremium` y exige déjà un
  /// `coursId`). Toujours affichée (pas de statut « déjà abonné » global
  /// à vérifier ici, un apprenant peut être abonné à certains départements
  /// et pas d'autres).
  Widget _bannierePremium(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkCard(
        onTap: () => context.goNamed(AppRoute.dashboardCursus),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: YkColors.accent(context), size: 28),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devenir Premium',
                    style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                  Text(
                    'Découvrez les départements Premium : vidéos, devoirs et forum sans limite.',
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: YkColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _infosPerso(BuildContext context) {
    final lignes = <(IconData, String, String)>[];
    if ((_profil['phone']?.toString() ?? '').isNotEmpty) lignes.add((Icons.phone_rounded, 'Téléphone', _profil['phone'].toString()));
    if ((_profil['email']?.toString() ?? '').isNotEmpty) lignes.add((Icons.email_rounded, 'Email', _profil['email'].toString()));
    if ((_profil['ville']?.toString() ?? '').isNotEmpty) lignes.add((Icons.location_on_rounded, 'Ville', _profil['ville'].toString()));
    if (_isEnseignant && (_profil['whatsapp']?.toString() ?? '').isNotEmpty) {
      lignes.add((Icons.chat_bubble_rounded, 'WhatsApp', _profil['whatsapp'].toString()));
    }
    if (!_isEnseignant) {
      if ((_profil['cursus']?.toString() ?? '').isNotEmpty) lignes.add((Icons.route_rounded, 'Cursus', _profil['cursus'].toString()));
      if ((_profil['niveau']?.toString() ?? '').isNotEmpty) lignes.add((Icons.grade_rounded, 'Niveau', _profil['niveau'].toString()));
      if ((_profil['filiere']?.toString() ?? '').isNotEmpty) lignes.add((Icons.bookmark_rounded, 'Filière', _profil['filiere'].toString()));
    }
    if ((_profil['username']?.toString() ?? '').isNotEmpty) {
      lignes.add((Icons.alternate_email_rounded, "Nom d'utilisateur", _profil['username'].toString()));
    }
    if (lignes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkSection(
        title: 'Informations',
        child: YkCard(
          child: Column(
            children: [
              for (final l in lignes) YkKeyValue(label: l.$2, value: l.$3, icon: l.$1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classementCard(BuildContext context) {
    final score = _classement['score'] as num? ?? 0;
    final rang = _classement['rang'] as int?;
    final total = _classement['total_apprenants'] as int? ?? 0;
    final progression = (_classement['progression'] as num? ?? 0).toDouble();
    final scores = Map<String, dynamic>.from(_classement['scores_categorie'] as Map? ?? {});

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkSection(
        title: 'Classement',
        child: YkCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score total', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                      Text('${score.toStringAsFixed(0)} pts', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rang', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                      Text(
                        rang != null ? '#$rang / $total' : 'Non classé',
                        style: YkTypography.h4(context).copyWith(color: rang != null && rang <= 3 ? YkColors.warning : YkColors.accent(context)),
                      ),
                    ],
                  ),
                ],
              ),
              if (progression != 0) ...[
                SizedBox(height: YkSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    YkBadge(
                      variant: YkBadgeVariant.label,
                      label: '${progression > 0 ? '+' : ''}${progression.toStringAsFixed(0)}%',
                      color: progression > 0 ? YkColors.success : YkColors.error,
                    ),
                  ],
                ),
              ],
              if (scores.isNotEmpty) ...[
                SizedBox(height: YkSpacing.sm),
                Divider(color: YkColors.border(context)),
                SizedBox(height: YkSpacing.xs),
                Wrap(
                  spacing: YkSpacing.xs,
                  runSpacing: YkSpacing.xs,
                  children: [
                    for (final e in scores.entries)
                      YkBadge(variant: YkBadgeVariant.label, label: '${e.key.toString().replaceAll('_', ' ')} : ${(e.value as num).toStringAsFixed(0)} pts', color: YkColors.accent(context)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionEnseignant(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkSection(
        title: 'Activité',
        child: Row(
          children: [
            Expanded(child: _miniCard(context, 'Enseignant\n$_roleLabel', Icons.verified_rounded)),
            SizedBox(width: YkSpacing.sm),
            Expanded(child: _miniCard(context, '${_stats['nb_cours'] ?? 0} cours\nactifs', Icons.book_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _sectionApprenant(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkSection(
        title: 'Parcours',
        child: Row(
          children: [
            Expanded(child: _miniCard(context, _profil['cursus']?.toString() ?? 'Non défini', Icons.route_rounded)),
            SizedBox(width: YkSpacing.sm),
            Expanded(child: _miniCard(context, _profil['niveau']?.toString() ?? 'Non défini', Icons.grade_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(BuildContext context, String texte, IconData icon) {
    return YkCard(
      variant: YkCardVariant.outlined,
      accentColor: YkColors.accent(context),
      child: Row(
        children: [
          Icon(icon, color: YkColors.accent(context), size: 18),
          SizedBox(width: YkSpacing.xs),
          Expanded(child: Text(texte, style: YkTypography.bodySm(context).copyWith(color: YkColors.accent(context), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _bio(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: YkSection(
        title: 'À propos',
        child: YkCard(
          child: Text(_profil['bio'].toString(), style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context), height: 1.6)),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      child: Column(
        children: [
          YkButton(
            label: 'Modifier mon profil',
            icon: Icons.edit_rounded,
            onPressed: () => context.pushNamed(AppRoute.profileEdit).then((_) => _charger()),
          ),
          SizedBox(height: YkSpacing.sm),
          YkButton(
            label: 'Paramètres',
            icon: Icons.settings_rounded,
            variant: YkButtonVariant.secondary,
            onPressed: () => context.pushNamed(AppRoute.settings),
          ),
        ],
      ),
    );
  }

  Widget _squelette(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 240, child: YkSkeleton.card(height: 240)),
        SizedBox(height: YkSpacing.lg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
          child: YkSkeleton.list(itemCount: 3, itemHeight: 100),
        ),
      ],
    );
  }
}
