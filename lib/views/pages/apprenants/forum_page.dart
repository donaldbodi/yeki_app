// lib/views/pages/apprenants/forum_page.dart
// Version avec WebSocket AJOUTÉ (sans modifier la logique existante)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yeki/views/pages/apprenants/details_question_forum.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';
import 'package:yeki/services/websocket_service.dart';  // AJOUTÉ

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
//const Color _borderMedium = Color(0xFFD0D4D8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _blue = Color(0xFF3B82F6);
const Color _purple = Color(0xFFA855F7);
const Color _orange = Color(0xFFF97316);

const String _base = 'https://yeki.pythonanywhere.com/api';

const Map<String, Color> _srcColor = {
  'lecon': _blue,
  'exercice': _purple,
  'devoir': _orange,
  'libre': _green,
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

Map<String, String> _getHeaders(String? token) => {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };

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

// ════════════════════════════════════════════════════════════════
// PAGE FORUM AVEC WEBSOCKET (AJOUTÉ SANS MODIFIER LA LOGIQUE)
// ════════════════════════════════════════════════════════════════
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
  late AnimationController _listCtrl;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _composerVisible = false;
  final _composerCtrl = TextEditingController();
  bool _sending = false;
  String _composerSource = 'libre';

  // ========== AJOUT WEBSOCKET ==========
  final WebSocketService _wsService = WebSocketService.instance;
  bool _wsConnected = false;
  // =====================================

  Color get _accentColor => widget.coursColor != null ? Color(widget.coursColor!) : brandBackground;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    // AJOUT: Initialiser WebSocket en arrière-plan
    _initWebSocket();
    
    _loadQuestions();

    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _loadQuestions(silent: true));

    if (widget.preoccupationContenu != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _composerCtrl.text = widget.preoccupationContenu!;
        _composerSource = widget.preoccupationSource ?? 'libre';
        setState(() => _composerVisible = true);
      });
    }
  }

  // ========== AJOUT: Initialisation WebSocket ==========
  Future<void> _initWebSocket() async {
    final token = await _getToken();
    if (token != null) {
      _wsService.connect(room: widget.preoccupationCoursId?.toString() ?? 'global');
      _wsService.subscribe('new_question', _onWebSocketNewQuestion);
      _wsService.subscribe('new_reponse', _onWebSocketNewReponse);
      _wsService.subscribe('like_updated', _onWebSocketLikeUpdated);
      setState(() => _wsConnected = true);
    }
  }
  
  // ========== AJOUT: Gestionnaires WebSocket ==========
  void _onWebSocketNewQuestion(Map<String, dynamic> data) {
    if (!mounted) return;
    final questionData = data['question'] as Map<String, dynamic>;
    final nouvelleQuestion = QForum.fromJson(questionData);
    
    // Vérifier si la question n'existe pas déjà
    final exists = _questions.any((q) => q.id == nouvelleQuestion.id);
    if (!exists) {
      setState(() {
        _questions.insert(0, nouvelleQuestion);
      });
      _listCtrl.forward(from: 0);
    }
  }
  
  void _onWebSocketNewReponse(Map<String, dynamic> data) {
    if (!mounted) return;
    final questionId = data['question_id'] as int;
    final reponseData = data['reponse'] as Map<String, dynamic>;
    final nouvelleReponse = RepForum.fromJson(reponseData);
    
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      setState(() {
        _questions[index].nbReponses++;
        _questions[index].reponses.add(nouvelleReponse);
      });
    }
  }
  
  void _onWebSocketLikeUpdated(Map<String, dynamic> data) {
    if (!mounted) return;
    final reponseId = data['reponse_id'] as int;
    final liked = data['liked'] as bool;
    final count = data['count'] as int;
    
    for (int i = 0; i < _questions.length; i++) {
      for (int j = 0; j < _questions[i].reponses.length; j++) {
        if (_questions[i].reponses[j].id == reponseId) {
          setState(() {
            _questions[i].reponses[j].nbLikes = count;
            _questions[i].reponses[j].monLike = liked;
          });
          return;
        }
      }
    }
  }
  // =========================================================

  @override
  void dispose() {
    _poll?.cancel();
    _listCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _composerCtrl.dispose();
    // AJOUT: Nettoyer WebSocket
    _wsService.unsubscribe('new_question', _onWebSocketNewQuestion);
    _wsService.unsubscribe('new_reponse', _onWebSocketNewReponse);
    _wsService.unsubscribe('like_updated', _onWebSocketLikeUpdated);
    super.dispose();
  }

  void _navigateToSource(QForum q) {
    if (q.source == 'lecon' && q.leconId != null && q.coursId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LectureLeconPage(
            leconId: q.leconId!,
            coursId: q.coursId!,
            coursTitre: q.coursTitre,
            coursColor: widget.coursColor ?? _accentColor.value,
          ),
        ),
      );
    } else if (q.source == 'exercice' && q.exerciceId != null && q.coursId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasserExercicePage(
            exerciceId: q.exerciceId!,
            coursId: q.coursId,
            coursTitre: q.coursTitre,
          ),
        ),
      );
    } else if (q.source == 'devoir' && q.devoirId != null && q.coursId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultatDevoirPage(
            devoirId: q.devoirId!,
            titre: q.devoirTitre,
            coursId: q.coursId,
            coursTitre: q.coursTitre,
          ),
        ),
      );
    }
  }

  Future<void> _loadQuestions({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    final token = await _getToken();
    if (token == null) {
      if (!silent && mounted) setState(() => _loading = false);
      _showSnackBar('Veuillez vous reconnecter');
      return;
    }

    try {
      final params = <String, String>{};
      if (_sourceFiltre != 'tous') params['source'] = _sourceFiltre;

      final uri = Uri.parse('$_base/forum/questions/')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<QForum> questions = data.map((j) => QForum.fromJson(j as Map<String, dynamic>)).toList();

        if (mounted) {
          setState(() {
            _questions = questions;
            _loading = false;
          });
          _listCtrl.forward(from: 0);

          if (widget.scrollToQuestionId != null) {
            final idx = questions.indexWhere((q) => q.id == widget.scrollToQuestionId);
            if (idx >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.animateTo(
                    idx * 170.0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                  );
                }
              });
            }
          }
        }
      } else {
        if (!silent && mounted) setState(() => _loading = false);
        _showSnackBar('Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement forum: $e');
      if (!silent && mounted) setState(() => _loading = false);
      _showSnackBar('Erreur de connexion');
    }
  }

  Future<void> _envoyerQuestion() async {
    final texte = _composerCtrl.text.trim();
    if (texte.isEmpty) {
      _showSnackBar('Veuillez écrire votre question');
      return;
    }

    setState(() => _sending = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _sending = false);
      _showSnackBar('Veuillez vous reconnecter');
      return;
    }

    final body = <String, dynamic>{
      'contenu': texte,
      'source': _composerSource,
    };

    if (widget.preoccupationLeconId != null) {
      body['lecon_id'] = widget.preoccupationLeconId;
      body['lecon_titre'] = widget.preoccupationLeconTitre ?? '';
      body['cours_id'] = widget.preoccupationCoursId;
      body['cours_titre'] = widget.preoccupationCoursTitre ?? '';
    }
    if (widget.preoccupationExerciceId != null) {
      body['exercice_id'] = widget.preoccupationExerciceId;
      body['exercice_titre'] = widget.preoccupationExerciceTitre ?? '';
    }
    if (widget.preoccupationDevoirId != null) {
      body['devoir_id'] = widget.preoccupationDevoirId;
      body['devoir_titre'] = widget.preoccupationDevoirTitre ?? '';
    }

    try {
      final response = await http.post(
        Uri.parse('$_base/forum/questions/'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final nouvelleQuestion = QForum.fromJson(data);
        
        // AJOUT: Envoyer via WebSocket si connecté
        if (_wsConnected) {
          _wsService.sendNewQuestion(
            contenu: texte,
            source: _composerSource,
            coursId: widget.preoccupationCoursId,
            leconId: widget.preoccupationLeconId,
            leconTitre: widget.preoccupationLeconTitre,
            exerciceId: widget.preoccupationExerciceId,
            exerciceTitre: widget.preoccupationExerciceTitre,
            devoirId: widget.preoccupationDevoirId,
            devoirTitre: widget.preoccupationDevoirTitre,
          );
        }
        
        // AJOUT: Ajouter localement immédiatement
        setState(() {
          _questions.insert(0, nouvelleQuestion);
        });
        
        _composerCtrl.clear();
        setState(() => _composerVisible = false);
        _listCtrl.forward(from: 0);
        
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
        _showSnackBar('✓ Question envoyée avec succès', isError: false);
      } else {
        _showSnackBar('Erreur lors de l\'envoi');
      }
    } catch (e) {
      debugPrint('Erreur envoi: $e');
      _showSnackBar('Erreur réseau');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: _white)),
        backgroundColor: isError ? Colors.red : _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
    return Container(
      color: _bgLight,
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildSearchBar(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _composerVisible ? _buildComposer() : const SizedBox.shrink(),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filtered = _filteredQuestions;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _accentColor,
      backgroundColor: _white,
      onRefresh: () => _loadQuestions(),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final delay = (index * 0.05).clamp(0.0, 1.0);
          final animation = CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
              child: _buildQuestionCard(filtered[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    // AJOUT: Indicateur de connexion WebSocket
    final wsStatus = _wsConnected ? 'En ligne' : 'Hors ligne';
    final wsColor = _wsConnected ? _green : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _borderLight)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accentColor, _accentColor.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.forum_rounded, color: _white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forum',
                  style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    Text(
                      '${_questions.length} préoccupation${_questions.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: _textLight, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: wsColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wsStatus,
                      style: TextStyle(color: wsColor, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _composerVisible = !_composerVisible;
              if (_composerVisible && widget.preoccupationContenu == null) {
                _composerCtrl.clear();
                _composerSource = 'libre';
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _composerVisible ? _accentColor : _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _composerVisible ? Icons.close_rounded : Icons.add_rounded,
                    color: _composerVisible ? _white : _accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _composerVisible ? 'Annuler' : 'Question',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _composerVisible ? _white : _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _loadQuestions(),
            icon: Icon(Icons.refresh_rounded, color: _textMedium, size: 20),
          ),
        ],
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

    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? color : _borderLight),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : _textMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderLight),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (value) => setState(() => _searchText = value),
          style: const TextStyle(color: _textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Rechercher une préoccupation...',
            hintStyle: const TextStyle(color: _textLight),
            prefixIcon: const Icon(Icons.search_rounded, color: _textLight, size: 18),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _textLight, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchText = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.edit_rounded, color: _accentColor, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Nouvelle préoccupation',
                style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (widget.preoccupationSource != null && widget.preoccupationSource != 'libre') ...[
            const SizedBox(height: 10),
            _buildContextBadge(
              source: widget.preoccupationSource!,
              contextLabel: widget.preoccupationLeconTitre ??
                  widget.preoccupationDevoirTitre ??
                  widget.preoccupationExerciceTitre ??
                  '',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isSelected ? color : _borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_srcIcon[s]!, size: 11, color: isSelected ? color : _textMedium),
                          const SizedBox(width: 4),
                          Text(
                            _srcLabel[s]!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : _textMedium,
                            ),
                          ),
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
              color: _bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderLight),
            ),
            child: TextField(
              controller: _composerCtrl,
              maxLines: 4,
              style: const TextStyle(color: _textDark, fontSize: 14, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Décrivez votre question ou difficulté...',
                hintStyle: TextStyle(color: _textLight, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _sending ? null : _envoyerQuestion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accentColor, _accentColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_sending)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                      )
                    else ...[
                      const Icon(Icons.send_rounded, color: _white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Poster la préoccupation',
                        style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge({required String source, required String contextLabel}) {
    final color = _srcColor[source] ?? _accentColor;
    final icon = _srcIcon[source] ?? Icons.link_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_srcLabel[source] ?? source} : $contextLabel',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailQuestionForumPage(questionId: q.id, question: q),
        ),
      ).then((_) => _loadQuestions()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? color.withOpacity(0.5) : _borderLight,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, size: 12, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                  if (q.source != 'libre' && q.contexteLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        q.contexteLabel,
                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (q.estResolue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 10, color: _green),
                          SizedBox(width: 4),
                          Text('Résolue', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.contenu,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w500, height: 1.55),
                  ),
                  if (q.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        q.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  if (q.audioUrl != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderLight),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 13, color: _textLight),
                          SizedBox(width: 5),
                          Text('Message audio', style: TextStyle(color: _textLight, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAvatar(q.auteurNom, q.auteurUsername, q.auteurEstEnseignant, color, 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                              style: const TextStyle(color: _textMedium, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (q.auteurEstEnseignant)
                              Text('Enseignant', style: TextStyle(color: _accentColor, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chat_bubble_outline_rounded, size: 13, color: _textLight),
                      const SizedBox(width: 4),
                      Text('${q.nbReponses}', style: const TextStyle(fontSize: 12, color: _textLight)),
                      const SizedBox(width: 12),
                      Icon(Icons.remove_red_eye_outlined, size: 13, color: _textLight),
                      const SizedBox(width: 4),
                      Text('${q.nbVues}', style: const TextStyle(fontSize: 12, color: _textLight)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 13, color: _textLight),
                        onPressed: () => _navigateToSource(q),
                        tooltip: 'Retour à la source',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatTimeAgo(q.creeLe), style: const TextStyle(fontSize: 11, color: _textLight)),
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

  Widget _buildAvatar(String nom, String username, bool estEnseignant, Color color, double radius) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: estEnseignant ? _accentColor.withOpacity(0.15) : color.withOpacity(0.1),
          child: Text(
            _getInitials(nom, username),
            style: TextStyle(
              fontSize: radius * 0.75,
              color: estEnseignant ? _accentColor : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (estEnseignant)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _bgLight, shape: BoxShape.circle, border: Border.all(color: _borderLight)),
            child: const Icon(Icons.forum_outlined, size: 48, color: _textLight),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune préoccupation',
            style: TextStyle(color: _textMedium, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les questions posées depuis les leçons,\nexercices et devoirs apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLight, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _composerVisible = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: _accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text('Poser une question', style: TextStyle(color: _accentColor, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}