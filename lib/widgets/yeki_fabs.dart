// lib/widgets/yeki_fabs.dart
// ════════════════════════════════════════════════════════════════
// TRIPLE FAB — Répétiteur · Yéki IA · Forum
// ✅ CORRIGÉ : Import conditionnel pour record
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';

// ✅ Import conditionnel pour record (évite les erreurs de compilation)
import 'package:record/record.dart' 
    if (dart.library.html) 'package:yeki/widgets/record_stub.dart';

const String _fabBase = 'https://yeki.pythonanywhere.com/api';

// Source colors
const Map<String, Color> _fc = {
  'lecon':    Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir':   Color(0xFFF97316),
  'libre':    Color(0xFF22C55E),
};

Future<String?> _tok() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _hdrs(String? t) =>
    {'Content-Type': 'application/json', if (t != null) 'Authorization': 'Token $t'};


// ════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ════════════════════════════════════════════════════════════════
class YekiFabs extends StatefulWidget {
  // Contexte du cours
  final int    coursId;
  final String coursTitre;

  // Source (leçon / exercice / devoir)
  final String source;        // 'lecon' | 'exercice' | 'devoir' | 'libre'
  final int?   sourceId;
  final String sourceTitre;

  // Pour rediriger vers le forum onglet
  final TabController? tabController;
  final int            forumTabIndex;
  final void Function(int questionId)? onForumNavigate;

  const YekiFabs({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.source      = 'libre',
    this.sourceId,
    this.sourceTitre = '',
    this.tabController,
    this.forumTabIndex = 3,
    this.onForumNavigate, required int coursColor,
  });

  @override
  State<YekiFabs> createState() => _YekiFabsState();
}

class _YekiFabsState extends State<YekiFabs> with TickerProviderStateMixin {
  late AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── IA : choix "Voir discussion" ou "Poser une préoccupation" ─
  void _onIAPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF008088), Color(0xFF39A0C2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('YIA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Yéki IA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.chat_rounded,
              label: 'Voir la discussion',
              subtitle: 'Reprendre la conversation',
              color: const Color(0xFF008088),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => YekiIAChatPage(
                    coursId:         widget.coursId,
                    coursTitre:      widget.coursTitre,
                    sourceInitiale:  widget.source,
                    sourceId:        widget.sourceId,
                    sourceTitreInit: widget.sourceTitre,
                  ),
                ));
              },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.psychology_rounded,
              label: 'Poser une préoccupation',
              subtitle: 'Expliquer un problème avec image',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(ctx);
                _ouvrirFormPreoccupation(
                  context: context,
                  isIA: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Forum : ouvrir formulaire préoccupation ──────────────────
  void _onForumPressed() {
    _ouvrirFormPreoccupation(context: context, isIA: false);
  }

  // ── Formulaire partagé IA / Forum ────────────────────────────
  void _ouvrirFormPreoccupation({
    required BuildContext context,
    required bool isIA,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PreoccupationForm(
        isIA:        isIA,
        coursId:     widget.coursId,
        coursTitre:  widget.coursTitre,
        source:      widget.source,
        sourceId:    widget.sourceId,
        sourceTitre: widget.sourceTitre,
        onSoumis: (int? questionId) {
          if (isIA) {
            // Rediriger vers le chat IA
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => YekiIAChatPage(
                coursId:         widget.coursId,
                coursTitre:      widget.coursTitre,
                sourceInitiale:  widget.source,
                sourceId:        widget.sourceId,
                sourceTitreInit: widget.sourceTitre,
              ),
            ));
          } else {
            // Rediriger vers le forum
            if (widget.tabController != null) {
              widget.tabController!.animateTo(widget.forumTabIndex);
              if (questionId != null && widget.onForumNavigate != null) {
                widget.onForumNavigate!(questionId);
              }
            } else {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: ForumPage(
                    scrollToQuestionId: questionId,
                    preoccupationSource:       widget.source,
                    preoccupationLeconId:      widget.source == 'lecon' ? widget.sourceId : null,
                    preoccupationLeconTitre:   widget.source == 'lecon' ? widget.sourceTitre : null,
                    preoccupationCoursId:      widget.coursId,
                    preoccupationCoursTitre:   widget.coursTitre,
                    preoccupationExerciceId:   widget.source == 'exercice' ? widget.sourceId : null,
                    preoccupationExerciceTitre:widget.source == 'exercice' ? widget.sourceTitre : null,
                    preoccupationDevoirId:     widget.source == 'devoir' ? widget.sourceId : null,
                    preoccupationDevoirTitre:  widget.source == 'devoir' ? widget.sourceTitre : null,
                  ),
                ),
              ));
            }
          }
        },
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Bouton 1 — Répétiteur (à développer)
        _FabButton(
          icon: Icons.record_voice_over_rounded,
          color: const Color(0xFFE2A84B),
          tooltip: 'Répétiteur',
          delay: 0.0,
          ctrl: _enterCtrl,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Répétiteur — Bientôt disponible'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ));
          },
        ),
        const SizedBox(height: 10),
        // Bouton 2 — Yéki IA
        _FabButton(
          icon: Icons.psychology_rounded,
          color: const Color(0xFF008088),
          tooltip: 'Yéki IA',
          delay: 0.1,
          ctrl: _enterCtrl,
          onTap: _onIAPressed,
          gradient: const LinearGradient(
            colors: [Color(0xFF008088), Color(0xFF39A0C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const SizedBox(height: 10),
        // Bouton 3 — Forum
        _FabButton(
          icon: Icons.forum_rounded,
          color: const Color(0xFF3B82F6),
          tooltip: 'Forum',
          delay: 0.2,
          ctrl: _enterCtrl,
          onTap: _onForumPressed,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FAB BOUTON individuel
// ════════════════════════════════════════════════════════════════
class _FabButton extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tooltip;
  final double   delay;
  final AnimationController ctrl;
  final VoidCallback onTap;
  final Gradient? gradient;

  const _FabButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.delay,
    required this.ctrl,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay, delay + 0.4, curve: Curves.elasticOut),
    );
    return ScaleTransition(
      scale: anim,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                  colors: [color, color.withOpacity(0.8)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FORMULAIRE PRÉOCCUPATION (IA ou Forum)
// ════════════════════════════════════════════════════════════════
class _PreoccupationForm extends StatefulWidget {
  final bool   isIA;
  final int    coursId;
  final String coursTitre;
  final String source;
  final int?   sourceId;
  final String sourceTitre;
  final void Function(int? questionId) onSoumis;

  const _PreoccupationForm({
    required this.isIA,
    required this.coursId,
    required this.coursTitre,
    required this.source,
    this.sourceId,
    this.sourceTitre = '',
    required this.onSoumis,
  });

  @override
  State<_PreoccupationForm> createState() => _PreoccupationFormState();
}

class _PreoccupationFormState extends State<_PreoccupationForm> {
  final _textCtrl = TextEditingController();
  File?  _image;
  String? _audioPath;
  bool  _recording = false;
  bool  _sending   = false;
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void dispose() {
    _textCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _image = File(picked.path));
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() { _recording = false; _audioPath = path; });
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/preoccupation_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() => _recording = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permission microphone refusée'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _envoyer() async {
    final texte = _textCtrl.text.trim();
    if (texte.isEmpty && _image == null && _audioPath == null) return;

    setState(() => _sending = true);
    final token = await _tok();

    try {
      if (widget.isIA) {
        // Pour l'IA : on ferme le sheet et redirige vers le chat IA
        Navigator.pop(context);
        widget.onSoumis(null);
        return;
      }

      // Pour le Forum : créer la question via API
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_fabBase/forum/questions/'),
      );
      request.headers['Authorization'] = 'Token ${token ?? ''}';
      request.fields['contenu']  = texte.isNotEmpty ? texte : '(voir image/audio)';
      request.fields['source']   = widget.source;
      if (widget.sourceId != null)
        request.fields['lecon_id'] = '${widget.sourceId}';
      if (widget.sourceTitre.isNotEmpty)
        request.fields['lecon_titre'] = widget.sourceTitre;
      request.fields['cours_id']    = '${widget.coursId}';
      request.fields['cours_titre'] = widget.coursTitre;

      if (widget.source == 'exercice' && widget.sourceId != null) {
        request.fields['exercice_id']    = '${widget.sourceId}';
        request.fields['exercice_titre'] = widget.sourceTitre;
      }
      if (widget.source == 'devoir' && widget.sourceId != null) {
        request.fields['devoir_id']    = '${widget.sourceId}';
        request.fields['devoir_titre'] = widget.sourceTitre;
      }

      if (_image != null) {
        request.files.add(
            await http.MultipartFile.fromPath('image', _image!.path));
      }
      if (_audioPath != null) {
        request.files.add(
            await http.MultipartFile.fromPath('audio', _audioPath!));
      }

      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        final data = jsonDecode(res.body);
        Navigator.pop(context);
        widget.onSoumis(data['id'] as int?);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur ${res.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur réseau'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Color get _accentColor =>
      widget.isIA ? const Color(0xFF008088) : const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final src = widget.source;
    final srcColor = _fc[src] ?? _accentColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isIA ? Icons.psychology_rounded : Icons.forum_rounded,
                    color: _accentColor, size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isIA ? 'Poser à Yéki IA' : 'Poser dans le Forum',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bandeau contexte source
            if (src != 'libre' && widget.sourceTitre.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: srcColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: srcColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_srcIcon(src), color: srcColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_srcLabel(src)} : ${widget.sourceTitre}',
                        style: TextStyle(
                            color: srcColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Champ texte
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: TextField(
                controller: _textCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: widget.isIA
                      ? 'Décrivez votre problème à Yéki IA…'
                      : 'Décrivez votre préoccupation au forum…',
                  hintStyle: const TextStyle(
                      color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Outils : image + audio
            Row(
              children: [
                // Image
                _ToolButton(
                  icon: _image != null
                      ? Icons.check_circle_rounded
                      : Icons.image_outlined,
                  label: _image != null ? 'Image ajoutée' : 'Image',
                  color: _image != null ? Colors.green : Colors.white54,
                  onTap: _pickImage,
                ),
                const SizedBox(width: 8),
                // Audio
                _ToolButton(
                  icon: _recording
                      ? Icons.stop_circle_rounded
                      : _audioPath != null
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                  label: _recording
                      ? 'Stop'
                      : _audioPath != null
                          ? 'Audio OK'
                          : 'Enregistrer',
                  color: _recording
                      ? Colors.red
                      : _audioPath != null
                          ? Colors.green
                          : Colors.white54,
                  onTap: _toggleRecording,
                ),
                if (_image != null || _audioPath != null) ...[
                  const SizedBox(width: 8),
                  _ToolButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Effacer',
                    color: Colors.redAccent,
                    onTap: () => setState(() {
                      _image     = null;
                      _audioPath = null;
                    }),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isIA
                                ? Icons.send_rounded
                                : Icons.forum_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isIA
                                ? 'Envoyer à Yéki IA'
                                : 'Poster dans le Forum',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _srcLabel(String src) {
    switch (src) {
      case 'lecon':    return 'Leçon';
      case 'exercice': return 'Exercice';
      case 'devoir':   return 'Devoir';
      default:         return 'Libre';
    }
  }

  IconData _srcIcon(String src) {
    switch (src) {
      case 'lecon':    return Icons.play_lesson_rounded;
      case 'exercice': return Icons.edit_note_rounded;
      case 'devoir':   return Icons.assignment_rounded;
      default:         return Icons.chat_bubble_outline_rounded;
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Option du menu IA ────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final Color    color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
