// lib/views/pages/apprenants/resultat_devoir_page.dart - Page des résultats

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_fabs.dart';

const String baseUrl = 'https://yeki.pythonanywhere.com/api';

class ResultatDevoirPage extends StatefulWidget {
  final int devoirId;
  final String titre;
  final int? coursId;
  final String? coursTitre;

  const ResultatDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
    this.coursId,
    this.coursTitre,
  });

  @override
  State<ResultatDevoirPage> createState() => _ResultatDevoirPageState();
}

class _ResultatDevoirPageState extends State<ResultatDevoirPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _resultat;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _charger() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devoirs/${widget.devoirId}/resultat/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _resultat = jsonDecode(response.body);
          _loading = false;
        });
        _animCtrl.forward();
      } else if (response.statusCode == 202) {
        setState(() {
          _resultat = {'en_attente': true, 'message': jsonDecode(response.body)['detail']};
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.titre),
        backgroundColor: const Color(0xFF135F74),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_resultat == null) {
      return const Center(child: Text('Aucun résultat disponible'));
    }

    if (_resultat!['en_attente'] == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 60, color: Color(0xFFF97316)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Correction en attente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              _resultat!['message'] ?? 'Votre devoir sera corrigé prochainement par l\'enseignant.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135F74),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    final note = (_resultat!['note'] as num?)?.toDouble() ?? 0;
    final noteSur = (_resultat!['note_sur'] as num?)?.toDouble() ?? 20;
    final pourcentage = noteSur > 0 ? (note / noteSur * 100) : 0;
    final commentaire = _resultat!['commentaire'] ?? '';
    final detail = _resultat!['detail'] as List? ?? [];
    
    Color noteColor;
    if (pourcentage >= 75) {
      noteColor = const Color(0xFF10B981);
    } else if (pourcentage >= 50) {
      noteColor = const Color(0xFFF97316);
    } else {
      noteColor = const Color(0xFFEF4444);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [noteColor, noteColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    pourcentage >= 50 ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(
                    '/ $noteSur',
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pourcentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (commentaire.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E4E8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment_rounded, size: 16, color: Color(0xFF135F74)),
                      SizedBox(width: 8),
                      Text('Commentaire de l\'enseignant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(commentaire, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
                ],
              ),
            ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E4E8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détail par question',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ...detail.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value as Map<String, dynamic>;
                    final estCorrect = d['est_correct'] == true;
                    final pointsObtenus = (d['points_obtenus'] as num?)?.toDouble() ?? 0;
                    final pointsMax = (d['points_max'] as num?)?.toDouble() ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: estCorrect ? const Color(0xFF10B981).withOpacity(0.05) : const Color(0xFFEF4444).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: estCorrect ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                estCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 16,
                                color: estCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d['question'] ?? 'Question ${idx + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: estCorrect ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${pointsObtenus.toStringAsFixed(0)}/${pointsMax.toStringAsFixed(0)} pts',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: estCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre réponse: ${d['reponse'] ?? '-'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                          if (!estCorrect && d['bonne_reponse'] != null && d['bonne_reponse'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Bonne réponse: ${d['bonne_reponse']}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}