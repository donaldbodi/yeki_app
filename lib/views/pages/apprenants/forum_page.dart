// lib/views/pages/apprenants/forum_page.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yeki/views/pages/apprenants/details_question_forum.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

const Map<String, Color> _srcColor = {
  'lecon': Colors.blue,
  'exercice': YekiColors.purple,
  'devoir': YekiColors.warning,
  'libre': YekiColors.success,
};
const Map<String, IconData> _srcIcon = {
  'lecon': Icons.play_lesson_rounded,
  'exercice': Icons.edit_note_rounded,
  'devoir': Icons.assignment_rounded,
  'libre': Icons.chat_bubble_outline_rounded,
};
const Map<String, String> _srcLabel = {
  'lecon': 'Leçon',
  'exercice': 'Exercice',
  'devoir': 'Devoir',
  'libre': 'Libre',
};

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

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
        reponses: (j['reponses'] as List? ?? [])
            .map((r) => RepForum.fromJson(r))
            .toList(),
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

// Lecteur audio simple
class ForumAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const ForumAudioPlayer({super.key, required this.audioUrl});
  @override
  State<ForumAudioPlayer> createState() => _ForumAudioPlayerState();
}

class _ForumAudioPlayerState extends State<ForumAudioPlayer> {
  bool _isPlaying = false;
  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: YekiColors.purple, size: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _isPlaying ? 0.5 : 0.0,
                backgroundColor: YekiColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(YekiColors.purple),
                minHeight: 3,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('00:00', style: TextStyle(fontSize: 10)),
                  Text('00:30', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
  });

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with TickerProviderStateMixin {
  bool _loading = true;
  List<QForum> _questions = [];
  String _sourceFiltre = 'tous';
  String _searchText = '';
  Timer? _poll;
  final _searchCtrl = TextEditingController();

  bool _composerVisible = false;
  final _composerCtrl = TextEditingController();
  bool _sending = false;
  String _composerSource = 'libre';
  File? _selectedImage;
  File? _selectedAudio;
  final ImagePicker _picker = ImagePicker();

  Color get _accentColor => widget.coursColor != null ? Color(widget.coursColor!) : YekiColors.primaryDark;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _loadQuestions(silent: true));
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
    _poll?.cancel();
    _searchCtrl.dispose();
    _composerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      if (!silent && mounted) setState(() => _loading = false);
      return;
    }

    try {
      final params = <String, String>{};
      if (_sourceFiltre != 'tous') params['source'] = _sourceFiltre;
      if (widget.preoccupationCoursId != null) params['cours_id'] = widget.preoccupationCoursId.toString();

      final uri = Uri.parse(ApiConstants.forumQuestions).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: ApiHeaders.auth(token));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<QForum> questions = data.map((j) => QForum.fromJson(j as Map<String, dynamic>)).toList();

        if (mounted) {
          setState(() {
            _questions = questions;
            _loading = false;
          });
        }
      } else {
        if (!silent && mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _pickAudio() async {
    final XFile? picked = await _picker.pickMedia();
    if (picked != null && mounted) {
      final ext = picked.path.split('.').last.toLowerCase();
      if (ext == 'mp3' || ext == 'm4a' || ext == 'wav' || ext == 'aac') {
        setState(() => _selectedAudio = File(picked.path));
      } else {
        ErrorHandler.showError(context, 'Format audio non supporté');
      }
    }
  }

  void _removeImage() => setState(() => _selectedImage = null);
  void _removeAudio() => setState(() => _selectedAudio = null);

  void _navigateToSource(QForum q) {
    if (q.source == 'lecon' && q.leconId != null && q.coursId != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => LectureLeconPage(
          leconId: q.leconId!,
          coursId: q.coursId!,
          coursTitre: q.coursTitre,
          coursColor: widget.coursColor ?? _accentColor.value,
        ),
      ));
    } else if (q.source == 'exercice' && q.exerciceId != null && q.coursId != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PasserExercicePage(
          exerciceId: q.exerciceId!,
          coursId: q.coursId,
          coursTitre: q.coursTitre,
        ),
      ));
    } else if (q.source == 'devoir' && q.devoirId != null && q.coursId != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultatDevoirPage(
          devoirId: q.devoirId!,
          titre: q.devoirTitre,
          coursId: q.coursId,
          coursTitre: q.coursTitre,
        ),
      ));
    }
  }

  Future<void> _envoyerQuestion() async {
    final texte = _composerCtrl.text.trim();
    if (texte.isEmpty && _selectedImage == null && _selectedAudio == null) {
      ErrorHandler.showError(context, 'Veuillez écrire une question, ajouter une image ou un audio.');
      return;
    }

    setState(() => _sending = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _sending = false);
      ErrorHandler.showError(context, 'Vous devez être connecté.');
      return;
    }

    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.forumQuestions));
    request.headers['Authorization'] = 'Token $token';
    request.fields['contenu'] = texte.isEmpty ? '[Message avec média]' : texte;
    request.fields['source'] = _composerSource;
    if (widget.preoccupationCoursId != null) {
      request.fields['cours_id'] = widget.preoccupationCoursId.toString();
      request.fields['cours_titre'] = widget.preoccupationCoursTitre ?? '';
    }
    if (widget.preoccupationLeconId != null) {
      request.fields['lecon_id'] = widget.preoccupationLeconId.toString();
      request.fields['lecon_titre'] = widget.preoccupationLeconTitre ?? '';
    }
    if (widget.preoccupationExerciceId != null) {
      request.fields['exercice_id'] = widget.preoccupationExerciceId.toString();
      request.fields['exercice_titre'] = widget.preoccupationExerciceTitre ?? '';
    }
    if (widget.preoccupationDevoirId != null) {
      request.fields['devoir_id'] = widget.preoccupationDevoirId.toString();
      request.fields['devoir_titre'] = widget.preoccupationDevoirTitre ?? '';
    }

    if (_selectedImage != null) {
      final imageBytes = await _selectedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
          filename: 'question_image_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    }
    if (_selectedAudio != null) {
      final audioBytes = await _selectedAudio!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('audio', audioBytes,
          filename: 'question_audio_${DateTime.now().millisecondsSinceEpoch}.m4a'));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final nouvelleQuestion = QForum.fromJson(data);
        setState(() {
          _questions.insert(0, nouvelleQuestion);
        });
        _composerCtrl.clear();
        _selectedImage = null;
        _selectedAudio = null;
        setState(() => _composerVisible = false);
        ErrorHandler.showSuccess(context, '✓ Question envoyée avec succès');
      } else {
        final errorData = jsonDecode(responseBody);
        ErrorHandler.showError(context, errorData['detail'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      ErrorHandler.showError(context, 'Erreur réseau: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<QForum> get _filteredQuestions {
    var list = _questions;
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      list = list.where((q) =>
          q.contenu.toLowerCase().contains(query) ||
          q.auteurNom.toLowerCase().contains(query) ||
          q.auteurUsername.toLowerCase().contains(query) ||
          q.contexteLabel.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: YekiColors.backgroundLight,
        child: const Center(child: YekiLoader()),
      );
    }

    final filtered = _filteredQuestions;

    return Container(
      color: YekiColors.backgroundLight,
      child: RefreshIndicator(
        color: _accentColor,
        backgroundColor: YekiColors.white,
        onRefresh: () => _loadQuestions(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: 20),
            _buildFilters(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _composerVisible
                  ? Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: _buildComposer())
                  : const SizedBox.shrink(),
            ),
            if (!_composerVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: GestureDetector(
                  onTap: () => setState(() => _composerVisible = true),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: YekiRadius.borderRadiusMd,
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: YekiColors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Poser une question', style: TextStyle(color: YekiColors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('Discussions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.08),
                      borderRadius: YekiRadius.borderRadiusMd,
                    ),
                    child: Text('${filtered.length} préoccupation${filtered.length > 1 ? 's' : ''}',
                        style: TextStyle(color: _accentColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            if (filtered.isEmpty) _buildEmptyState(),
            ...List.generate(filtered.length, (index) => _buildQuestionCard(filtered[index])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final items = [
      ('tous', 'Tous', null),
      ('lecon', 'Leçons', _srcColor['lecon']!),
      ('exercice', 'Exercices', _srcColor['exercice']!),
      ('devoir', 'Devoirs', _srcColor['devoir']!),
      ('libre', 'Libres', _srcColor['libre']!),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final isSelected = _sourceFiltre == item.$1;
            final color = item.$3 ?? _accentColor;
            return GestureDetector(
              onTap: () {
                setState(() => _sourceFiltre = item.$1);
                _loadQuestions();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : YekiColors.backgroundAlt,
                  borderRadius: YekiRadius.borderRadiusXl,
                  border: Border.all(color: isSelected ? color.withValues(alpha: 0.35) : Colors.transparent, width: 1.5),
                ),
                child: Text(item.$2,
                    style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? color : YekiColors.textLight)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusXxl,
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
        boxShadow: YekiShadows.subtle,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _searchText = value),
        style: YekiTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher une préoccupation...',
          hintStyle: YekiTextStyles.bodySmall,
          prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 22),
          suffixIcon: _searchText.isNotEmpty
              ? GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _searchText = ''); },
                  child: Icon(Icons.close_rounded, size: 18, color: YekiColors.textLight))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusXl,
        border: Border.all(color: _accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.08), borderRadius: YekiRadius.borderRadiusSm),
                child: Icon(Icons.edit_rounded, color: _accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Nouvelle préoccupation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _composerVisible = false),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: YekiColors.backgroundLight, borderRadius: YekiRadius.borderRadiusSm),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          ),
          if (widget.preoccupationSource != null && widget.preoccupationSource != 'libre') ...[
            const SizedBox(height: 10),
            _buildContextBadge(
              source: widget.preoccupationSource!,
              contextLabel: widget.preoccupationLeconTitre ??
                  widget.preoccupationDevoirTitre ??
                  widget.preoccupationExerciceTitre ?? '',
            ),
          ],
          const SizedBox(height: 12),
          if (widget.preoccupationSource == null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['libre', 'lecon', 'exercice', 'devoir'].map((s) {
                  final isSelected = _composerSource == s;
                  final color = _srcColor[s] ?? _accentColor;
                  return GestureDetector(
                    onTap: () => setState(() => _composerSource = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.08) : YekiColors.backgroundLight,
                        borderRadius: YekiRadius.borderRadiusXl,
                        border: Border.all(color: isSelected ? color.withValues(alpha: 0.3) : YekiColors.borderLight, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_srcIcon[s]!, size: 12, color: isSelected ? color : YekiColors.textLight),
                          const SizedBox(width: 5),
                          Text(_srcLabel[s]!,
                              style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? color : YekiColors.textMedium)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: YekiColors.backgroundLight,
              borderRadius: YekiRadius.borderRadiusLg,
              border: Border.all(color: YekiColors.borderLight),
            ),
            child: TextField(
              controller: _composerCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Décrivez votre question ou difficulté...',
                hintStyle: TextStyle(fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMediaButton(icon: Icons.image_outlined, label: 'Image', color: Colors.blue, onTap: _pickImage),
              const SizedBox(width: 12),
              _buildMediaButton(icon: Icons.audiotrack_rounded, label: 'Audio', color: YekiColors.purple, onTap: _pickAudio),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 10),
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: YekiColors.backgroundLight,
                borderRadius: YekiRadius.borderRadiusSm,
                border: Border.all(color: YekiColors.borderLight),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: YekiRadius.borderRadiusSm,
                    child: Image.file(_selectedImage!, width: double.infinity, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: YekiColors.black, borderRadius: YekiRadius.borderRadiusXl),
                        child: const Icon(Icons.close_rounded, size: 16, color: YekiColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedAudio != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: YekiColors.backgroundLight,
                borderRadius: YekiRadius.borderRadiusSm,
                border: Border.all(color: YekiColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.audiotrack_rounded, color: YekiColors.purple, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_selectedAudio!.path.split('/').last, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(onTap: _removeAudio, child: const Icon(Icons.close_rounded, size: 18)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          YekiButton(
            label: 'Poster la préoccupation',
            icon: Icons.send_rounded,
            onPressed: _sending ? null : _envoyerQuestion,
            isLoading: _sending,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: YekiRadius.borderRadiusSm,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBadge({required String source, required String contextLabel}) {
    final color = _srcColor[source] ?? _accentColor;
    final icon = _srcIcon[source] ?? Icons.link_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: YekiRadius.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${_srcLabel[source] ?? source} : $contextLabel',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QForum q) {
    final color = _srcColor[q.source] ?? _accentColor;
    final icon = _srcIcon[q.source] ?? Icons.chat_bubble_outline_rounded;
    final label = _srcLabel[q.source] ?? 'Libre';
    final isHighlighted = q.id == widget.scrollToQuestionId;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailQuestionForumPage(questionId: q.id, question: q)))
          .then((_) => _loadQuestions()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: YekiRadius.borderRadiusLg,
          border: Border.all(color: isHighlighted ? color.withValues(alpha: 0.4) : YekiColors.borderLight, width: 1),
          boxShadow: YekiShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: YekiRadius.borderRadiusSm),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                  if (q.source != 'libre' && q.contexteLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(q.contexteLabel, style: TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  if (q.estResolue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: YekiColors.success.withValues(alpha: 0.08), borderRadius: YekiRadius.borderRadiusSm),
                      child: Text('Résolue', style: TextStyle(fontSize: 10, color: YekiColors.success, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(q.contenu, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
            if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: YekiRadius.borderRadiusMd,
                  child: Image.network(q.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 160, color: YekiColors.backgroundLight,
                        child: const Center(child: Icon(Icons.broken_image, size: 40))),
                  ),
                ),
              ),
            ],
            if (q.audioUrl != null && q.audioUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: YekiRadius.borderRadiusSm,
                    border: Border.all(color: YekiColors.borderLight),
                  ),
                  child: ForumAudioPlayer(audioUrl: q.audioUrl!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  _buildAvatar(q.auteurNom, q.auteurUsername, q.auteurEstEnseignant, color, 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  _statIcon(Icons.chat_bubble_outline_rounded, '${q.nbReponses}'),
                  const SizedBox(width: 10),
                  _statIcon(Icons.remove_red_eye_outlined, '${q.nbVues}'),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _navigateToSource(q),
                    child: Icon(Icons.open_in_new_rounded, size: 14, color: YekiColors.textLight),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatTimeAgo(q.creeLe), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statIcon(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: YekiColors.textLight),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 11)),
    ],
  );

  Widget _buildAvatar(String nom, String username, bool estEnseignant, Color color, double radius) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: estEnseignant ? _accentColor.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
          child: Text(_getInitials(nom, username),
              style: TextStyle(fontSize: radius * 0.7, color: estEnseignant ? _accentColor : color, fontWeight: FontWeight.w800)),
        ),
        if (estEnseignant)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: radius * 0.35, height: radius * 0.35,
              decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle, border: Border.all(color: YekiColors.white, width: 1)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.primaryDark.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.12), width: 1),
              ),
              child: const Icon(Icons.forum_outlined, size: 48, color: YekiColors.textLight),
            ),
            const SizedBox(height: 16),
            const Text('Aucune préoccupation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Les questions posées depuis les leçons,\nexercices et devoirs apparaîtront ici.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}