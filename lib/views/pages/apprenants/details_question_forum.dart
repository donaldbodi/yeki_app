// lib/views/pages/apprenants/details_question_forum.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';

const String _base = 'https://yeki.pythonanywhere.com/api';
const Color _teal = Color(0xFF2884A0);
const Color _tealLight = Color(0xFF39A0C2);
const Color _dark = Color(0xFF0D1117);
const Color _surface = Color(0xFF161B22);
const Color _card = Color(0xFF1C2128);
const Color _border = Color(0xFF30363D);
const Color _green = Color(0xFF22C55E);
//const Color _red = Color(0xFFEF4444);

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

// ════════════════════════════════════════════════════════════════
// PAGE DÉTAIL D'UNE QUESTION
// ════════════════════════════════════════════════════════════════
class DetailQuestionForumPage extends StatefulWidget {
  final int questionId;
  final QForum? question;

  const DetailQuestionForumPage({
    super.key,
    required this.questionId,
    this.question,
  });

  @override
  State<DetailQuestionForumPage> createState() => _DetailQuestionForumPageState();
}

class _DetailQuestionForumPageState extends State<DetailQuestionForumPage> {
  bool _loading = true;
  QForum? _question;
  final TextEditingController _reponseCtrl = TextEditingController();
  bool _sending = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    if (widget.question != null) {
      _question = widget.question;
      _loading = false;
    } else {
      _loadQuestion();
    }
  }

  @override
  void dispose() {
    _reponseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_base/forum/questions/${widget.questionId}/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _question = QForum.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _envoyerReponse() async {
    final texte = _reponseCtrl.text.trim();
    if (texte.isEmpty && _selectedImage == null) {
      return;
    }

    setState(() => _sending = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _sending = false);
      return;
    }

    try {
      final uri = Uri.parse('$_base/forum/questions/${widget.questionId}/repondre/');

      if (_selectedImage != null) {
        // Envoi avec image
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Token $token';
        request.fields['contenu'] = texte;
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ));
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          _reponseCtrl.clear();
          setState(() => _selectedImage = null);
          await _loadQuestion();
        }
      } else {
        // Envoi simple
        final response = await http.post(
          uri,
          headers: _getHeaders(token),
          body: jsonEncode({'contenu': texte}),
        );

        if (response.statusCode == 201) {
          _reponseCtrl.clear();
          await _loadQuestion();
        }
      }
    } catch (e) {
      debugPrint('Erreur envoi réponse: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _likerReponse(RepForum reponse) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_base/forum/reponses/${reponse.id}/liker/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reponse.monLike = data['liked'] ?? false;
          reponse.nbLikes = data['nb_likes'] ?? reponse.nbLikes;
        });
      }
    } catch (e) {
      debugPrint('Erreur like: $e');
    }
  }

  Future<void> _marquerSolution(RepForum reponse) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$_base/forum/reponses/${reponse.id}/solution/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        await _loadQuestion();
      }
    } catch (e) {
      debugPrint('Erreur marquer solution: $e');
    }
  }

  Future<void> _resoudreQuestion() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$_base/forum/questions/${widget.questionId}/resoudre/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        await _loadQuestion();
      }
    } catch (e) {
      debugPrint('Erreur résoudre question: $e');
    }
  }

  Future<void> _pickerImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _navigateToSource() {
    if (_question == null) return;
    final q = _question!;

    if (q.source == 'lecon' && q.leconId != null && q.coursId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LectureLeconPage(
            leconId: q.leconId!,
            coursId: q.coursId!,
            coursTitre: q.coursTitre,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Question',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          if (_question != null && _question!.source != 'libre')
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white54),
              onPressed: _navigateToSource,
              tooltip: 'Retour à la source',
            ),
          if (_question != null && !_question!.estResolue)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: _green),
              onPressed: _resoudreQuestion,
              tooltip: 'Marquer comme résolue',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _question == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'Question introuvable',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _teal),
            child: const Text('Retour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final q = _question!;
    final color = _srcColor[q.source] ?? _teal;
    final icon = _srcIcon[q.source] ?? Icons.chat_bubble_outline_rounded;
    final label = _srcLabel[q.source] ?? 'Libre';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bandeau source
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const SizedBox(width: 12),
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                      if (q.source != 'libre' && q.contexteLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            q.contexteLabel,
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (q.estResolue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: _green),
                              SizedBox(width: 4),
                              Text('Résolue', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contenu de la question
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.contenu,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                      ),
                      if (q.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            q.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildAvatar(q.auteurNom, q.auteurUsername, q.auteurEstEnseignant, color, 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (q.auteurEstEnseignant)
                                  const Text('Enseignant', style: TextStyle(color: _tealLight, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimeAgo(q.creeLe),
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Réponses
                if (q.reponses.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.forum_rounded, size: 18, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        '${q.reponses.length} réponse${q.reponses.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...q.reponses.map((r) => _buildReponseCard(r, q)),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 32, color: Colors.white24),
                          SizedBox(height: 8),
                          Text(
                            'Aucune réponse pour le moment',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Zone de réponse
        _buildReponseInput(),
      ],
    );
  }

  Widget _buildReponseCard(RepForum reponse, QForum question) {
    final isAuteur = reponse.auteurUsername == question.auteurUsername;
    final isEnseignant = reponse.auteurEstEnseignant;
    //final color = isEnseignant ? _tealLight : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reponse.estSolution ? _green.withOpacity(0.5) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(
                reponse.auteurNom,
                reponse.auteurUsername,
                isEnseignant,
                _teal,
                18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reponse.auteurNom.isNotEmpty ? reponse.auteurNom : reponse.auteurUsername,
                      style: TextStyle(
                        color: isEnseignant ? _tealLight : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isEnseignant)
                      const Text('Enseignant', style: TextStyle(color: _tealLight, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (reponse.estSolution)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: _green),
                      SizedBox(width: 4),
                      Text('Solution', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              Text(
                _formatTimeAgo(reponse.creeLe),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reponse.contenu,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          if (reponse.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                reponse.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              // Bouton like
              GestureDetector(
                onTap: () => _likerReponse(reponse),
                child: Row(
                  children: [
                    Icon(
                      reponse.monLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: reponse.monLike ? Colors.red.shade300 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reponse.nbLikes}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Bouton marquer comme solution (seulement pour l'auteur de la question)
              if (isAuteur && !question.estResolue && !reponse.estSolution)
                GestureDetector(
                  onTap: () => _marquerSolution(reponse),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: _green),
                      const SizedBox(width: 4),
                      const Text('Solution', style: TextStyle(fontSize: 11, color: _green)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReponseInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _pickerImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Icon(
                _selectedImage != null ? Icons.check_circle : Icons.image_outlined,
                color: _selectedImage != null ? _green : Colors.white54,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _reponseCtrl,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Écrire une réponse...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _envoyerReponse,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String nom, String username, bool estEnseignant, Color color, double radius) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: estEnseignant ? _teal.withOpacity(0.3) : color.withOpacity(0.2),
          child: Text(
            _getInitials(nom, username),
            style: TextStyle(
              fontSize: radius * 0.75,
              color: estEnseignant ? _tealLight : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (estEnseignant)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: const BoxDecoration(
                color: _tealLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Import des constantes depuis forum_page.dart ─────────────────
const Map<String, Color> _srcColor = {
  'lecon': Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir': Color(0xFFF97316),
  'libre': Color(0xFF22C55E),
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