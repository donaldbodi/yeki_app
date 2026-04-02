// lib/widgets/form_preoccupation_sheet.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';

const String _basePreocc = 'https://yeki.pythonanywhere.com/api';
const Color _pBlue = Color(0xFF2884A0);
const Color _pCard = Color(0xFF1C2128);
const Color _pBord = Color(0xFF30363D);

const Map<String, Color> _srcColP = {
  'lecon': Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir': Color(0xFFF97316),
  'libre': Color(0xFF22C55E),
};

const Map<String, IconData> _srcIcoP = {
  'lecon': Icons.play_lesson_rounded,
  'exercice': Icons.edit_note_rounded,
  'devoir': Icons.assignment_rounded,
  'libre': Icons.chat_bubble_outline_rounded,
};

void ouvrirPreoccupation({
  required BuildContext context,
  required String source,
  String contenuPrefill = '',
  int? leconId,
  String? leconTitre,
  int? coursId,
  String? coursTitre,
  int? exerciceId,
  String? exerciceTitre,
  int? devoirId,
  String? devoirTitre,
  TabController? tabController,
  int forumTabIndex = 3,
  void Function(int)? onNaviguerForum,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PreoccupationSheet(
      source: source,
      contenuPrefill: contenuPrefill,
      leconId: leconId,
      leconTitre: leconTitre,
      coursId: coursId,
      coursTitre: coursTitre,
      exerciceId: exerciceId,
      exerciceTitre: exerciceTitre,
      devoirId: devoirId,
      devoirTitre: devoirTitre,
      tabController: tabController,
      forumTabIndex: forumTabIndex,
      onNaviguerForum: onNaviguerForum,
    ),
  );
}

class _PreoccupationSheet extends StatefulWidget {
  final String source;
  final String contenuPrefill;
  final int? leconId;
  final String? leconTitre;
  final int? coursId;
  final String? coursTitre;
  final int? exerciceId;
  final String? exerciceTitre;
  final int? devoirId;
  final String? devoirTitre;
  final TabController? tabController;
  final int forumTabIndex;
  final void Function(int)? onNaviguerForum;

  const _PreoccupationSheet({
    required this.source,
    required this.contenuPrefill,
    this.leconId, this.leconTitre,
    this.coursId, this.coursTitre,
    this.exerciceId, this.exerciceTitre,
    this.devoirId, this.devoirTitre,
    this.tabController,
    required this.forumTabIndex,
    this.onNaviguerForum,
  });

  @override
  State<_PreoccupationSheet> createState() => _PreoccupationSheetState();
}

class _PreoccupationSheetState extends State<_PreoccupationSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.contenuPrefill;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _ctrl.text.trim();
    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Écrivez votre question.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _sending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final tok = prefs.getString('token');

      final body = <String, dynamic>{
        'contenu': texte,
        'source': widget.source,
      };

      if (widget.leconId != null) {
        body['lecon_id'] = widget.leconId;
        body['lecon_titre'] = widget.leconTitre ?? '';
        body['cours_id'] = widget.coursId;
        body['cours_titre'] = widget.coursTitre ?? '';
      }

      if (widget.exerciceId != null) {
        body['exercice_id'] = widget.exerciceId;
        body['exercice_titre'] = widget.exerciceTitre ?? '';
      }

      if (widget.devoirId != null) {
        body['devoir_id'] = widget.devoirId;
        body['devoir_titre'] = widget.devoirTitre ?? '';
      }

      final res = await http.post(
        Uri.parse('$_basePreocc/forum/questions/'),
        headers: {
          'Content-Type': 'application/json',
          if (tok != null) 'Authorization': 'Token $tok',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newId = data['id'] as int?;

        if (!mounted) return;
        Navigator.pop(context);

        if (widget.tabController != null && widget.coursId != null && widget.coursTitre != null) {
          widget.tabController!.animateTo(widget.forumTabIndex);
          if (widget.onNaviguerForum != null && newId != null) {
            widget.onNaviguerForum!(newId);
          }
        } else if (widget.coursId != null && widget.coursTitre != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoursDetailTabs(
                coursId: widget.coursId!.toString(),
                titre: widget.coursTitre!,
                isPremium: true,
                initialTab: widget.forumTabIndex,
                scrollToQuestionId: newId,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFF0D1117),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF161B22),
                  title: const Text('Forum', style: TextStyle(color: Colors.white)),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: ForumPage(scrollToQuestionId: newId),
              ),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Question envoyée au forum !'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi.'), backgroundColor: Colors.red));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau.'), backgroundColor: Colors.red));
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final col = _srcColP[widget.source] ?? _pBlue;
    final ico = _srcIcoP[widget.source] ?? Icons.help_outline_rounded;
    final contextLabel = _contextLabel();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
        )),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(ico, color: col, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Poser une question', style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            if (contextLabel.isNotEmpty)
              Text(contextLabel, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: col.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.link_rounded, size: 13, color: col),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Depuis ${_srcLabel(widget.source)} : $contextLabel',
              style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _pCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _pBord),
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            decoration: const InputDecoration(
              hintText: 'Décrivez votre préoccupation en détail...',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _sending ? null : _envoyer,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [col, col.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 12)],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_sending)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else ...[
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Envoyer au forum', style: TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Vous serez redirigé vers le forum après envoi.',
            style: TextStyle(fontSize: 11, color: Colors.white38)),
      ]),
    );
  }

  String _contextLabel() {
    switch (widget.source) {
      case 'lecon': return widget.leconTitre ?? '';
      case 'exercice': return widget.exerciceTitre ?? '';
      case 'devoir': return widget.devoirTitre ?? '';
      default: return 'Question libre';
    }
  }

  String _srcLabel(String source) {
    const map = {'lecon': 'la leçon', 'exercice': 'l\'exercice', 'devoir': 'le devoir', 'libre': 'une question libre'};
    return map[source] ?? source;
  }
}