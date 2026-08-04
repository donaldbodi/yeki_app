// lib/views/pages/apprenants/forum_page.dart
//
// Refondu en P10.5 (migration mécanique, rituel P5.0) : bascule vers
// `ForumRepository` (plus de `http`/`SharedPreferences`/`dart:convert`
// bruts) et vers les tokens/composants `Yk*` (plus de `YekiColors`/
// `YekiRadius`/`YekiShadows`/`YekiTextStyles`/`YekiButton`/`YekiLoader`,
// dépréciés). Structure et comportement inchangés — migration mécanique,
// pas une réinvention visuelle (décision explicite, vu le volume et le
// risque de régression sans QA visuelle possible).
//
// Corrections apportées au passage (bugs confirmés, pas des choix de
// design) :
// - `_loadQuestions()` castait directement l'enveloppe paginée du
//   backend (`{count, next, previous, results}`) en `List` — corrigé À LA
//   SOURCE dans `ForumRepository.listQuestions()`.
// - `ApiConstants.forumRealtimeEnabled` (actuellement `false`) n'était
//   JAMAIS consulté : le sondage 8 s tournait inconditionnellement malgré
//   le drapeau. Câblé ici — le sondage ne démarre que si le drapeau est à
//   `true`.
// - `_selectedImage`/`_selectedAudio` passent de `File` (dart:io) à
//   `Uint8List` : `File` plante sur le web (voir `YkPickedFile` dans
//   `yk_file_upload.dart`), même bug déjà corrigé ailleurs.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/features/paiement/presentation/ouvrir_abonnement.dart';
import 'package:yeki/repositories/forum_repository.dart';
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
// MODÈLE DE QUESTION
// ════════════════════════════════════════════════════════════
class QForum {
  final int id;
  final String contenu, source, creeLe;
  final String auteurNom, auteurUsername;
  final bool estResolue, auteurEstEnseignant;
  final int nbVues;
  int nbReponses;
  final int? leconId, coursId, exerciceId, devoirId;
  final String leconTitre, coursTitre, exerciceTitre, devoirTitre;
  final String? imageUrl, audioUrl;
  List<RepForum> reponses;

  QForum({
    required this.id,
    required this.contenu,
    required this.source,
    required this.creeLe,
    required this.estResolue,
    required this.nbVues,
    required this.nbReponses,
    required this.auteurNom,
    required this.auteurUsername,
    this.auteurEstEnseignant = false,
    this.leconId,
    this.leconTitre = '',
    this.coursId,
    this.coursTitre = '',
    this.exerciceId,
    this.exerciceTitre = '',
    this.devoirId,
    this.devoirTitre = '',
    this.imageUrl,
    this.audioUrl,
    this.reponses = const [],
  });

  factory QForum.fromJson(Map<String, dynamic> j) => QForum(
    id: j['id'],
    contenu: j['contenu'] ?? '',
    source: j['source'] ?? 'libre',
    creeLe: j['cree_le'] ?? '',
    estResolue: j['est_resolue'] ?? false,
    nbVues: j['nb_vues'] ?? 0,
    nbReponses: j['nb_reponses'] ?? 0,
    auteurNom: j['auteur_nom'] ?? '',
    auteurUsername: j['auteur_username'] ?? '',
    auteurEstEnseignant: j['auteur_est_enseignant'] ?? false,
    leconId: j['lecon_id'],
    leconTitre: j['lecon_titre'] ?? '',
    coursId: j['cours_id'],
    coursTitre: j['cours_titre'] ?? '',
    exerciceId: j['exercice_id'],
    exerciceTitre: j['exercice_titre'] ?? '',
    devoirId: j['devoir_id'],
    devoirTitre: j['devoir_titre'] ?? '',
    imageUrl: j['image_url'] as String?,
    audioUrl: j['audio_url'] as String?,
    reponses: (j['reponses'] as List? ?? []).map((r) => RepForum.fromJson(r)).toList(),
  );

  String get contexteLabel {
    switch (source) {
      case 'lecon':
        return leconTitre.isNotEmpty ? leconTitre : 'Leçon';
      case 'exercice':
        return exerciceTitre.isNotEmpty ? exerciceTitre : 'Exercice';
      case 'devoir':
        return devoirTitre.isNotEmpty ? devoirTitre : 'Devoir';
      default:
        return 'Question libre';
    }
  }
}

// ════════════════════════════════════════════════════════════
// MODÈLE DE RÉPONSE
// ════════════════════════════════════════════════════════════
class RepForum {
  final int id;
  final String contenu, creeLe, auteurNom, auteurUsername;
  final bool estSolution, auteurEstEnseignant;
  int nbLikes;
  bool monLike;
  final String? imageUrl, audioUrl;

  RepForum({
    required this.id,
    required this.contenu,
    required this.creeLe,
    required this.estSolution,
    required this.auteurNom,
    required this.auteurUsername,
    this.auteurEstEnseignant = false,
    required this.nbLikes,
    required this.monLike,
    this.imageUrl,
    this.audioUrl,
  });

  factory RepForum.fromJson(Map<String, dynamic> j) => RepForum(
    id: j['id'],
    contenu: j['contenu'] ?? '',
    creeLe: j['cree_le'] ?? '',
    estSolution: j['est_solution'] ?? false,
    auteurNom: j['auteur_nom'] ?? '',
    auteurUsername: j['auteur_username'] ?? '',
    auteurEstEnseignant: j['auteur_est_enseignant'] ?? false,
    nbLikes: j['nb_likes'] ?? 0,
    monLike: j['mon_like'] ?? false,
    imageUrl: j['image_url'] as String?,
    audioUrl: j['audio_url'] as String?,
  );
}

// ════════════════════════════════════════════════════════════
// PAGE PRINCIPALE DU FORUM
// ════════════════════════════════════════════════════════════
class ForumPage extends StatefulWidget {
  final int? scrollToQuestionId;
  final String? preoccupationContenu;
  final String? preoccupationSource;
  final int? preoccupationLeconId;
  final String? preoccupationLeconTitre;
  final int? preoccupationCoursId;
  final String? preoccupationCoursTitre;
  final int? preoccupationExerciceId;
  final String? preoccupationExerciceTitre;
  final int? preoccupationDevoirId;
  final String? preoccupationDevoirTitre;
  final int? coursColor;

  /// Espace réservé en haut du contenu défilable — voir
  /// `LeconsCoursPage.topPadding` (même besoin, en-tête « verre dépoli »
  /// de `CoursDetailTabs`). `0` par défaut (usage standalone, ex. onglet
  /// principal Forum, sans cet en-tête).
  final double topPadding;

  const ForumPage({
    super.key,
    this.scrollToQuestionId,
    this.preoccupationContenu,
    this.preoccupationSource,
    this.preoccupationLeconId,
    this.preoccupationLeconTitre,
    this.preoccupationCoursId,
    this.preoccupationCoursTitre,
    this.preoccupationExerciceId,
    this.preoccupationExerciceTitre,
    this.preoccupationDevoirId,
    this.preoccupationDevoirTitre,
    this.coursColor,
    this.topPadding = 0,
  });

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _repo = ForumRepository();
  bool _loading = true;

  /// Bug corrigé : une erreur de chargement (le plus souvent le 403
  /// « réservé aux abonnés Premium », `AccesMatricePermission` côté
  /// backend) était avalée en silence (`debugPrint` seul) — l'écran
  /// retombait sur `_buildEmptyState()`, indiscernable d'un forum
  /// réellement vide. `null` = pas d'erreur.
  String? _erreurMessage;
  List<QForum> _questions = [];
  String _sourceFiltre = 'tous';
  String _searchText = '';
  Timer? _poll;
  DateTime? _dernierSondage;
  final _searchCtrl = TextEditingController();

  bool _composerVisible = false;
  final _composerCtrl = TextEditingController();
  bool _sending = false;
  String _composerSource = 'libre';
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  Uint8List? _selectedAudioBytes;
  String? _selectedAudioNom;

  Color _accentColor(BuildContext context) =>
      widget.coursColor != null ? Color(widget.coursColor!) : YkColors.accent(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
    _demarrerSondage();
    if (widget.preoccupationContenu != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _composerCtrl.text = widget.preoccupationContenu!;
        _composerSource = widget.preoccupationSource ?? 'libre';
        setState(() => _composerVisible = true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _searchCtrl.dispose();
    _composerCtrl.dispose();
    super.dispose();
  }

  // ── Sondage temps réel (repli WebSocket) ───────────────────────────────
  // PythonAnywhere ne supporte pas les WebSockets (voir
  // docs/FORUM_TEMPS_REEL.md) : ce sondage ne tourne JAMAIS en arrière-plan
  // (uniquement pendant que cet écran est visible), et ne démarre QUE
  // derrière `ApiConstants.forumRealtimeEnabled` (`false` par défaut
  // aujourd'hui — le drapeau existait mais n'était jamais consulté ici,
  // corrigé en P10.5).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ApiConstants.forumRealtimeEnabled) return;
    if (state == AppLifecycleState.resumed) {
      _demarrerSondage();
      _sonderActivite();
    } else {
      _poll?.cancel();
    }
  }

  void _demarrerSondage() {
    if (!ApiConstants.forumRealtimeEnabled) return;
    _poll?.cancel();
    _dernierSondage ??= DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _sonderActivite());
  }

  String get _room => widget.preoccupationCoursId?.toString() ?? 'global';

  /// Sondage léger et incrémental (`?since=`) : ne redemande la liste
  /// complète que si une activité réelle est détectée depuis le dernier
  /// passage.
  Future<void> _sonderActivite() async {
    final since = _dernierSondage;
    final maintenant = DateTime.now();
    try {
      final data = await _repo.sonderActivite(_room, since: since);
      _dernierSondage = maintenant;
      final nouvellesQuestions = (data['nouvelles_questions'] as List?) ?? const [];
      final reponsesRecentesIds = (data['reponses_recentes_ids'] as List?) ?? const [];
      if (nouvellesQuestions.isNotEmpty || reponsesRecentesIds.isNotEmpty) {
        await _loadQuestions(silent: true);
      }
    } catch (e) {
      debugPrint('Erreur sondage forum: $e');
    }
  }

  Future<void> _loadQuestions({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await _repo.listQuestions(
        source: _sourceFiltre,
        coursId: widget.preoccupationCoursId,
      );
      if (!mounted) return;
      setState(() {
        _questions = data.map((j) => QForum.fromJson(j)).toList();
        _erreurMessage = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _erreurMessage = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _erreurMessage = 'Impossible de charger le forum.';
          _loading = false;
        });
        debugPrint('Erreur chargement questions: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _pickAudio() async {
    final XFile? picked = await _picker.pickMedia();
    if (picked != null && mounted) {
      final ext = picked.path.split('.').last.toLowerCase();
      if (ext == 'mp3' || ext == 'm4a' || ext == 'wav' || ext == 'aac') {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedAudioBytes = bytes;
          _selectedAudioNom = picked.name;
        });
      } else {
        ErrorHandler.showError(context, 'Format audio non supporté');
      }
    }
  }

  void _removeImage() => setState(() => _selectedImageBytes = null);
  void _removeAudio() => setState(() {
    _selectedAudioBytes = null;
    _selectedAudioNom = null;
  });

  void _navigateToSource(QForum q) {
    if (q.source == 'lecon' && q.leconId != null && q.coursId != null) {
      context.pushNamed(
        AppRoute.leconLecture,
        pathParameters: {'leconId': q.leconId!.toString(), 'coursId': q.coursId!.toString()},
        queryParameters: {
          'coursTitre': q.coursTitre,
          'coursColor': (widget.coursColor ?? _accentColor(context).toARGB32()).toString(),
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

  Future<void> _envoyerQuestion() async {
    final texte = _composerCtrl.text.trim();
    if (texte.isEmpty && _selectedImageBytes == null && _selectedAudioBytes == null) {
      ErrorHandler.showError(context, 'Veuillez écrire une question, ajouter une image ou un audio.');
      return;
    }

    setState(() => _sending = true);
    try {
      final data = await _repo.creerQuestion(
        contenu: texte.isEmpty ? '[Message avec média]' : texte,
        source: _composerSource,
        coursId: widget.preoccupationCoursId,
        coursTitre: widget.preoccupationCoursTitre,
        leconId: widget.preoccupationLeconId,
        leconTitre: widget.preoccupationLeconTitre,
        exerciceId: widget.preoccupationExerciceId,
        exerciceTitre: widget.preoccupationExerciceTitre,
        devoirId: widget.preoccupationDevoirId,
        devoirTitre: widget.preoccupationDevoirTitre,
        imageBytes: _selectedImageBytes,
        audioBytes: _selectedAudioBytes,
      );
      final nouvelleQuestion = QForum.fromJson(data);
      setState(() {
        _questions.insert(0, nouvelleQuestion);
        _composerCtrl.clear();
        _selectedImageBytes = null;
        _selectedAudioBytes = null;
        _selectedAudioNom = null;
        _composerVisible = false;
      });
      if (mounted) ErrorHandler.showSuccess(context, '✓ Question envoyée avec succès');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Erreur lors de l\'envoi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<QForum> get _filteredQuestions {
    var list = _questions;
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      list = list
          .where(
            (q) =>
                q.contenu.toLowerCase().contains(query) ||
                q.auteurNom.toLowerCase().contains(query) ||
                q.auteurUsername.toLowerCase().contains(query) ||
                q.contexteLabel.toLowerCase().contains(query),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: YkColors.background(context),
        padding: EdgeInsets.only(top: widget.topPadding),
        child: Center(child: YkProgress(shape: YkProgressShape.circular)),
      );
    }

    final erreur = _erreurMessage;
    if (erreur != null) {
      return Container(
        color: YkColors.background(context),
        padding: EdgeInsets.only(top: widget.topPadding),
        child: erreur == kMessagePremiumRequis
            ? YkPremiumRequired(message: erreur, onSubscribe: () => ouvrirAbonnementPremium(context))
            : YkErrorState(message: erreur, onRetry: () => _loadQuestions()),
      );
    }

    final accent = _accentColor(context);
    final filtered = _filteredQuestions;

    return Container(
      color: YkColors.background(context),
      child: RefreshIndicator(
        color: accent,
        backgroundColor: YkColors.surface(context),
        onRefresh: () => _loadQuestions(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.only(top: widget.topPadding, bottom: 100),
          children: [
            SizedBox(height: YkSpacing.lg),
            _buildFilters(context),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
              child: _buildSearchBar(context),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _composerVisible
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
                      child: _buildComposer(context),
                    )
                  : const SizedBox.shrink(),
            ),
            if (!_composerVisible)
              Padding(
                padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.xs, YkSpacing.md, YkSpacing.xxs),
                child: YkButton(
                  label: 'Poser une question',
                  icon: Icons.add_rounded,
                  onPressed: () => setState(() => _composerVisible = true),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.lg, YkSpacing.md, YkSpacing.lg, YkSpacing.xs),
              child: Row(
                children: [
                  Text(
                    'Discussions',
                    style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                  const Spacer(),
                  YkBadge(
                    variant: YkBadgeVariant.label,
                    label: '${filtered.length} préoccupation${filtered.length > 1 ? 's' : ''}',
                    color: accent,
                  ),
                ],
              ),
            ),
            if (filtered.isEmpty) _buildEmptyState(context),
            ...List.generate(filtered.length, (index) => _buildQuestionCard(context, filtered[index])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final items = [
      ('tous', 'Tous', null),
      ('lecon', 'Leçons', YkColors.info),
      ('exercice', 'Exercices', YkColors.accent(context)),
      ('devoir', 'Devoirs', YkColors.warning),
      ('libre', 'Libres', YkColors.success),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final isSelected = _sourceFiltre == item.$1;
            final color = item.$3 ?? _accentColor(context);
            return Padding(
              padding: EdgeInsets.only(right: YkSpacing.xs),
              child: YkChip(
                label: item.$2,
                variant: YkChipVariant.filter,
                selected: isSelected,
                accentColor: color,
                onSelected: (_) {
                  setState(() => _sourceFiltre = item.$1);
                  _loadQuestions();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return YkTextField(
      controller: _searchCtrl,
      type: YkTextFieldType.search,
      hint: 'Rechercher une préoccupation...',
      onChanged: (value) => setState(() => _searchText = value),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final accent = _accentColor(context);
    return YkCard(
      accentColor: accent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: accent.withValues(alpha: 0.08),
                child: Icon(Icons.edit_rounded, color: accent, size: 16),
              ),
              SizedBox(width: YkSpacing.xs),
              Text(
                'Nouvelle préoccupation',
                style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              const Spacer(),
              YkIconButton(
                icon: Icons.close_rounded,
                label: 'Fermer',
                variant: YkIconButtonVariant.ghost,
                onPressed: () => setState(() => _composerVisible = false),
              ),
            ],
          ),
          if (widget.preoccupationSource != null && widget.preoccupationSource != 'libre') ...[
            SizedBox(height: YkSpacing.xs),
            _buildContextBadge(
              context,
              source: widget.preoccupationSource!,
              contextLabel:
                  widget.preoccupationLeconTitre ??
                  widget.preoccupationDevoirTitre ??
                  widget.preoccupationExerciceTitre ??
                  '',
            ),
          ],
          SizedBox(height: YkSpacing.sm),
          if (widget.preoccupationSource == null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['libre', 'lecon', 'exercice', 'devoir'].map((s) {
                  final isSelected = _composerSource == s;
                  final color = sourcePreoccupationCouleur(context, s);
                  return Padding(
                    padding: EdgeInsets.only(right: YkSpacing.xxs),
                    child: YkChip(
                      label: sourceLabelCourt(s),
                      variant: YkChipVariant.filter,
                      selected: isSelected,
                      accentColor: color,
                      avatar: Icon(sourcePreoccupationIcone(s), size: 14, color: color),
                      onSelected: (_) => setState(() => _composerSource = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: YkSpacing.xs),
          ],
          YkTextField(
            controller: _composerCtrl,
            type: YkTextFieldType.multiline,
            maxLines: 4,
            hint: 'Décrivez votre question ou difficulté...',
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  context,
                  icon: Icons.image_outlined,
                  label: 'Image',
                  color: YkColors.info,
                  onTap: _pickImage,
                ),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: _buildMediaButton(
                  context,
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio',
                  color: YkColors.accent(context),
                  onTap: _pickAudio,
                ),
              ),
            ],
          ),
          if (_selectedImageBytes != null) ...[
            SizedBox(height: YkSpacing.xs),
            SizedBox(
              height: 80,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(YkRadius.sm),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: ClipOval(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.black54,
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedAudioBytes != null) ...[
            SizedBox(height: YkSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(YkRadius.sm),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
                color: YkColors.surfaceVariant(context),
                child: Row(
                  children: [
                    Icon(Icons.audiotrack_rounded, color: YkColors.accent(context), size: 18),
                    SizedBox(width: YkSpacing.sm),
                    Expanded(
                      child: Text(
                        _selectedAudioNom ?? 'Audio sélectionné',
                        style: YkTypography.bodySm(
                          context,
                        ).copyWith(color: YkColors.textSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(onTap: _removeAudio, child: const Icon(Icons.close_rounded, size: 18)),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: YkSpacing.sm),
          YkButton(
            label: 'Poster la préoccupation',
            icon: Icons.send_rounded,
            onPressed: _sending ? null : _envoyerQuestion,
            isLoading: _sending,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(YkRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
          color: color.withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: YkSpacing.xxs),
              Text(label, style: YkTypography.bodySm(context).copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBadge(BuildContext context, {required String source, required String contextLabel}) {
    final color = sourcePreoccupationCouleur(context, source);
    final icon = sourcePreoccupationIcone(source);
    return ClipRRect(
      borderRadius: BorderRadius.circular(YkRadius.sm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
        color: color.withValues(alpha: 0.06),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            SizedBox(width: YkSpacing.xs),
            Expanded(
              child: Text(
                '${sourceLabelCourt(source)} : $contextLabel',
                style: YkTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QForum q) {
    final color = sourcePreoccupationCouleur(context, q.source);
    final icon = sourcePreoccupationIcone(q.source);
    final label = sourceLabelCourt(q.source);
    final isHighlighted = q.id == widget.scrollToQuestionId;

    return Padding(
      padding: EdgeInsets.fromLTRB(YkSpacing.md, 0, YkSpacing.md, YkSpacing.sm),
      child: YkCard(
        variant: YkCardVariant.elevated,
        accentColor: isHighlighted ? color : null,
        onTap: () => context
            .pushNamed(
              AppRoute.forumQuestionDetail,
              pathParameters: {'questionId': q.id.toString()},
              queryParameters: {
                if (widget.coursColor != null) 'coursColor': widget.coursColor.toString(),
              },
              extra: q,
            )
            .then((_) => _loadQuestions()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withValues(alpha: 0.08),
                  child: Icon(icon, size: 14, color: color),
                ),
                SizedBox(width: YkSpacing.xs),
                Text(label, style: YkTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.bold)),
                if (q.source != 'libre' && q.contexteLabel.isNotEmpty) ...[
                  SizedBox(width: YkSpacing.xxs),
                  Expanded(
                    child: Text(
                      q.contexteLabel,
                      style: YkTypography.caption(
                        context,
                      ).copyWith(color: YkColors.textTertiary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (q.estResolue)
                  YkBadge(variant: YkBadgeVariant.label, label: 'Résolue', color: YkColors.success),
              ],
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              q.contenu,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
              SizedBox(height: YkSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(YkRadius.md),
                child: Image.network(
                  q.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 160,
                    color: YkColors.surfaceVariant(context),
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
            ],
            if (q.audioUrl != null && q.audioUrl!.isNotEmpty) ...[
              SizedBox(height: YkSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(YkRadius.sm),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
                  color: YkColors.surfaceVariant(context),
                  child: ForumAudioPlayer(audioUrl: q.audioUrl!),
                ),
              ),
            ],
            SizedBox(height: YkSpacing.xs),
            Row(
              children: [
                _buildAvatar(context, q.auteurNom, q.auteurUsername, q.auteurEstEnseignant, color, 16),
                SizedBox(width: YkSpacing.xs),
                Expanded(
                  child: Text(
                    q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                    style: YkTypography.bodySm(
                      context,
                    ).copyWith(color: YkColors.textSecondary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statIcon(context, Icons.chat_bubble_outline_rounded, '${q.nbReponses}'),
                SizedBox(width: YkSpacing.xs),
                _statIcon(context, Icons.remove_red_eye_outlined, '${q.nbVues}'),
                SizedBox(width: YkSpacing.xs),
                GestureDetector(
                  onTap: () => _navigateToSource(q),
                  child: Icon(Icons.open_in_new_rounded, size: 14, color: YkColors.textTertiary(context)),
                ),
                SizedBox(width: YkSpacing.xxs),
                Text(
                  _formatTimeAgo(q.creeLe),
                  style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statIcon(BuildContext context, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: YkColors.textTertiary(context)),
      SizedBox(width: 3),
      Text(text, style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context))),
    ],
  );

  Widget _buildAvatar(
    BuildContext context,
    String nom,
    String username,
    bool estEnseignant,
    Color color,
    double radius,
  ) {
    final accent = _accentColor(context);
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: estEnseignant ? accent.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
          child: Text(
            _getInitials(nom, username),
            style: TextStyle(
              fontSize: radius * 0.7,
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
              child: Container(width: radius * 0.35, height: radius * 0.35, color: accent),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xxl, horizontal: YkSpacing.lg),
      child: YkEmptyState(
        icon: Icons.forum_outlined,
        title: 'Aucune préoccupation',
        message: 'Les questions posées depuis les leçons,\nexercices et devoirs apparaîtront ici.',
      ),
    );
  }
}
