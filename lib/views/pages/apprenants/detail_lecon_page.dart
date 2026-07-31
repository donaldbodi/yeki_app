// lib/views/pages/apprenants/detail_lecon_page.dart
//
// Refondu en P11.4 (rituel P5.0) : l'ancienne page scrollable classique
// cède la place à `YkLessonFeed` (flux vertical immersif « style TikTok
// à la Yéki », CDC_DESIGN §5.3.5 — composant prêt mais jamais câblé avant
// ce ticket, voir `lib/core/design/components/media/yk_lesson_feed.dart`).
//
// Gating gratuit/premium : `estAccessible` (dérivé par l'appelant de
// `DepartementItem.estAccessible`, PAS un abonnement séparé — décision
// utilisateur explicite du 2026-07-29, aucun autre signal d'accès réel
// n'existe côté backend). Accessible → vidéo ; non accessible → pas de
// vidéo, le bouton "Support PDF" (toujours visible si la leçon a un PDF)
// reste l'unique façon de consulter le contenu, via `LectureLeconPage` et
// son filigrane dynamique.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/services/download_manager.dart';
import 'package:yeki/views/pages/apprenants/lecon_models.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

String _urlComplete(String? chemin) {
  if (chemin == null || chemin.isEmpty) return '';
  return chemin.startsWith('http') ? chemin : '${ApiConstants.baseUrl}$chemin';
}

class DetailLeconPage extends StatefulWidget {
  final int leconId;
  final int coursId;
  final String coursTitre;
  final int coursColor;
  final bool estAccessible;

  const DetailLeconPage({
    super.key,
    required this.leconId,
    required this.coursId,
    required this.coursTitre,
    required this.coursColor,
    this.estAccessible = true,
  });

  @override
  State<DetailLeconPage> createState() => _DetailLeconPageState();
}

class _DetailLeconPageState extends State<DetailLeconPage> {
  final _repo = CoursRepository();
  bool _loading = true;
  List<LeconItem> _lecons = [];
  int _indexInitial = 0;
  final Set<int> _likees = {};
  final Set<int> _favorites = {};

  Color get _accent => Color(widget.coursColor);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _charger();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final modules = await _repo.modules(widget.coursId);
      final lecons = modules.tousLesLecons();
      final index = lecons.indexWhere((l) => l.id == widget.leconId);
      if (mounted) {
        setState(() {
          _lecons = lecons;
          _indexInitial = index >= 0 ? index : 0;
        });
      }
      if (lecons.isNotEmpty) {
        await _repo.marquerLecon(lecons[_indexInitial].id, 10);
      }
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLike(String leconIdStr) async {
    final leconId = int.parse(leconIdStr);
    final etaitLikee = _likees.contains(leconId);
    setState(() => etaitLikee ? _likees.remove(leconId) : _likees.add(leconId));
    try {
      final liked = await _repo.toggleLike(leconId);
      if (mounted) setState(() => liked ? _likees.add(leconId) : _likees.remove(leconId));
    } catch (_) {
      if (mounted) setState(() => etaitLikee ? _likees.add(leconId) : _likees.remove(leconId));
    }
  }

  void _onFavorite(String leconIdStr) {
    // Aucun favori persistant côté backend (recherche exhaustive,
    // confirmée absente) — état local à la session, pas fabriqué comme
    // une fonctionnalité persistée qui n'existe pas (règle 3).
    final leconId = int.parse(leconIdStr);
    setState(() => _favorites.contains(leconId) ? _favorites.remove(leconId) : _favorites.add(leconId));
  }

  void _onPreoccupation(String leconIdStr) {
    final lecon = _lecons.firstWhere((l) => l.id.toString() == leconIdStr);
    YkSheet.show<void>(
      context: context,
      title: 'Une question sur cette leçon ?',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.psychology_rounded, color: _accent),
            title: const Text('Discuter avec Yéki IA'),
            onTap: () {
              Navigator.pop(ctx);
              context.pushNamed(
                AppRoute.iaChat,
                pathParameters: {'coursId': widget.coursId.toString()},
                queryParameters: {
                  'coursTitre': widget.coursTitre,
                  'sourceInitiale': 'lecon',
                  'sourceId': lecon.id.toString(),
                  'sourceTitreInit': lecon.titre,
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.forum_rounded, color: YkColors.info),
            title: const Text('Poser au forum'),
            onTap: () {
              Navigator.pop(ctx);
              ouvrirPreoccupation(
                context: context,
                source: 'lecon',
                leconId: lecon.id,
                leconTitre: lecon.titre,
                coursId: widget.coursId,
                coursTitre: widget.coursTitre,
                coursColor: widget.coursColor,
              );
            },
          ),
        ],
      ),
    );
  }

  void _onShare(String leconIdStr) {
    final lecon = _lecons.firstWhere((l) => l.id.toString() == leconIdStr);
    Clipboard.setData(ClipboardData(text: '${widget.coursTitre} — ${lecon.titre} (Yéki)'));
    YkSnack.success(context, 'Lien copié dans le presse-papiers.');
  }

  void _onDownload(String leconIdStr) {
    final lecon = _lecons.firstWhere((l) => l.id.toString() == leconIdStr);
    final url = lecon.hasVideo ? _urlComplete(lecon.videoUrl) : _urlComplete(lecon.pdfUrl);
    if (url.isEmpty) {
      YkSnack.info(context, 'Aucun fichier à télécharger pour cette leçon.');
      return;
    }
    DownloadManager().downloadFile(
      url: url,
      fileId: 'lecon_${lecon.id}',
      fileName: '${lecon.titre}.${lecon.hasVideo ? 'mp4' : 'pdf'}',
      fileType: lecon.hasVideo ? 'video' : 'pdf',
      onComplete: () => mounted ? YkSnack.success(context, 'Téléchargement terminé.') : null,
      onError: (e) => mounted ? YkSnack.error(context, e) : null,
    );
    YkSnack.info(context, 'Téléchargement démarré…');
  }

  void _ouvrirPdf(LeconItem lecon) {
    context.pushNamed(
      AppRoute.leconLecture,
      pathParameters: {'leconId': lecon.id.toString(), 'coursId': widget.coursId.toString()},
      queryParameters: {'coursTitre': widget.coursTitre, 'coursColor': widget.coursColor.toString()},
    );
  }

  Future<void> _onSupplements(String leconIdStr) async {
    final lecon = _lecons.firstWhere((l) => l.id.toString() == leconIdStr);
    List<SupplementCoursItem> supplements;
    try {
      supplements = await _repo.supplements(widget.coursId, leconId: lecon.id);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement des suppléments.');
      return;
    }
    if (!mounted) return;
    YkSheet.show<void>(
      context: context,
      title: 'Suppléments',
      bodyBuilder: (ctx) => supplements.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: YkSpacing.lg),
              child: Text('Aucun supplément pour cette leçon.', style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textSecondary(ctx))),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in supplements)
                  YkCard(
                    onTap: s.lienAOuvrir == null ? null : () => launchUrl(Uri.parse(s.lienAOuvrir!), mode: LaunchMode.externalApplication),
                    child: Row(
                      children: [
                        Icon(_iconeSupplement(s.typeContenu), color: _accent),
                        SizedBox(width: YkSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.titre, style: YkTypography.label(ctx).copyWith(color: YkColors.textPrimary(ctx))),
                              if (s.description.isNotEmpty)
                                Text(s.description, style: YkTypography.caption(ctx).copyWith(color: YkColors.textSecondary(ctx)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded, size: 16, color: YkColors.textTertiary(ctx)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _iconeSupplement(String type) => switch (type) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'ppt' => Icons.slideshow_outlined,
    'lien' => Icons.link_rounded,
    _ => Icons.attachment_rounded,
  };

  void _naviguerVersExercices(LeconItem lecon) {
    context.pushNamed(
      AppRoute.coursDetail,
      pathParameters: {'coursId': widget.coursId.toString()},
      queryParameters: {
        'titre': widget.coursTitre,
        'coursColor': widget.coursColor.toString(),
        'isPremium': widget.estAccessible.toString(),
        'tab': '1',
        'leconId': lecon.id.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: YkProgress(shape: YkProgressShape.circular, color: _accent)));
    }
    if (_lecons.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: YkEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Leçon introuvable',
          message: 'Cette leçon a peut-être été retirée.',
          actionLabel: 'Retour',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          YkLessonFeed(
            items: [
              for (final lecon in _lecons)
                YkLessonFeedItem(
                  id: lecon.id.toString(),
                  isLiked: _likees.contains(lecon.id),
                  isFavorite: _favorites.contains(lecon.id),
                  player: _LeconFeedCard(
                    lecon: lecon,
                    accent: _accent,
                    estAccessible: widget.estAccessible,
                    onOuvrirPdf: () => _ouvrirPdf(lecon),
                    onExercices: () => _naviguerVersExercices(lecon),
                  ),
                ),
            ],
            onLike: _onLike,
            onFavorite: _onFavorite,
            onPreoccupation: _onPreoccupation,
            onShare: _onShare,
            onDownload: _onDownload,
            onSupplements: _onSupplements,
            onPageChanged: (i) => _repo.marquerLecon(_lecons[i].id, 10),
          ),
          Positioned(
            top: YkSpacing.md,
            left: YkSpacing.md,
            child: SafeArea(
              child: YkIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Retour',
                variant: YkIconButtonVariant.filled,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeconFeedCard extends StatelessWidget {
  const _LeconFeedCard({
    required this.lecon,
    required this.accent,
    required this.estAccessible,
    required this.onOuvrirPdf,
    required this.onExercices,
  });

  final LeconItem lecon;
  final Color accent;
  final bool estAccessible;
  final VoidCallback onOuvrirPdf;
  final VoidCallback onExercices;

  @override
  Widget build(BuildContext context) {
    final montrerVideo = estAccessible && lecon.hasVideo;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: YkSpacing.xxl),
            Expanded(
              child: montrerVideo
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
                      child: Center(child: YkVideoPlayer(videoUrl: _urlComplete(lecon.videoUrl))),
                    )
                  : _buildPlaceholder(context),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.sm, YkSpacing.xxl * 2, YkSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        lecon.moduleTitre.toUpperCase(),
                        style: YkTypography.caption(context).copyWith(color: Colors.white70, letterSpacing: 1),
                      ),
                      if (lecon.estTerminee) ...[
                        SizedBox(width: YkSpacing.xs),
                        YkBadge(variant: YkBadgeVariant.label, label: 'Terminée', color: YkColors.success),
                      ],
                    ],
                  ),
                  SizedBox(height: YkSpacing.xs),
                  Text(lecon.titre, style: YkTypography.h3(context).copyWith(color: Colors.white)),
                  if (lecon.description.isNotEmpty) ...[
                    SizedBox(height: YkSpacing.xs),
                    Text(
                      lecon.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: YkTypography.bodySm(context).copyWith(color: Colors.white70),
                    ),
                  ],
                  SizedBox(height: YkSpacing.md),
                  Row(
                    children: [
                      if (lecon.hasPdf)
                        Expanded(
                          child: YkButton(
                            label: 'Support PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            variant: YkButtonVariant.secondary,
                            onPressed: onOuvrirPdf,
                          ),
                        ),
                      if (lecon.hasPdf) SizedBox(width: YkSpacing.sm),
                      Expanded(
                        child: YkButton(label: 'Exercices', icon: Icons.assignment_outlined, onPressed: onExercices),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.35), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(YkRadius.lg),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              !estAccessible ? Icons.lock_outline_rounded : Icons.menu_book_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              !estAccessible ? 'Accédez à cette formation pour la vidéo' : 'Pas de vidéo pour cette leçon',
              textAlign: TextAlign.center,
              style: YkTypography.bodySm(context).copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
