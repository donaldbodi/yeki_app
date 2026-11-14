// lib/views/pages/apprenants/details_question_forum.dart
//
// Refondu en P10.5 (migration mécanique, rituel P5.0) : bascule vers
// `ForumRepository` (plus de `http`/`SharedPreferences` bruts) et vers les
// tokens/composants `Yk*` (plus de `YekiColors`/`YekiRadius`/`YekiButton`/
// `YekiLoader`, dépréciés). Structure et comportement inchangés —
// migration mécanique, pas une réinvention visuelle (décision explicite,
// vu le volume et le risque de régression sans QA visuelle possible).
//
// `_selectedImage` passe de `File` (dart:io) à `Uint8List` : `File` plante
// sur le web (`Unsupported operation: _Namespace`, voir le commentaire de
// tête de `YkPickedFile` dans `yk_file_upload.dart`) — même bug déjà
// corrigé ailleurs dans le projet, corrigé ici aussi au passage.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/forum_repository.dart';
import 'package:yeki/services/forum_realtime_service.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/widgets/forum_audio_player.dart';
import 'package:yeki/widgets/forum_style.dart';

String _formatTimeAgo(String iso) {
  try {
    return timeago.format(DateTime.parse(iso).toLocal(), locale: 'fr');
  } catch (_) {
    return '';
  }
}

String _getInitials(String nom, String username) {
  final n = nom.isNotEmpty ? nom : username;
  if (n.isEmpty) return '?';
  final parts = n.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return n[0].toUpperCase();
}

// ════════════════════════════════════════════════════════════
// PAGE DÉTAIL D'UNE QUESTION
// ════════════════════════════════════════════════════════════
class DetailQuestionForumPage extends StatefulWidget {
  final int questionId;
  final QForum? question;
  final int? coursColor;

  const DetailQuestionForumPage({super.key, required this.questionId, this.question, this.coursColor});

  @override
  State<DetailQuestionForumPage> createState() => _DetailQuestionForumPageState();
}

class _DetailQuestionForumPageState extends State<DetailQuestionForumPage> with WidgetsBindingObserver {
  final _repo = ForumRepository();
  bool _loading = true;
  QForum? _question;
  ForumRealtimeConnexion? _tempsReel;
  Timer? _rechargeDifferee;
  final TextEditingController _reponseCtrl = TextEditingController();
  bool _sending = false;
  Uint8List? _selectedImageBytes;

  Color _accentColor(BuildContext context) =>
      widget.coursColor != null ? Color(widget.coursColor!) : YkColors.accent(context);

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    // Bug corrigé : `widget.question` (passé par `forum_page.dart` en
    // `extra`) vient de `QuestionForumListSerializer`, qui n'inclut PAS
    // `reponses` (seul `QuestionForumDetailSerializer` le fait) — utilisé
    // ici uniquement comme affichage transitoire le temps du chargement
    // réel (évite un écran vide), JAMAIS comme donnée finale : sans ce
    // rechargement, les réponses n'apparaissaient jamais à l'ouverture.
    if (widget.question != null) {
      _question = widget.question;
      _loading = false;
      _loadQuestion(silent: true);
    } else {
      _loadQuestion();
    }
    if (ApiConstants.forumRealtimeEnabled) {
      WidgetsBinding.instance.addObserver(this);
      // Salle globale : elle reçoit les événements de toutes les questions,
      // et la page peut être ouverte sans connaître le cours (lien direct).
      _tempsReel = ForumRealtimeConnexion(room: 'global', onEvenement: _surEvenementForum)
        ..demarrer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rechargeDifferee?.cancel();
    _tempsReel?.arreter();
    _reponseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tempsReel?.demarrer();
      _loadQuestion(silent: true, compterVue: false);
    } else {
      _tempsReel?.arreter();
    }
  }

  void _surEvenementForum(ForumEvenement evenement) {
    if (evenement.questionId != widget.questionId) return;
    // Regroupe les rafales d'événements en un seul rechargement.
    _rechargeDifferee?.cancel();
    _rechargeDifferee = Timer(
      const Duration(seconds: 1),
      () => _loadQuestion(silent: true, compterVue: false),
    );
  }

  /// [silent] : `true` quand un aperçu transitoire (`widget.question`,
  /// sans réponses) est déjà affiché — évite de reclignoter un état de
  /// chargement plein écran, `_question` est simplement remplacé dès que
  /// les données fraîches (avec réponses) arrivent.
  Future<void> _loadQuestion({bool silent = false, bool compterVue = true}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _repo.getQuestion(widget.questionId, compterVue: compterVue);
      if (!mounted) return;
      setState(() {
        _question = QForum.fromJson(data);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!silent) {
        setState(() => _loading = false);
        if (mounted) ErrorHandler.showError(context, e.message);
      }
    } catch (e) {
      debugPrint('DetailsQuestionForum._loadQuestion() — exception non-ApiException : ${e.runtimeType} : $e');
      if (!silent) {
        setState(() => _loading = false);
        if (mounted) ErrorHandler.showError(context, 'Erreur de chargement: $e');
      }
    }
  }

  Future<void> _envoyerReponse() async {
    final texte = _reponseCtrl.text.trim();
    if (texte.isEmpty && _selectedImageBytes == null) {
      ErrorHandler.showError(context, 'Veuillez écrire une réponse ou ajouter une image.');
      return;
    }

    setState(() => _sending = true);
    try {
      await _repo.repondre(
        questionId: widget.questionId,
        contenu: texte,
        imageBytes: _selectedImageBytes,
      );
      _reponseCtrl.clear();
      setState(() => _selectedImageBytes = null);
      if (mounted) ErrorHandler.showSuccess(context, 'Réponse envoyée avec succès !');
      await _loadQuestion();
    } on ApiException catch (e) {
      if (mounted) ErrorHandler.showError(context, e.message);
    } catch (e) {
      debugPrint('Erreur envoi réponse: $e');
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _likerReponse(RepForum reponse) async {
    try {
      final data = await _repo.liker(reponse.id);
      setState(() {
        reponse.monLike = data['liked'] ?? false;
        reponse.nbLikes = data['nb_likes'] ?? reponse.nbLikes;
      });
    } catch (e) {
      debugPrint('Erreur like: $e');
    }
  }

  Future<void> _marquerSolution(RepForum reponse) async {
    try {
      await _repo.marquerSolution(reponse.id);
      if (mounted) ErrorHandler.showSuccess(context, 'Réponse marquée comme solution !');
      await _loadQuestion();
    } catch (e) {
      debugPrint('Erreur marquer solution: $e');
    }
  }

  Future<void> _resoudreQuestion() async {
    try {
      await _repo.resoudreQuestion(widget.questionId);
      if (mounted) ErrorHandler.showSuccess(context, 'Question marquée comme résolue !');
      await _loadQuestion();
    } catch (e) {
      debugPrint('Erreur résoudre question: $e');
    }
  }

  Future<void> _pickerImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _selectedImageBytes = bytes);
    }
  }

  void _navigateToSource() {
    if (_question == null) return;
    final q = _question!;
    final accent = _accentColor(context);

    if (q.source == 'lecon' && q.leconId != null && q.coursId != null) {
      context.pushNamed(
        AppRoute.leconLecture,
        pathParameters: {'leconId': q.leconId!.toString(), 'coursId': q.coursId!.toString()},
        queryParameters: {
          'coursTitre': q.coursTitre,
          'coursColor': (widget.coursColor ?? accent.toARGB32()).toString(),
        },
      );
    } else if (q.source == 'exercice' && q.exerciceId != null && q.coursId != null) {
      context.pushNamed(
        AppRoute.exercicePasser,
        pathParameters: {'exerciceId': q.exerciceId!.toString()},
        queryParameters: {'coursId': q.coursId!.toString(), 'coursTitre': q.coursTitre},
      );
    } else if (q.source == 'devoir' && q.devoirId != null && q.coursId != null) {
      context.pushNamed(
        AppRoute.devoirResultat,
        pathParameters: {'devoirId': q.devoirId!.toString()},
        queryParameters: {
          'titre': q.devoirTitre,
          'coursId': q.coursId!.toString(),
          'coursTitre': q.coursTitre,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (_question != null && _question!.source != 'libre')
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: _navigateToSource,
              tooltip: 'Retour à la source',
            ),
          if (_question != null && !_question!.estResolue)
            IconButton(
              icon: Icon(Icons.check_circle_outline_rounded, color: YkColors.success),
              onPressed: _resoudreQuestion,
              tooltip: 'Marquer comme résolue',
            ),
        ],
      ),
      body: _loading
          ? Center(child: YkProgress(shape: YkProgressShape.circular))
          : _question == null
          ? _buildErrorState(context)
          : _buildContent(context),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return YkEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Question introuvable',
      message: "Cette question n'existe plus ou a été retirée.",
      actionLabel: 'Retour',
      onAction: () => Navigator.pop(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final q = _question!;
    final color = sourcePreoccupationCouleur(context, q.source);
    final icon = sourcePreoccupationIcone(q.source);
    final label = sourceLabelCourt(q.source);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YkCard(
                  variant: YkCardVariant.filled,
                  accentColor: color,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      SizedBox(width: YkSpacing.sm),
                      Text(
                        label,
                        style: YkTypography.label(context).copyWith(color: color),
                      ),
                      if (q.source != 'libre' && q.contexteLabel.isNotEmpty) ...[
                        SizedBox(width: YkSpacing.xs),
                        Flexible(
                          child: Text(
                            q.contexteLabel,
                            style: YkTypography.bodySm(context).copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (q.estResolue)
                        YkBadge(variant: YkBadgeVariant.label, label: 'Résolue', color: YkColors.success),
                    ],
                  ),
                ),
                SizedBox(height: YkSpacing.md),
                YkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.contenu,
                        style: YkTypography.bodyMd(
                          context,
                        ).copyWith(color: YkColors.textPrimary(context)),
                      ),
                      if (q.imageUrl != null) ...[
                        SizedBox(height: YkSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(YkRadius.md),
                          child: Image.network(
                            q.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      if (q.audioUrl != null) ...[
                        SizedBox(height: YkSpacing.sm),
                        ForumAudioPlayer(audioUrl: q.audioUrl!),
                      ],
                      SizedBox(height: YkSpacing.sm),
                      Row(
                        children: [
                          _buildAvatar(context, q.auteurNom, q.auteurUsername, q.auteurEstEnseignant, color, 20, avatarUrl: q.auteurAvatarUrl),
                          SizedBox(width: YkSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                                  style: YkTypography.label(
                                    context,
                                  ).copyWith(color: YkColors.textSecondary(context)),
                                ),
                                if (q.auteurEstEnseignant)
                                  Text(
                                    'Enseignant',
                                    style: YkTypography.caption(
                                      context,
                                    ).copyWith(color: _accentColor(context), fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimeAgo(q.creeLe),
                            style: YkTypography.caption(
                              context,
                            ).copyWith(color: YkColors.textTertiary(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: YkSpacing.lg),
                if (q.reponses.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.forum_rounded, size: 18, color: YkColors.textSecondary(context)),
                      SizedBox(width: YkSpacing.xs),
                      Text(
                        '${q.reponses.length} réponse${q.reponses.length > 1 ? 's' : ''}',
                        style: YkTypography.label(
                          context,
                        ).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ],
                  ),
                  SizedBox(height: YkSpacing.sm),
                  ...q.reponses.map((r) => _buildReponseCard(context, r, q)),
                ] else
                  YkCard(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 32,
                            color: YkColors.textTertiary(context),
                          ),
                          SizedBox(height: YkSpacing.xs),
                          Text(
                            'Aucune réponse pour le moment',
                            style: YkTypography.bodySm(
                              context,
                            ).copyWith(color: YkColors.textTertiary(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildReponseInput(context),
      ],
    );
  }

  Widget _buildReponseCard(BuildContext context, RepForum reponse, QForum question) {
    final isAuteur = reponse.auteurUsername == question.auteurUsername;
    final isEnseignant = reponse.auteurEstEnseignant;
    final color = sourcePreoccupationCouleur(context, question.source);
    final accent = _accentColor(context);

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        variant: reponse.estSolution ? YkCardVariant.outlined : YkCardVariant.elevated,
        accentColor: reponse.estSolution ? YkColors.success : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(context, reponse.auteurNom, reponse.auteurUsername, isEnseignant, color, 18, avatarUrl: reponse.auteurAvatarUrl),
                SizedBox(width: YkSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reponse.auteurNom.isNotEmpty ? reponse.auteurNom : reponse.auteurUsername,
                        style: YkTypography.label(context).copyWith(
                          color: isEnseignant ? accent : YkColors.textPrimary(context),
                        ),
                      ),
                      if (isEnseignant)
                        Text(
                          'Enseignant',
                          style: YkTypography.caption(
                            context,
                          ).copyWith(color: accent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                if (reponse.estSolution)
                  YkBadge(variant: YkBadgeVariant.label, label: 'Solution', color: YkColors.success),
                SizedBox(width: YkSpacing.xs),
                Text(
                  _formatTimeAgo(reponse.creeLe),
                  style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                ),
              ],
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              reponse.contenu,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            if (reponse.imageUrl != null) ...[
              SizedBox(height: YkSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(YkRadius.sm),
                child: Image.network(
                  reponse.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (reponse.audioUrl != null) ...[
              SizedBox(height: YkSpacing.xs),
              ForumAudioPlayer(audioUrl: reponse.audioUrl!),
            ],
            SizedBox(height: YkSpacing.xs),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _likerReponse(reponse),
                  child: Row(
                    children: [
                      Icon(
                        reponse.monLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: reponse.monLike ? YkColors.error : YkColors.textTertiary(context),
                      ),
                      SizedBox(width: YkSpacing.xxs),
                      Text(
                        '${reponse.nbLikes}',
                        style: YkTypography.caption(
                          context,
                        ).copyWith(color: YkColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: YkSpacing.lg),
                if (isAuteur && !question.estResolue && !reponse.estSolution)
                  GestureDetector(
                    onTap: () => _marquerSolution(reponse),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: YkColors.success),
                        SizedBox(width: YkSpacing.xxs),
                        Text(
                          'Solution',
                          style: YkTypography.caption(context).copyWith(color: YkColors.success),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReponseInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.sm, YkSpacing.md, YkSpacing.lg),
      color: YkColors.surface(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          YkIconButton(
            icon: _selectedImageBytes != null ? Icons.check_circle : Icons.image_outlined,
            label: 'Ajouter une image',
            variant: YkIconButtonVariant.outlined,
            onPressed: _pickerImage,
          ),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: YkTextField(
              controller: _reponseCtrl,
              type: YkTextFieldType.multiline,
              maxLines: 3,
              hint: 'Écrire une réponse...',
            ),
          ),
          SizedBox(width: YkSpacing.xs),
          _sending
              ? Padding(
                  padding: EdgeInsets.all(YkSpacing.sm),
                  child: YkProgress(shape: YkProgressShape.circular, size: 24),
                )
              : YkIconButton(
                  icon: Icons.send_rounded,
                  label: 'Envoyer',
                  variant: YkIconButtonVariant.filled,
                  onPressed: _envoyerReponse,
                ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String nom,
    String username,
    bool estEnseignant,
    Color color,
    double radius, {
    String? avatarUrl,
  }) {
    final accent = _accentColor(context);
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: estEnseignant ? accent.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
          backgroundImage: hasPhoto ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: hasPhoto ? (_, _) {} : null,
          child: hasPhoto
              ? null
              : Text(
                  _getInitials(nom, username),
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    color: estEnseignant ? accent : color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        if (estEnseignant)
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipOval(
              child: Container(width: radius * 0.4, height: radius * 0.4, color: accent),
            ),
          ),
      ],
    );
  }
}
