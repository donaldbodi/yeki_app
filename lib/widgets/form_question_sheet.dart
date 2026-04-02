import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────
const String _base = 'https://yeki.pythonanywhere.com/api';

const Color _teal   = Color(0xFF008088);
const Color _dark   = Color(0xFF0D1B2A);

// Couleurs par source
const Map<String, Color> _sourceColors = {
  "lecon":    Color(0xFF1565C0),  // Bleu
  "exercice": Color(0xFF6A1B9A),  // Violet
  "devoir":   Color(0xFFE65100),  // Orange
  "libre":    Color(0xFF2E7D32),  // Vert
};

const Map<String, IconData> _sourceIcons = {
  "lecon":    Icons.play_lesson_rounded,
  "exercice": Icons.edit_note_rounded,
  "devoir":   Icons.assignment_rounded,
  "libre":    Icons.chat_bubble_outline_rounded,
};

/*const Map<String, String> _sourceLabels = {
  "lecon":    "Leçon",
  "exercice": "Exercice",
  "devoir":   "Devoir",
  "libre":    "Libre",
};*/

// ─────────────────────────────────────────────────────────────────
// WIDGET PARTAGÉ — Bottom Sheet "Poser une question"
// Utilisé depuis LectureLeconPage, PasserExercicePage, ResultatDevoirPage
// ─────────────────────────────────────────────────────────────────
class FormQuestionSheet extends StatefulWidget {
  final String  source;
  final int?    leconId;
  final String  leconTitre;
  final int?    coursId;
  final String  coursTitre;
  final int?    exerciceId;
  final String  exerciceTitre;
  final int?    devoirId;
  final String  devoirTitre;
  final VoidCallback? onSoumis;

  const FormQuestionSheet({super.key, 
    required this.source,
    this.leconId,
    this.leconTitre  = '',
    this.coursId,
    this.coursTitre  = '',
    this.exerciceId,
    this.exerciceTitre = '',
    this.devoirId,
    this.devoirTitre = '',
    this.onSoumis,
  });

  @override
  State<FormQuestionSheet> createState() => _FormQuestionSheetState();
}

class _FormQuestionSheetState extends State<FormQuestionSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  Color get _color => _sourceColors[widget.source] ?? _teal;
  IconData get _icon => _sourceIcons[widget.source] ?? Icons.chat_bubble_outline_rounded;

  String get _contexteLabel {
    switch (widget.source) {
      case 'lecon':    return widget.leconTitre.isNotEmpty ? widget.leconTitre : 'Leçon';
      case 'exercice': return widget.exerciceTitre.isNotEmpty ? widget.exerciceTitre : 'Exercice';
      case 'devoir':   return widget.devoirTitre.isNotEmpty ? widget.devoirTitre : 'Devoir';
      default:         return 'Question libre';
    }
  }

  Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

  Future<void> _envoyer() async {
    final texte = _ctrl.text.trim();
    if (texte.isEmpty) return;
    setState(() => _sending = true);

    final token = await _getToken();
    try {
      final body = {
        'contenu': texte,
        'source':  widget.source,
        if (widget.leconId    != null) 'lecon_id':     widget.leconId.toString(),
        if (widget.leconTitre.isNotEmpty) 'lecon_titre': widget.leconTitre,
        if (widget.coursId    != null) 'cours_id':     widget.coursId.toString(),
        if (widget.coursTitre.isNotEmpty) 'cours_titre': widget.coursTitre,
        if (widget.exerciceId != null) 'exercice_id':  widget.exerciceId.toString(),
        if (widget.exerciceTitre.isNotEmpty) 'exercice_titre': widget.exerciceTitre,
        if (widget.devoirId   != null) 'devoir_id':    widget.devoirId.toString(),
        if (widget.devoirTitre.isNotEmpty) 'devoir_titre': widget.devoirTitre,
      };

      final res = await http.post(
        Uri.parse('$_base/forum/questions/'),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context);
        widget.onSoumis?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Question envoyée dans le forum ✓'),
          backgroundColor: _color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Poser une question',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _dark)),
              Text('Visible par tous dans le forum',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ]),

          const SizedBox(height: 16),

          // Badge contexte
          if (widget.source != 'libre')
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _color.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(_icon, color: _color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _contexteLabel,
                    style: TextStyle(
                        fontSize: 12, color: _color, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ),

          // Champ texte
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: _dark),
              decoration: const InputDecoration(
                hintText: 'Décrivez votre question...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bouton envoyer
          GestureDetector(
            onTap: _sending ? null : _envoyer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _sending ? _color.withOpacity(0.6) : _color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _color.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5)),
                ],
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Envoyer dans le forum',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800,
                            fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FONCTION UTILITAIRE — Ouvrir le sheet depuis n'importe quelle page
// ─────────────────────────────────────────────────────────────────
void ouvrirQuestionForum(
  BuildContext context, {
  required String source,
  int?    leconId,
  String  leconTitre  = '',
  int?    coursId,
  String  coursTitre  = '',
  int?    exerciceId,
  String  exerciceTitre = '',
  int?    devoirId,
  String  devoirTitre = '',
  VoidCallback? onSoumis,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FormQuestionSheet(
      source:         source,
      leconId:        leconId,
      leconTitre:     leconTitre,
      coursId:        coursId,
      coursTitre:     coursTitre,
      exerciceId:     exerciceId,
      exerciceTitre:  exerciceTitre,
      devoirId:       devoirId,
      devoirTitre:    devoirTitre,
      onSoumis:       onSoumis,
    ),
  );
}