// lib/widgets/form_preoccupation_sheet.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
//const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
//const Color _borderMedium = Color(0xFFD0D4D8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _blue = Color(0xFF3B82F6);
const Color _purple = Color(0xFFA855F7);
const Color _orange = Color(0xFFF97316);

const String _basePreocc = ApiConstants.baseUrl;

const Map<String, Color> _srcColP = {
  'lecon': _blue,
  'exercice': _purple,
  'devoir': _orange,
  'libre': _green,
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
  int? coursColor,
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
      coursColor: coursColor,
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
  final int? coursColor;
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
    this.coursId, this.coursTitre, this.coursColor,
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
        SnackBar(
          content: const Text('Écrivez votre question.'),
          backgroundColor: _orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
          context.pushNamed(
            AppRoute.coursDetail,
            pathParameters: {'coursId': widget.coursId!.toString()},
            queryParameters: {
              'titre': widget.coursTitre!,
              'coursColor': (widget.coursColor ?? brandBackground.value).toString(),
              'isPremium': 'true',
              'tab': widget.forumTabIndex.toString(),
              if (newId != null) 'scrollToQuestionId': newId.toString(),
            },
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: _bgLight,
                appBar: AppBar(
                  backgroundColor: _white,
                  title: const Text('Forum', style: TextStyle(color: _textDark)),
                  iconTheme: const IconThemeData(color: _textDark),
                  elevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: _borderLight),
                  ),
                ),
                body: ForumPage(scrollToQuestionId: newId),
              ),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Question envoyée au forum !'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'envoi.'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur réseau.'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final col = _srcColP[widget.source] ?? brandBackground;
    final ico = _srcIcoP[widget.source] ?? Icons.help_outline_rounded;
    final contextLabel = _contextLabel();

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(10)),
        )),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: col.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.withOpacity(0.2), width: 0.8),
            ),
            child: Icon(ico, color: col, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Poser une question',
                style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            if (contextLabel.isNotEmpty)
              Text(contextLabel,
                  style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: col.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withOpacity(0.25), width: 0.8),
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
            color: _bgLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderLight, width: 1),
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            autofocus: true,
            style: TextStyle(color: _textDark, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Décrivez votre préoccupation en détail...',
              hintStyle: TextStyle(color: _textLight, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
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
                gradient: LinearGradient(colors: [col, col.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_sending)
                  SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                else ...[
                  const Icon(Icons.send_rounded, color: _white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Envoyer au forum', style: TextStyle(
                    color: _white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Vous serez redirigé vers le forum après envoi.',
            style: TextStyle(fontSize: 11, color: _textLight)),
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